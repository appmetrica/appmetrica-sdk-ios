#import <Foundation/Foundation.h>
#import "AMAJSONSerializable.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAModulesStatusReportState : NSObject <AMAJSONSerializable, NSCopying>

@property (nonatomic, copy, readonly, nullable) NSDate *lastSentDate;
@property (nonatomic, copy, readonly, nullable) NSDictionary<NSString *, NSNumber *> *moduleStatuses;

- (instancetype)initWithLastSentDate:(nullable NSDate *)lastSentDate
                      moduleStatuses:(nullable NSDictionary<NSString *, NSNumber *> *)moduleStatuses
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
