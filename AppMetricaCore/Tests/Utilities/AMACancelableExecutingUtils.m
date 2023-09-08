
#import "AMACancelableExecutingUtils.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <Kiwi/Kiwi.h>

@implementation AMACancelableExecutingUtils

+ (id<AMACancelableExecuting>)stubCancellableExecutor
{
    id executor = [KWMock nullMockForProtocol:@protocol(AMACancelableExecuting)];
    [executor stub:@selector(execute:) withBlock:^id (NSArray *params) {
        void (^block)(void) = params[0];
        block();
        return nil;
    }];
    return executor;
}

@end
