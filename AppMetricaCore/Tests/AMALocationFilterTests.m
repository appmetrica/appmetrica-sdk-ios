
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMALocationFilter.h"
#import "AMALocationCollectingConfiguration.h"
#import <CoreLocation/CoreLocation.h>

SPEC_BEGIN(AMALocationFilterTests)

describe(@"AMALocationFilter", ^{

    NSTimeInterval const minInterval = 10.0;
    double const minDistance = 10.0;
    double const minDistanceAngle = minDistance * 360 / 40000000;

    NSDate *__block now = nil;
    CLLocation *__block location = nil;
    AMALocationCollectingConfiguration *__block configuration = nil;
    AMALocationFilter *__block filter = nil;

    beforeEach(^{
        now = [NSDate date];
        location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(0.0, 0.0)
                                                 altitude:0.0
                                       horizontalAccuracy:0.0
                                         verticalAccuracy:0.0
                                                timestamp:now];

        configuration = [AMALocationCollectingConfiguration nullMock];
        [configuration stub:@selector(minUpdateInterval) andReturn:theValue(minInterval)];
        [configuration stub:@selector(minUpdateDistance) andReturn:theValue(minDistance)];
        filter = [[AMALocationFilter alloc] initWithConfiguration:configuration];
    });

    context(@"First location", ^{
        it(@"Should return YES", ^{
            [[theValue([filter shouldAddLocation:location atDate:now]) should] beYes];
        });
    });
    context(@"Second location", ^{
        beforeEach(^{
            [filter updateLastLocation:location atDate:now];
        });
        context(@"Before limits", ^{
            beforeEach(^{
                now = [now dateByAddingTimeInterval:minInterval - 1.0];
                location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(0.0, minDistanceAngle * 0.9)
                                                         altitude:0.0
                                               horizontalAccuracy:0.0
                                                 verticalAccuracy:0.0
                                                        timestamp:now];
            });
            it(@"Should return NO", ^{
                [[theValue([filter shouldAddLocation:location atDate:now]) should] beNo];
            });
        });
        context(@"After distabce limit (latitude)", ^{
            beforeEach(^{
                now = [now dateByAddingTimeInterval:minInterval - 1.0];
                location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(minDistanceAngle * 1.1, 0.0)
                                                         altitude:0.0
                                               horizontalAccuracy:0.0
                                                 verticalAccuracy:0.0
                                                        timestamp:now];
            });
            it(@"Should return YES", ^{
                [[theValue([filter shouldAddLocation:location atDate:now]) should] beYes];
            });
        });
        context(@"After distabce limit (longitude)", ^{
            beforeEach(^{
                now = [now dateByAddingTimeInterval:minInterval - 1.0];
                location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(0.0, minDistanceAngle * 1.1)
                                                         altitude:0.0
                                               horizontalAccuracy:0.0
                                                 verticalAccuracy:0.0
                                                        timestamp:now];
            });
            it(@"Should return YES", ^{
                [[theValue([filter shouldAddLocation:location atDate:now]) should] beYes];
            });
        });
        context(@"After time interval limit", ^{
            beforeEach(^{
                now = [now dateByAddingTimeInterval:minInterval + 0.1];
                location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(0.0, 0.0)
                                                         altitude:0.0
                                               horizontalAccuracy:0.0
                                                 verticalAccuracy:0.0
                                                        timestamp:now];
            });
            it(@"Should return YES", ^{
                [[theValue([filter shouldAddLocation:location atDate:now]) should] beYes];
            });
        });
        context(@"After all limits", ^{
            beforeEach(^{
                now = [now dateByAddingTimeInterval:minInterval + 1.0];
                location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(0.0, minDistanceAngle * 1.1)
                                                         altitude:0.0
                                               horizontalAccuracy:0.0
                                                 verticalAccuracy:0.0
                                                        timestamp:now];
            });
            it(@"Should return YES", ^{
                [[theValue([filter shouldAddLocation:location atDate:now]) should] beYes];
            });
        });
    });

});

SPEC_END

