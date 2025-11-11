
#import "AMAFailureDispatcherTestHelper.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>

@implementation AMAFailureDispatcherTestHelper

+ (void)stubFailureDispatcher
{
    [AMAFailureDispatcher stub:@selector(dispatchError:withBlock:) withBlock:^id(NSArray *params) {
        NSError *error = params[0];
        void (^block)(NSError *) = [params[1] isKindOfClass:[NSNull class]] ? nil : params[1];
        if (error != nil && block != nil) {
            block(error);
        }
        return nil;
    }];
}

@end
