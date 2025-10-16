
#import "AMAIDSyncPreconditionHandler.h"
#import <Foundation/Foundation.h>
#import <Network/Network.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>

static NSString *const kAMAIDSyncNetworkPreconditionKey = @"network";
static NSString *const kAMAIDSyncNetworkPreconditionCellKey = @"cell";

@implementation AMAIDSyncPreconditionHandler

- (void)canExecuteRequestWithPreconditions:(NSDictionary *)preconditions
                                completion:(void (^)(BOOL))completion
{
    NSString *networkCondition = preconditions[kAMAIDSyncNetworkPreconditionKey];
    
    if ([networkCondition isEqualToString:kAMAIDSyncNetworkPreconditionCellKey]) {
        [AMAPlatformDescription isCellularConnection:^(BOOL isCellular) {
            completion(isCellular);
        }];
    } else {
        completion(YES);
    }
}

@end
