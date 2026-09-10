#import "AMASavedAppMetricaConfigTtlChecker.h"

static const NSTimeInterval kAMASavedAppMetricaConfigTTL = 30.0 * 24.0 * 60.0 * 60.0;

@implementation AMASavedAppMetricaConfigTtlChecker

+ (NSTimeInterval)savedAppMetricaConfigTTL
{
    return kAMASavedAppMetricaConfigTTL;
}

+ (BOOL)isExpiredForSavedAt:(NSDate *)savedAt now:(NSDate *)now
{
    NSTimeInterval nowInterval = now.timeIntervalSince1970;
    NSTimeInterval savedAtInterval = savedAt.timeIntervalSince1970;
    if (nowInterval < savedAtInterval) {
        return NO;
    }
    return (nowInterval - savedAtInterval) >= kAMASavedAppMetricaConfigTTL;
}

@end
