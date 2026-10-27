
#import "AMABacktraceSymbolicator.h"
#import "AMABinaryImage.h"
#import "AMABacktrace.h"
#import "AMABacktraceFrame.h"
#import "AMABinaryImageExtractor.h"
#import "AMAKSCrashImports.h"

@interface AMABacktraceSymbolicator ()

@property (nonatomic, assign, readonly) AMADLAddrFunction *dlAddrFunction;
@property (nonatomic, strong, readonly) NSCache<NSNumber *, AMABinaryImage *> *imagesCache;

@end

@implementation AMABacktraceSymbolicator

- (instancetype)init
{
    return [self initWithDLAddrFunction:ksdl_dladdr];
}

- (instancetype)initWithDLAddrFunction:(AMADLAddrFunction *)dlAddrFunction
{
    self = [super init];
    if (self != nil) {
        _dlAddrFunction = dlAddrFunction;
        _imagesCache = [[NSCache alloc] init];
        _imagesCache.countLimit = 100;
    }
    return self;
}

- (AMABacktrace *)backtraceForInstructionAddresses:(NSArray<NSNumber *> *)addresses
                                      binaryImages:(NSSet<AMABinaryImage *> **)binaryImages
{
    if (addresses.count == 0) {
        return nil;
    }

    // Per-backtrace scratch: avoids repeated global-cache locks / sharedImages scans for the same images.
    NSMutableDictionary<NSNumber *, AMABinaryImage *> *localImagesByHeader = [NSMutableDictionary dictionary];
    NSArray<AMABinaryImage *> *sharedImagesSnapshot = nil;
    AMABinaryImage *lastFallbackImage = nil;

    NSMutableSet *mutableBinaryImages = [NSMutableSet set];
    NSMutableArray *frames = [NSMutableArray arrayWithCapacity:addresses.count];
    for (NSNumber *address in addresses) {
        AMABinaryImage *binaryImage = nil;
        AMABacktraceFrame *frame = [self frameForAddress:address
                                             binaryImage:&binaryImage
                                      localImagesByHeader:localImagesByHeader
                                    sharedImagesSnapshot:&sharedImagesSnapshot
                                       lastFallbackImage:&lastFallbackImage];
        if (frame != nil) {
            [frames addObject:frame];
        }
        if (binaryImage != nil) {
            [mutableBinaryImages addObject:binaryImage];
        }
    }
    if (binaryImages != NULL) {
        *binaryImages = [mutableBinaryImages copy];
    }
    return [[AMABacktrace alloc] initWithFrames:[frames copy]];
}

- (AMABacktraceFrame *)frameForAddress:(NSNumber *)address
                           binaryImage:(AMABinaryImage **)binaryImage
                    localImagesByHeader:(NSMutableDictionary<NSNumber *, AMABinaryImage *> *)localImagesByHeader
                  sharedImagesSnapshot:(NSArray<AMABinaryImage *> * __strong *)sharedImagesSnapshot
                     lastFallbackImage:(AMABinaryImage * __strong *)lastFallbackImage
{
    if ([address isKindOfClass:[NSNumber class]] == NO) {
        return nil;
    }

    AMABinaryImage *image = nil;
    AMABacktraceFrame *frame = nil;

    Dl_info info = {0};
    uintptr_t instructionAddress = kssymbolicator_callInstructionAddress((uintptr_t)address.unsignedIntegerValue);
    if (self.dlAddrFunction(instructionAddress, &info)) {
        image = [self binaryImageWithHeaderAddress:info.dli_fbase
                                              name:info.dli_fname
                                localImagesByHeader:localImagesByHeader];
        uintptr_t symbolAddress = (uintptr_t)info.dli_saddr;
        BOOL stripped = (info.dli_saddr == info.dli_fbase) || (info.dli_saddr == NULL);
        NSString *objectPath = [self stringForCString:info.dli_fname];
        frame = [[AMABacktraceFrame alloc] initWithLineOfCode:nil
                                           instructionAddress:@(instructionAddress)
                                                symbolAddress:(symbolAddress != 0 ? @(symbolAddress) : nil)
                                                objectAddress:@((uintptr_t)info.dli_fbase)
                                                   symbolName:[self stringForCString:info.dli_sname]
                                                   objectName:objectPath.lastPathComponent
                                                     stripped:stripped];
    }
    else {
        image = [self binaryImageWithInstructionAddress:instructionAddress
                                  sharedImagesSnapshot:sharedImagesSnapshot
                                     lastFallbackImage:lastFallbackImage];
        frame = [[AMABacktraceFrame alloc] initWithLineOfCode:nil
                                           instructionAddress:@(instructionAddress)
                                                symbolAddress:nil
                                                objectAddress:@(image.address)
                                                   symbolName:nil
                                                   objectName:image.name.lastPathComponent
                                                     stripped:YES];
    }

    if (binaryImage != NULL) {
        *binaryImage = image;
    }
    return frame;
}

- (AMABinaryImage *)binaryImageWithHeaderAddress:(void *)address
                                            name:(const char *)name
                              localImagesByHeader:(NSMutableDictionary<NSNumber *, AMABinaryImage *> *)localImagesByHeader
{
    if (address == NULL) {
        return nil;
    }

    NSNumber *key = @((NSUInteger)address);
    AMABinaryImage *image = localImagesByHeader[key];
    if (image != nil) {
        return image;
    }

    image = [self cachedBinaryImageWithHeaderAddress:address name:name];
    if (image != nil) {
        localImagesByHeader[key] = image;
    }
    return image;
}

/// Global NSCache with serialize-on-create (single locked check → create → insert; no DCL).
- (AMABinaryImage *)cachedBinaryImageWithHeaderAddress:(void *)address name:(const char *)name
{
    NSNumber *key = @((NSUInteger)address);
    @synchronized (self) {
        AMABinaryImage *image = [self.imagesCache objectForKey:key];
        if (image != nil) {
            return image;
        }
        image = [AMABinaryImageExtractor imageForImageHeader:address name:name];
        if (image != nil) {
            [self.imagesCache setObject:image forKey:key];
        }
        return image;
    }
}

- (AMABinaryImage *)binaryImageWithInstructionAddress:(NSUInteger)instructionAddress
                                sharedImagesSnapshot:(NSArray<AMABinaryImage *> * __strong *)sharedImagesSnapshot
                                   lastFallbackImage:(AMABinaryImage * __strong *)lastFallbackImage
{
    AMABinaryImage *lastImage = (lastFallbackImage != NULL) ? *lastFallbackImage : nil;
    if (lastImage != nil
        && lastImage.address <= instructionAddress
        && instructionAddress < lastImage.address + lastImage.size) {
        return lastImage;
    }

    NSArray<AMABinaryImage *> *images = (sharedImagesSnapshot != NULL) ? *sharedImagesSnapshot : nil;
    if (images == nil) {
        images = [AMABinaryImageExtractor sharedImages];
        if (sharedImagesSnapshot != NULL) {
            *sharedImagesSnapshot = images;
        }
    }

    for (AMABinaryImage *obj in images) {
        if (obj.address <= instructionAddress && instructionAddress < obj.address + obj.size) {
            if (lastFallbackImage != NULL) {
                *lastFallbackImage = obj;
            }
            return obj;
        }
    }
    return nil;
}

- (NSString *)stringForCString:(const char *)cString
{
    if (cString == NULL) {
        return nil;
    }
    return [NSString stringWithUTF8String:cString];
}

@end
