
#import <Foundation/Foundation.h>
#import "AMASearchAdsRequester.h"

@interface AMASearchAdsReporter : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithApiKey:(NSString *)apiKey;

- (void)reportAttributionAttempt;
- (void)reportAttributionSuccessWithInfo:(NSDictionary *)info;
- (void)reportAttributionErrorWithCode:(AMASearchAdsRequesterErrorCode)errorCode description:(NSString *)description;

@end
