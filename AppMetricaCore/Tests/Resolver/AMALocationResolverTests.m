#import <XCTest/XCTest.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMALocationManager.h"
#import "AMALocationResolver.h"

SPEC_BEGIN(AMALocationResolverTests)

describe(@"AMALocationResolver", ^{
    AMALocationManager *__block locationManager = nil;
    AMALocationResolver *__block resolver = nil;
    
    beforeEach(^{
        locationManager = [AMALocationManager nullMock];
        [locationManager stub:@selector(setEnabled:)];
        resolver = [[AMALocationResolver alloc] initWithLocationManager:locationManager];
    });
    
    context(@"Update value", ^{
        it(@"should call setEnabled", ^{
            [[locationManager should] receive:@selector(setTrackLocationEnabled:) withArguments:theValue(NO)];
            [resolver updateWithValue:NO];
        });
    });
});

SPEC_END
