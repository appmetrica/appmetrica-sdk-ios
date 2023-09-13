
#import <AppMetricaNetwork/AppMetricaNetwork.h>

@class AMAReportPayload;

@interface AMAReportRequest : AMAGenericRequest

@property (nonatomic, strong, readonly) AMAReportPayload *reportPayload;
@property (nonatomic, copy, readonly) NSString *requestIdentifier;

+ (instancetype)reportRequestWithPayload:(AMAReportPayload *)reportPayload
                       requestIdentifier:(NSString *)requestIdentifier;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end
