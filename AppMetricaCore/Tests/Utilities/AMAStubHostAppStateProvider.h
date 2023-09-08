
#import <Foundation/Foundation.h>
#import <AppMetricaHostState/AppMetricaHostState.h>

@interface AMAStubHostAppStateProvider : NSObject<AMAHostStateProviding>

@property (nonatomic, assign) AMAHostAppState hostState;

@end
