
#import <Foundation/Foundation.h>

NS_SWIFT_NAME(TimeUtilities)
@interface AMATimeUtilities : NSObject

+ (NSTimeInterval)intervalWithNumber:(NSNumber *)value defaultInterval:(NSTimeInterval)defaultInterval;
+ (NSString *)timestampForDate:(NSDate *)date;
+ (NSTimeInterval)timeSinceFirstStartupUpdate:(NSDate *)firstStartupUpdateDate
                        lastStartupUpdateDate:(NSDate *)lastStartupUpdateDate
                         lastServerTimeOffset:(NSNumber *)lastServerTimeOffset;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end
