
#import <Foundation/Foundation.h>

@class AMASymbolsCollection;
@class AMACrashMatchingRule;
@class AMABinaryImage;

@interface AMASymbolsExtractor : NSObject

+ (AMASymbolsCollection *)symbolsCollectionForRule:(AMACrashMatchingRule *)rule;

+ (NSArray<AMABinaryImage *> *)sharedImages;
+ (NSArray<AMABinaryImage *> *)userApplicationImages;

+ (AMABinaryImage *)imageForImageHeader:(void *)machHeaderPtr name:(const char *)name;

@end
