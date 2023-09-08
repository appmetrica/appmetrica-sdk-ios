
#import <AppMetricaHostState/AppMetricaHostState.h>
#import "AMAHostStatePublisher.h"
#import "AMAHostStateControlling.h"

@interface AMAExtensionHostStateProvider : AMAHostStatePublisher<AMAHostStateControlling>

- (instancetype)initWithNotificationCenter:(NSNotificationCenter *)center NS_DESIGNATED_INITIALIZER;

@end
