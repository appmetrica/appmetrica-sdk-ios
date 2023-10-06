
#import "AMAAppMetrica.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@class AMAAppMetricaImpl;
@class AMADeepLinkController;
@protocol AMAEventPollingDelegate;

@interface AMAAppMetrica ()

@property (class, readonly) NSArray<Class<AMAEventPollingDelegate>> *eventPollingDelegates;

+ (NSUInteger)dispatchPeriod;
+ (NSUInteger)maxReportsCount;
+ (NSUInteger)sessionTimeout;

+ (AMAAppMetricaImpl *)sharedImpl;
+ (id<AMAExecuting>)sharedExecutor;

+ (void)asyncUpdatePersistentConfigurationWithUUID:(NSString *)UUID;

+ (void)reportEventWithType:(NSUInteger)eventType
                       name:(NSString *)name
                      value:(NSString *)value
                environment:(NSDictionary *)environment
                  onFailure:(void (^)(NSError *error))onFailure;
@end

@interface AMAAppMetrica (TestUtilities)

+ (void)amatest_stubStrategiesWithTypeMask:(unsigned int)typeMask;

@end
