
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

@implementation AMATimeUtilities

+ (NSTimeInterval)intervalWithNumber:(NSNumber *)value defaultInterval:(NSTimeInterval)defaultInterval
{
    return [AMANumberUtilities doubleWithNumber:value defaultValue:defaultInterval];
}

+ (NSString *)timestampForDate:(NSDate *)date
{
    return [NSString stringWithFormat:@"%llu", (uint64_t)[date timeIntervalSince1970]];
}

+ (NSTimeInterval)timeSinceFirstStartupUpdate:(NSDate *)firstStartupUpdateDate
                        lastStartupUpdateDate:(NSDate *)lastStartupUpdateDate
                         lastServerTimeOffset:(NSNumber *)lastServerTimeOffset
{
    NSTimeInterval timeSinceFirstStartupUpdate = 0;
    if (firstStartupUpdateDate != nil && lastServerTimeOffset != nil) {
        NSTimeInterval serverTimeOffset = [lastServerTimeOffset doubleValue];
        if (lastStartupUpdateDate != nil) {
            NSDate *startupUpdatedAt = [lastStartupUpdateDate dateByAddingTimeInterval:serverTimeOffset];
            timeSinceFirstStartupUpdate = [startupUpdatedAt timeIntervalSinceDate:firstStartupUpdateDate];
        }
    }
    return timeSinceFirstStartupUpdate < 1.0 ? 0.0 : timeSinceFirstStartupUpdate;
}

@end
