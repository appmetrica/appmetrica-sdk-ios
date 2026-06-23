
#import <Foundation/Foundation.h>
#import "AMAAppMetricaEventData.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(StaticEventData)
@interface AMAStaticEventData : NSObject <AMAAppMetricaEventData, NSCopying>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithName:(nullable NSString *)name
                        type:(NSUInteger)type
                        data:(nullable NSData *)data
              bytesTruncated:(NSUInteger)bytesTruncated NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
