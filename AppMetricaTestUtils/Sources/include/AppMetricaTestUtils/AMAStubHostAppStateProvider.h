
#import <Foundation/Foundation.h>
#import <AppMetricaHostState/AppMetricaHostState.h>

NS_SWIFT_NAME(StubHostAppStateProvider)
@interface AMAStubHostAppStateProvider : NSObject<AMAHostStateProviding>

@property (nonatomic, assign) AMAHostAppState hostState;

@end
