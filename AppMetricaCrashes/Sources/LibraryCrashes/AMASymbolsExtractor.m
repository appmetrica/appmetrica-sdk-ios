
#import "AMACrashLogging.h"
#import "AMASymbolsExtractor.h"
#import "AMABinaryImage.h"
#import "AMASymbol.h"
#import "AMASymbolsCollection.h"
#import "AMACrashMatchingRule.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <objc/runtime.h>
#import "KSDynamicLinker.h"

static NSUInteger const kAMADefaultSymbolSize = 1;

@implementation AMASymbolsExtractor

+ (AMASymbolsCollection *)symbolsCollectionForRule:(AMACrashMatchingRule *)rule
{
#if defined(DEBUG)
    NSDate *startTime = [NSDate date];
#endif

    NSArray *symbols = nil;
    NSArray *images = nil;

    @try {
        NSMutableArray *allSymbols = [NSMutableArray array];
        if (rule.classes.count > 0) {
            [allSymbols addObjectsFromArray:[self symbolsOfClasses:rule.classes]];
        }
        if (rule.classPrefixes.count > 0) {
            AMALogWarn(@"Class-prefixes-based crash reporting are disabled. See https://nda.ya.ru/t/XFzsPvep6fHaTF.");
            // TODO(https://nda.ya.ru/t/XFzsPvep6fHaTF): Enable back after crashes are fixed.
            // [allSymbols addObjectsFromArray:[self symbolsOfClassesWithPrefixes:rule.classPrefixes]];
        }

        if (allSymbols.count > 0) {
            symbols = [self symbolsWithFilledSize:allSymbols];
            images = [self sharedImages];
        }

    }
    @catch (NSException *exception) {
        AMALogError(@"Symbols generation failed with exception: %@", exception.description);
    }

    AMASymbolsCollection *collection = [[AMASymbolsCollection alloc] initWithSymbols:symbols
                                                                              images:images
                                                                  dynamicBinaryNames:rule.dynamicBinaryNames];

#if defined(DEBUG) && !AMA_RELEASE
    AMALogInfo(@"Symbols extraction time: %f", -[startTime timeIntervalSinceNow]);
    startTime = nil; // FIXME(https://nda.ya.ru/t/__fqTWIu6fHaU3): raises 'Unused variable warning' if logs disabled 
#endif
    return collection;
}

#pragma mark - Symbols extraction

+ (NSArray *)symbolsOfClassesWithPrefixes:(NSArray *)prefixes
{
    NSMutableArray *classesToAdd = [NSMutableArray array];

    [self enumerateClassesWithBlock:^(Class aClass) {
        NSString *className = NSStringFromClass(aClass);
        for (NSString *prefix in prefixes) {
            if ([className hasPrefix:prefix]) {
                [classesToAdd addObject:aClass];
                break;
            }
        }
    }];

    return [self symbolsOfClasses:classesToAdd];
}

+ (NSArray *)symbolsOfClasses:(NSArray *)classes
{
    NSMutableArray *symbols = [NSMutableArray array];
    for (Class aClass in classes) {
        NSArray *classSymbols = [self symbolsOfClass:aClass];
        [symbols addObjectsFromArray:classSymbols];
    }
    return [symbols copy];
}

+ (NSArray *)symbolsOfClass:(Class)aClass
{
    NSMutableArray *symbols = [NSMutableArray array];
    [self enumerateMethodsOfClass:aClass block:^(Class methodClass, Method method) {
        AMASymbol *symbol = [self symbolForMethod:method ofClass:methodClass];
        if (symbol != nil) {
            [symbols addObject:symbol];
        }
    }];

    return [symbols copy];
}

+ (AMASymbol *)symbolForMethod:(Method)method ofClass:(Class)aClass
{
    IMP methodImplementation = method_getImplementation(method);
    NSUInteger methodAddress = (NSUInteger)methodImplementation;

    BOOL isInstanceMethod = class_isMetaClass(aClass) == NO;
    NSString *methodName = [self stringIgnoringNULL:sel_getName(method_getName(method))];
    NSString *className = [self stringIgnoringNULL:class_getName(aClass)];

    AMASymbol *symbol = [[AMASymbol alloc] initWithMethodName:methodName
                                                    className:className
                                             isInstanceMethod:isInstanceMethod
                                                      address:methodAddress
                                                         size:0];
    return symbol;
}

#pragma mark - Symbols processing utilities

+ (NSArray *)symbolsWithFilledSize:(NSArray *)symbols
{
    if (symbols.count <= 1) {
        return symbols;
    }

    NSMutableArray *allFilledSymbols = [NSMutableArray arrayWithCapacity:symbols.count];
    NSArray *orderedSymbols = [self orderedSymbols:symbols];

    for (NSUInteger index = 0; index < orderedSymbols.count - 1; ++index) {
        AMASymbol *symbol = orderedSymbols[index];
        AMASymbol *filledSymbol = symbol;

        if (symbol.size == 0) {
            AMASymbol *nextSymbol = orderedSymbols[index + 1];
            NSUInteger symbolSize = nextSymbol.address - symbol.address;

            // We could not guarantee that different classes will be placed one after other,
            // that's why we think that the last symbol of the class is 1-byte-sized.
            // This assumption allows us to find this symbol by its address,
            // but not by any instruction address, so for not-stripped builds,
            // everything will work just fine.
            if ([nextSymbol.className isEqualToString:symbol.className] == NO) {
                symbolSize = kAMADefaultSymbolSize;
            }

            filledSymbol = [symbol symbolByChangingSize:symbolSize];
        }
        if (filledSymbol != nil) {
            [allFilledSymbols addObject:filledSymbol];
        }
    }

    AMASymbol *lastFilledSymbol = [orderedSymbols.lastObject symbolByChangingSize:kAMADefaultSymbolSize];
    if (lastFilledSymbol != nil) {
        [allFilledSymbols addObject:lastFilledSymbol];
    }

    return [allFilledSymbols copy];
}

