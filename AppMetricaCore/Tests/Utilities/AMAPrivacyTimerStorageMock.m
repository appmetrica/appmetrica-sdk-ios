
#import "AMAPrivacyTimerStorageMock.h"

@interface AMAPrivacyTimerStorageMock () {
    NSArray<NSNumber *> *_retryPeriod;
}

@end

@implementation AMAPrivacyTimerStorageMock

- (NSArray<NSNumber *> *)retryPeriod
{
    [self.retryPeriodExpectation fulfill];
    return _retryPeriod;
}

- (void)setRetryPeriod:(NSArray<NSNumber *> *)retryPeriod
{
    _retryPeriod = [retryPeriod copy];
}

- (BOOL)isResendPeriodOutdated {
    [self.isResendPeriodOutdatedExpection fulfill];
    return _isResendPeriodOutdated;
}

- (void) privacyEventSent
{
    [self.privacyEventSentExpectation fulfill];
}

@end
