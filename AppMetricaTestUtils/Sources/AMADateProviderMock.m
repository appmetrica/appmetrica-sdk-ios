
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@interface AMADateProviderMock () {
    NSDate *_currentDate;
}
@end

@implementation AMADateProviderMock

- (instancetype)init
{
    self = [super init];

    if (self != nil) {
        _currentDate = nil;
    }

    return self;
}

- (NSDate *)currentDate
{
    return _currentDate ? _currentDate : [NSDate date];
}

- (NSDate *)freeze
{
    NSDate *date = [NSDate date];
    [self freezeWithDate:date];
    return date;
}

- (void)freezeWithDate:(NSDate *)date
{
    _currentDate = date;
}

@end
