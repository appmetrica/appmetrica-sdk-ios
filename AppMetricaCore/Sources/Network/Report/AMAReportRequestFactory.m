
#import "AMAReportRequestFactory.h"
#import "AMAReportRequest.h"

@implementation AMARegularReportRequestFactory

- (nonnull AMAReportRequest *)reportRequestWithPayload:(nonnull AMAReportPayload *)reportPayload
                                     requestIdentifier:(nonnull NSString *)requestIdentifier
{
    return [AMAReportRequest reportRequestWithPayload:reportPayload
                                    requestIdentifier:requestIdentifier
                               requestParamterOptions:AMARequestParametersDefault];
}

@end


@implementation AMATrackingReportRequestFactory


- (nonnull AMAReportRequest *)reportRequestWithPayload:(nonnull AMAReportPayload *)reportPayload
                                     requestIdentifier:(nonnull NSString *)requestIdentifier
{
    return [AMAReportRequest reportRequestWithPayload:reportPayload
                                    requestIdentifier:requestIdentifier
                               requestParamterOptions:AMARequestParametersTracking];
}

@end
