
#import <Foundation/Foundation.h>
#import "AMAIDSyncNetworkRequest.h"

@class AMAIDSyncRequestResponse;

NS_ASSUME_NONNULL_BEGIN

@interface AMAIDSyncReportRequest : AMAGenericRequest

- (instancetype)initWithResponse:(AMAIDSyncRequestResponse *)response;

@end

NS_ASSUME_NONNULL_END
