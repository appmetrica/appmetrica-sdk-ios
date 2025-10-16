
#import <Foundation/Foundation.h>
#import <AppMetricaNetwork/AppMetricaNetwork.h>

@interface AMAIDSyncNetworkRequest : AMAGenericRequest

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithURL:(NSString *)url
                    headers:(NSDictionary *)headers;

@end
