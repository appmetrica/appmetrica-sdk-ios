
#import "AMASymbolsCollection.h"
#import "AMASymbol.h"
#import "AMABinaryImage.h"
#import "AMABacktraceFrame.h"

@implementation AMASymbolsCollection

- (instancetype)initWithSymbols:(NSArray<AMASymbol *> *)symbols
                         images:(NSArray<AMABinaryImage *> *)images
             dynamicBinaryNames:(NSArray<NSString *> *)dynamicBinaryNames
{
    self = [super init];
    if (self != nil) {
        NSSortDescriptor *selfDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
        _symbols = [symbols sortedArrayUsingDescriptors:@[ selfDescriptor ]];

        NSMutableDictionary *imagesDictionary = [NSMutableDictionary dictionaryWithCapacity:images.count];
        for (AMABinaryImage *image in images) {
            if (image.UUID != nil) {
                imagesDictionary[image.UUID] = image;
            }
        }
        _images = [imagesDictionary copy];
        _dynamicBinaryNames = [NSSet setWithArray:dynamicBinaryNames];
    }
    return self;
}

- (NSUInteger)count
{
    return self.symbols.count;
}

- (AMASymbol *)symbolForAddress:(NSUInteger)address binaryImage:(AMABinaryImage *)binaryImage
{
    AMASymbol *symbol = nil;
    if (binaryImage.name != nil) {
        AMABinaryImage *originalImage = self.images[binaryImage.UUID];
        if (originalImage != nil) {
            NSInteger imagesDelta = (NSInteger)originalImage.address - (NSInteger)binaryImage.address;
            NSUInteger originalAddress = (NSUInteger)((NSInteger)address + imagesDelta);

            AMASymbol *collectionSymbol = [self binarySearchForAddress:originalAddress];
            if (collectionSymbol != nil) {
                NSUInteger actualSymbolAddress = (NSUInteger)((NSInteger)collectionSymbol.address - imagesDelta);
                symbol = [collectionSymbol symbolByChangingAddress:actualSymbolAddress];
            }
        }
    }
    return symbol;
}

- (AMASymbol *)binarySearchForAddress:(NSUInteger)address
{
    AMASymbol *symbol = nil;

    AMASymbol *firstSymbol = self.symbols.firstObject;
    AMASymbol *lastSymbol = self.symbols.lastObject;
    // This condition will fail for most system symbols and could save O(log(n)) time.
    if (address >= firstSymbol.address && address < lastSymbol.address + lastSymbol.size) {
        NSUInteger left = 0, right = self.symbols.count;

        while (left < right) {
            NSUInteger middle = left + (right - left) / 2;
            AMASymbol *middleSymbol = self.symbols[middle];
            if (middleSymbol.address > address) {
                right = middle;
            }
            else {
                if (address < middleSymbol.address + middleSymbol.size) {
                    symbol = middleSymbol;
                    break;
                }
                left = middle + 1;
            }
        }
    }

    return symbol;
}

- (BOOL)containsDynamicBinaryWithName:(NSString *)binaryName
{
    return [self.dynamicBinaryNames containsObject:binaryName];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
