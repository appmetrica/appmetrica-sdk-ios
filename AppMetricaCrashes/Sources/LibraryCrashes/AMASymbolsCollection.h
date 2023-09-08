
#import <Foundation/Foundation.h>

@class AMASymbol;
@class AMABinaryImage;

@interface AMASymbolsCollection : NSObject <NSCopying>

@property (nonatomic, copy, readonly) NSArray<AMASymbol *> *symbols;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, AMABinaryImage *> *images;
@property (nonatomic, copy, readonly) NSSet<NSString *> *dynamicBinaryNames;

@property (nonatomic, assign, readonly) NSUInteger count;

- (instancetype)initWithSymbols:(NSArray<AMASymbol *> *)symbols
                         images:(NSArray<AMABinaryImage *> *)images
             dynamicBinaryNames:(NSArray<NSString *> *)dynamicBinaryNames;

- (AMASymbol *)symbolForAddress:(NSUInteger)address binaryImage:(AMABinaryImage *)binaryImage;
- (BOOL)containsDynamicBinaryWithName:(NSString *)binaryName;

@end
