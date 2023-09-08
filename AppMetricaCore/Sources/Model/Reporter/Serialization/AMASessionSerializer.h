
#import <Foundation/Foundation.h>

@class AMASession;

NS_ASSUME_NONNULL_BEGIN

@interface AMASessionSerializer : NSObject

- (NSDictionary *)dictionaryForSession:(AMASession *)session error:(NSError **)error;
- (AMASession *)sessionForDictionary:(NSDictionary *)dictionary error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
