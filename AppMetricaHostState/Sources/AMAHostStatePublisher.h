
#import <AppMetricaHostState/AppMetricaHostState.h>

@interface AMAHostStatePublisher : NSObject <AMABroadcasting>

- (void)hostStateDidChange;

@end
