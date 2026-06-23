#import <Foundation/Foundation.h>
#import <AppMetricaCore/AppMetricaCore.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AMAAppMetricaEventData;

NS_SWIFT_NAME(AppMetricaInternalEvent)
@protocol AMAAppMetricaInternalEvent <AMAAppMetricaEvent>

@property (nonatomic, copy, readonly) id<AMAAppMetricaEventData> eventData;

@end

NS_ASSUME_NONNULL_END
