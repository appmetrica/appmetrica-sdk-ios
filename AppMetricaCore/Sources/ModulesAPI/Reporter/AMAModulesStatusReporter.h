
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AMADateProviding;

@class AMAInternalEventsReporter;
@class AMAModulesController;
@class AMAMetricaPersistentConfiguration;

@interface AMAModulesStatusReporter : NSObject

- (instancetype)initWithReporter:(AMAInternalEventsReporter *)reporter
               modulesController:(AMAModulesController *)modulesController
         persistentConfiguration:(AMAMetricaPersistentConfiguration *)persistentConfiguration
                    dateProvider:(id<AMADateProviding>)dateProvider NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)report;

@end

NS_ASSUME_NONNULL_END
