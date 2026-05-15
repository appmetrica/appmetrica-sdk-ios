
#import "AMAAppMetricaImpl.h"
#import "AMADispatcherDelegate.h"
#import "AMADispatchStrategyDelegate.h"

@class AMAAppMetricaConfiguration;
@class AMAEventCountDispatchStrategy;
@class AMATimerDispatchStrategy;
@class AMADispatchStrategiesContainer;
@class AMADispatcher;
@class AMADispatchingController;
@class AMAReporter;
@protocol AMAHostStateProviding;

@interface AMAAppMetricaImpl () <AMADispatcherDelegate, AMADispatchStrategyDelegate>

@property (nonatomic, strong) AMAReporter *mainReporter;
@property (nonatomic, strong) AMADispatchingController *dispatchingController;
@property (nonatomic, strong) AMADispatchStrategiesContainer *strategiesContainer;

- (void)dispatcherDidPerformStartup:(AMADispatcher *)dispatcher
                             failed:(BOOL)failure
                            fakeRun:(BOOL)fakeRun;
- (void)notifyOnStartupCompleted;
- (void)reportDatabaseInconsistencyStateIfNeeded;
- (void)start;

- (void)activateCommonComponents:(AMAAppMetricaConfiguration *)configuration
                        reporter:(AMAReporter *)reporter;

@end

@interface AMAAppMetricaImpl (TestUtilities)

- (AMAEventCountDispatchStrategy *)eventCountDispatchStrategyInSet:(NSSet *)strategies forApiKey:(NSString *)apiKey;
- (AMATimerDispatchStrategy *)timerDispatchStrategyInSet:(NSSet *)strategies forApiKey:(NSString *)apiKey;

@end


