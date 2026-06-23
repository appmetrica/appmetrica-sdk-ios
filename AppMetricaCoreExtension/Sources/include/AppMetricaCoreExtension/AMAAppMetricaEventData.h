
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AppMetricaEventData)
@protocol AMAAppMetricaEventData <NSObject>

@property (nonatomic, copy, readonly, nullable) NSString *name;
@property (nonatomic, assign, readonly) NSUInteger type;
@property (nonatomic, copy, readonly, nullable) NSData *data;
@property (nonatomic, assign, readonly) NSUInteger bytesTruncated;

@end

NS_ASSUME_NONNULL_END
