
#import <AppMetricaNetwork/AppMetricaNetwork.h>

@class AMAReportPayload;

@interface AMAReportRequest : AMAGenericRequest

@property (nonatomic) AMARequestParametersOptions requestParamtersOptions;
@property (nonatomic, strong, readonly) AMAReportPayload *reportPayload;
@property (nonatomic, copy, readonly) NSString *requestIdentifier;

+ (instancetype)reportRequestWithPayload:(AMAReportPayload *)reportPayload
                       requestIdentifier:(NSString *)requestIdentifier
                  requestParamterOptions:(AMARequestParametersOptions)requestParamtersOptions;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end