+ (NSArray *)orderedSymbols:(NSArray *)symbols
{
    NSSortDescriptor *selfDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    return [symbols sortedArrayUsingDescriptors:@[ selfDescriptor ]];
}

+ (NSString *)stringIgnoringNULL:(const char *)UTFString
{
    return UTFString == NULL ? nil : [NSString stringWithUTF8String:UTFString];
}

#pragma mark - Classes and methods enumeration

+ (void)enumerateClassesWithBlock:(void(^)(__unsafe_unretained Class aClass))block
{
    if (block == nil) {
        return;
    }

    unsigned int classesCount = 0;
    Class *classes = objc_copyClassList(&classesCount);
    for (unsigned int classIndex = 0; classIndex < classesCount; ++classIndex) {
        block(classes[classIndex]);
    }
    free(classes);
}

+ (void)enumerateMethodsOfClass:(Class)aClass
                          block:(void(^)(Class aClass, Method method))block
{
    [self enumerateMethodsOfPartialClass:aClass block:block];
    [self enumerateMethodsOfPartialClass:object_getClass(aClass) block:block];
}

+ (void)enumerateMethodsOfPartialClass:(Class)aClass
                                 block:(void(^)(Class aClass, Method method))block
{
    if (block == nil) {
        return;
    }

    unsigned int methodsCount = 0;
    Method *methods = class_copyMethodList(aClass, &methodsCount);
    for (unsigned int methodIndex = 0; methodIndex < methodsCount; ++methodIndex) {
        block(aClass, methods[methodIndex]);
    }
    free(methods);
}

#pragma mark - Binary images extraction

+ (NSArray *)sharedImages
{
    static NSArray *images = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        images = [self images];
    });

    return images;
}

+ (NSArray<AMABinaryImage *> *)userApplicationImages
{
    static NSArray *userApplicationImages = nil;
    static dispatch_once_t userOnceToken;
    dispatch_once(&userOnceToken, ^{
        userApplicationImages = [self filterUserImages:self.sharedImages];
    });
    
    return userApplicationImages;
}

+ (NSArray<AMABinaryImage *> *)filterUserImages:(NSArray<AMABinaryImage *> *)images
{
    NSArray *const kSystemPatterns = @[
        @"^/usr/lib",
        @"^/System/Library",
        @"^/Developer",
        @"Xcode.*/Developer",
    ];
    
    NSArray *regexes = [AMACollectionUtilities mapArray:kSystemPatterns withBlock:^id(id item) {
        return [NSRegularExpression regularExpressionWithPattern:item
                                                         options:NSRegularExpressionAnchorsMatchLines
                                                           error:nil];
    }];
    
    NSMutableArray *result = [NSMutableArray array];
    [images enumerateObjectsUsingBlock:^(AMABinaryImage *obj, NSUInteger idx, BOOL *stop) {
        if ([self path:obj.name hasAtLeastOneMatch:regexes] == NO) {
            [result addObject:obj];
        }
    }];
    return [result copy];
}

+ (BOOL)path:(NSString *)path hasAtLeastOneMatch:(NSArray<NSRegularExpression *> *)patterns
{
    for (NSRegularExpression *regex in patterns) {
        if ([regex firstMatchInString:path options:0 range:NSMakeRange(0, path.length)] != nil) {
            return YES;
        }
    }
    return NO;
}

+ (NSArray *)images
{
    int imageCount = ksdl_imageCount();
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:(NSUInteger)imageCount];
    for (int index = 0; index < imageCount; ++index) {
        AMABinaryImage *image = [self imageForImageIndex:index];
        if (image != nil) {
            [images addObject:image];
        }
    }
    return [images copy];
}

+ (AMABinaryImage *)imageForImageIndex:(int)index
{
    KSBinaryImage ksImage = { 0 };
    if (ksdl_getBinaryImage(index, &ksImage) == false) {
        return nil;
    }
    return [self binaryImageForImage:&ksImage];
}

+ (AMABinaryImage *)imageForImageHeader:(void *)machHeaderPtr name:(const char *)name
{
    KSBinaryImage ksImage = { 0 };
    if (ksdl_getBinaryImageForHeader(machHeaderPtr, name, &ksImage) == false) {
        return nil;
    }
    return [self binaryImageForImage:&ksImage];
}

+ (AMABinaryImage *)binaryImageForImage:(KSBinaryImage *)ksImage
{
    CFUUIDRef uuidRef = CFUUIDCreateFromUUIDBytes(NULL, *((CFUUIDBytes *)ksImage->uuid));
    NSString *imageUUID = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);

    return [[AMABinaryImage alloc] initWithName:[self stringForCString:ksImage->name]
                                           UUID:imageUUID
                                        address:(NSUInteger)ksImage->address
                                           size:(NSUInteger)ksImage->size
                                      vmAddress:(NSUInteger)ksImage->vmAddress
                                        cpuType:(NSUInteger)ksImage->cpuType
                                     cpuSubtype:(NSUInteger)ksImage->cpuSubType
                                   majorVersion:(int32_t)ksImage->majorVersion
                                   minorVersion:(int32_t)ksImage->minorVersion
                                revisionVersion:(int32_t)ksImage->revisionVersion
                               crashInfoMessage:[self stringForCString:ksImage->crashInfoMessage]
                              crashInfoMessage2:[self stringForCString:ksImage->crashInfoMessage2]];
}

+ (NSString *)stringForCString:(const char *)cString
{
    if (cString == NULL) {
        return nil;
    }
    return [NSString stringWithUTF8String:cString];
}

@end
