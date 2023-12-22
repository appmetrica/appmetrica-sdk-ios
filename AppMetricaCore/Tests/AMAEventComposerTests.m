
#import <Foundation/Foundation.h>
#import <Kiwi/Kiwi.h>
#import "AMAEventComposerBuilder.h"
#import "AMAEventComposer.h"
#import "AMAProfileIdComposer.h"
#import "AMALocationComposer.h"
#import "AMALocationEnabledComposer.h"
#import "AMAAppEnvironmentComposer.h"
#import "AMAEventEnvironmentComposer.h"
#import "AMAEvent+Private.h"
#import <CoreLocation/CoreLocation.h>
#import "AMAOpenIDComposer.h"

SPEC_BEGIN(AMAEventComposerTests)

describe(@"AMAEventComposer", ^{
    context(@"Compose", ^{
        AMAEventComposerBuilder *__block builder = nil;
        AMAEventComposer *__block composer = nil;
        id __block profileIdComposer = nil;
        id __block locationComposer = nil;
        id __block locationEnabledComposer = nil;
        id __block appEnvironmentComposer = nil;
        id __block eventEnvironmentComposer = nil;
        id __block openIDComposer = nil;

        NSString *__block profileId = @"profile_id";
        CLLocation *__block location = [[CLLocation alloc] initWithLatitude:2.0 longitude:1.2];
        AMAOptionalBool __block locationEnabled = AMAOptionalBoolTrue;
        NSDictionary *appEnvironment = @{ @"key1" : @"value1", @"key2" : @"value2" };
        NSDictionary *eventEnvironment = @{ @"key3" : @"value3", @"key4" : @"value4" };
        NSUInteger openID = 777888;

        beforeEach(^{
            builder = [AMAEventComposerBuilder nullMock];
            profileIdComposer = [KWMock nullMockForProtocol:@protocol(AMAProfileIdComposer)];
            [[profileIdComposer should] conformToProtocol:@protocol(AMAProfileIdComposer)];
            locationComposer = [KWMock nullMockForProtocol:@protocol(AMALocationComposer)];
            [[locationComposer should] conformToProtocol:@protocol(AMALocationComposer)];
            locationEnabledComposer = [KWMock nullMockForProtocol:@protocol(AMALocationEnabledComposer)];
            [[locationEnabledComposer should] conformToProtocol:@protocol(AMALocationEnabledComposer)];
            appEnvironmentComposer = [KWMock nullMockForProtocol:@protocol(AMAAppEnvironmentComposer)];
            [[appEnvironmentComposer should] conformToProtocol:@protocol(AMAAppEnvironmentComposer)];
            eventEnvironmentComposer = [KWMock nullMockForProtocol:@protocol(AMAEventEnvironmentComposer)];
            [[eventEnvironmentComposer should] conformToProtocol:@protocol(AMAEventEnvironmentComposer)];
            openIDComposer = [KWMock nullMockForProtocol:@protocol(AMAOpenIDComposer)];
            [[openIDComposer should] conformToProtocol:@protocol(AMAOpenIDComposer)];

            [builder stub:@selector(profileIdComposer) andReturn:profileIdComposer];
            [builder stub:@selector(locationComposer) andReturn:locationComposer];
            [builder stub:@selector(locationEnabledComposer) andReturn:locationEnabledComposer];
            [builder stub:@selector(appEnvironmentComposer) andReturn:appEnvironmentComposer];
            [builder stub:@selector(eventEnvironmentComposer) andReturn:eventEnvironmentComposer];
            [builder stub:@selector(openIDComposer) andReturn:openIDComposer];

            [profileIdComposer stub:@selector(compose) andReturn:profileId];
            [locationComposer stub:@selector(compose) andReturn:location];
            [locationEnabledComposer stub:@selector(compose) andReturn:theValue(locationEnabled)];
            [appEnvironmentComposer stub:@selector(compose) andReturn:appEnvironment];
            [eventEnvironmentComposer stub:@selector(compose) andReturn:eventEnvironment];
            [openIDComposer stub:@selector(compose) andReturn:theValue(openID)];

            composer = [[AMAEventComposer alloc] initWithBuilder:builder];
        });
        it(@"Should use all composers", ^{
            AMAEvent *event = [[AMAEvent alloc] init];

            [[profileIdComposer should] receive:@selector(compose)];
            [[locationComposer should] receive:@selector(compose)];
            [[locationEnabledComposer should] receive:@selector(compose)];
            [[appEnvironmentComposer should] receive:@selector(compose)];
            [[eventEnvironmentComposer should] receive:@selector(compose)];
            [[openIDComposer should] receive:@selector(compose)];

            [composer compose:event];

            [[event.profileID should] equal:profileId];
            double doubleDelta = 0.00000000001;
            [[theValue(event.location.coordinate.longitude) should] equal:location.coordinate.longitude withDelta:doubleDelta];
            [[theValue(event.location.coordinate.longitude) should] equal:location.coordinate.longitude withDelta:doubleDelta];
            [[theValue(event.locationEnabled) should] equal:theValue(locationEnabled)];
            [[event.appEnvironment should] equal:appEnvironment];
            [[event.eventEnvironment should] equal:eventEnvironment];
            [[theValue(event.openID.unsignedLongValue) should] equal:theValue(openID)];
        });
    });
});

SPEC_END
