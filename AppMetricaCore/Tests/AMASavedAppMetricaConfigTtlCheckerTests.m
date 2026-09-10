#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMASavedAppMetricaConfigTtlChecker.h"

SPEC_BEGIN(AMASavedAppMetricaConfigTtlCheckerTests)

describe(@"AMASavedAppMetricaConfigTtlChecker", ^{

    NSDate *__block savedAt = nil;
    NSTimeInterval __block ttl = 0;

    beforeEach(^{
        savedAt = [NSDate dateWithTimeIntervalSince1970:1000000.0];
        ttl = AMASavedAppMetricaConfigTtlChecker.savedAppMetricaConfigTTL;
    });

    it(@"Should use 30-day TTL in seconds", ^{
        [[theValue(ttl) should] equal:theValue(30.0 * 24.0 * 60.0 * 60.0)];
    });

    it(@"Should not expire when clock skews backwards", ^{
        NSDate *now = [savedAt dateByAddingTimeInterval:-1.0];
        [[theValue([AMASavedAppMetricaConfigTtlChecker isExpiredForSavedAt:savedAt now:now]) should] beNo];
    });

    it(@"Should not expire at savedAt", ^{
        [[theValue([AMASavedAppMetricaConfigTtlChecker isExpiredForSavedAt:savedAt now:savedAt]) should] beNo];
    });

    it(@"Should not expire just before TTL", ^{
        NSDate *now = [savedAt dateByAddingTimeInterval:ttl - 1.0];
        [[theValue([AMASavedAppMetricaConfigTtlChecker isExpiredForSavedAt:savedAt now:now]) should] beNo];
    });

    it(@"Should expire at exact TTL boundary", ^{
        NSDate *now = [savedAt dateByAddingTimeInterval:ttl];
        [[theValue([AMASavedAppMetricaConfigTtlChecker isExpiredForSavedAt:savedAt now:now]) should] beYes];
    });

    it(@"Should expire after TTL", ^{
        NSDate *now = [savedAt dateByAddingTimeInterval:ttl + 1.0];
        [[theValue([AMASavedAppMetricaConfigTtlChecker isExpiredForSavedAt:savedAt now:now]) should] beYes];
    });

});

SPEC_END
