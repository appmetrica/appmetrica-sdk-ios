
#import <AppMetricaProtobufUtils/AppMetricaProtobufUtils.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMAAllocationsTrackingMock : NSObject <AMAAllocationsTracking>
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSData *> *allocations;
@end

NS_ASSUME_NONNULL_END
