
#import <AppMetricaNetwork/AppMetricaNetwork.h>

@class AMAReportResponse;

@interface AMAReportResponseParser : NSObject <AMAHostExchangeResponseValidating>

- (AMAReportResponse *)responseForData:(NSData *)data;

@end
