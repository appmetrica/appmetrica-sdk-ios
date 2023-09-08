
#import <Foundation/Foundation.h>

@class AMASymbolsCollection;

@interface AMASymbolsCollectionSerializer : NSObject

+ (NSData *)dataForCollection:(AMASymbolsCollection *)collection;
+ (AMASymbolsCollection *)collectionForData:(NSData *)data;

@end
