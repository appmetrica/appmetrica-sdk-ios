
#import <Foundation/Foundation.h>

@class AMAIDSyncStartupResponse;

NS_ASSUME_NONNULL_BEGIN

@interface AMAIDSyncStartupResponseParser : NSObject

- (nullable AMAIDSyncStartupResponse *)parseStartupResponse:(NSDictionary *)response;

@end

NS_ASSUME_NONNULL_END
