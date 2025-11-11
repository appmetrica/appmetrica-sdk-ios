
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAFilledAppEnvironmentComposer.h"
#import "AMAFilledEventEnvironmentComposer.h"
#import "AMAFilledLocationComposer.h"
#import "AMAReporterStateStorage+Migration.h"
#import "AMAEnvironmentContainer.h"
#import "AMALocationManager.h"
#import "AMAFilledLocationEnabledComposer.h"
#import "AMAFilledProfileIdComposer.h"
#import "AMAFilledExtrasComposer.h"
#import "AMAExtrasContainer.h"

SPEC_BEGIN(AMAFilledComposersTests)

describe(@"AMAFilledComposers", ^{
    context(@"Compose", ^{
        context(@"Environment", ^{
            AMAReporterStateStorage *__block storage = nil;
            AMAEnvironmentContainer *__block environmentContainer = nil;
            NSDictionary *filledEnvironment = @{ @"key1": @"value1", @"key2": @"value2" };
            NSDictionary *emptyEnvironment = @{};
            beforeEach(^{
                storage = [AMAReporterStateStorage nullMock];
                environmentContainer = [AMAEnvironmentContainer nullMock];
            });
            context(@"AppEnvironment", ^{
                AMAFilledAppEnvironmentComposer *__block composer = nil;
                beforeEach(^{
                    [storage stub:@selector(appEnvironment) andReturn:environmentContainer];
                    composer = [[AMAFilledAppEnvironmentComposer alloc] initWithStorage:storage];
                });

                it(@"Should return nil if empty", ^{
                    [environmentContainer stub:@selector(dictionaryEnvironment) andReturn:emptyEnvironment];
                    [[[composer compose] should] beNil];
                });
                it(@"Should return filled environment if not empty", ^{
                    [environmentContainer stub:@selector(dictionaryEnvironment) andReturn:filledEnvironment];
                    [[[composer compose] should] equal:filledEnvironment];
                });
            });
            context(@"EventEnvironment", ^{
                AMAFilledEventEnvironmentComposer *__block composer = nil;
                beforeEach(^{
                    [storage stub:@selector(eventEnvironment) andReturn:environmentContainer];
                    composer = [[AMAFilledEventEnvironmentComposer alloc] initWithStorage:storage];
                });
                it(@"Should return nil if empty", ^{
                    [environmentContainer stub:@selector(dictionaryEnvironment) andReturn:emptyEnvironment];
                    [[[composer compose] should] beNil];
                });
                it(@"Should return filled environment if not empty", ^{
                    [environmentContainer stub:@selector(dictionaryEnvironment) andReturn:filledEnvironment];
                    [[[composer compose] should] equal:filledEnvironment];
                });
            });
        });
        context(@"Extras", ^{
            AMAReporterStateStorage *__block storage = nil;
            AMAFilledExtrasComposer *__block composer = nil;
            NSDictionary<NSString *, NSData *> *dict = @{
                    @"key1": [@"value1" dataUsingEncoding:NSUTF8StringEncoding],
                    @"key2": [@"value2" dataUsingEncoding:NSUTF8StringEncoding],
            };
            NSDictionary *emptyExtras = @{};
            AMAExtrasContainer *extrasContainer = [[AMAExtrasContainer alloc] initWithDictionaryExtras:dict];
            beforeEach(^{
                storage = [AMAReporterStateStorage nullMock];
                [storage stub:@selector(extrasContainer) andReturn:extrasContainer];
                composer = [[AMAFilledExtrasComposer alloc] initWithStorage:storage];
            });
            it(@"Should return empty if empty", ^{
                [extrasContainer stub:@selector(dictionaryExtras) andReturn:emptyExtras];
                [[[composer compose] should] equal:emptyExtras];
            });
            it(@"Should return filled environment if not empty", ^{
                [extrasContainer stub:@selector(dictionaryExtras) andReturn:dict];
                [[[composer compose] should] equal:dict];
            });
        });
        context(@"Location info", ^{

            AMALocationManager *__block locationManager = nil;
            beforeEach(^{
                locationManager = [AMALocationManager nullMock];
            });

            context(@"Location itself", ^{
                AMAFilledLocationComposer *__block composer = nil;
                beforeEach(^{
                    composer = [[AMAFilledLocationComposer alloc] initWithLocationManager:locationManager];
                });
                it(@"Should return nil", ^{
                    [locationManager stub:@selector(currentLocation) andReturn:nil];
                    [[[composer compose] should] beNil];
                });
                it(@"Should return filled location", ^{
                    CLLocation *location = [[CLLocation alloc] initWithLatitude:76.9897897 longitude:23.09090];
                    [locationManager stub:@selector(currentLocation) andReturn:location];
                    CLLocation *actualLocation = [composer compose];
                    double doubleDelta = 0.000000001;
                    [[theValue(actualLocation.coordinate.latitude) should] equal:location.coordinate.latitude
                                                                       withDelta:doubleDelta];
                    [[theValue(actualLocation.coordinate.longitude) should] equal:location.coordinate.longitude
                                                                        withDelta:doubleDelta];
                });
            });
            context(@"LocationEnabled", ^{
                AMAFilledLocationEnabledComposer *__block composer = nil;
                beforeEach(^{
                    composer = [[AMAFilledLocationEnabledComposer alloc] initWithLocationManager:locationManager];
                });

                it(@"Should return true", ^{
                    [locationManager stub:@selector(trackLocationEnabled) andReturn:theValue(AMAOptionalBoolTrue)];
                    [[theValue([composer compose]) should] equal:theValue(AMAOptionalBoolTrue)];
                });
            });

        });
        context(@"Profile id", ^{
            AMAFilledProfileIdComposer *__block composer = nil;
            AMAReporterStateStorage *__block storage = nil;

            beforeEach(^{
                storage = [AMAReporterStateStorage nullMock];
                composer = [[AMAFilledProfileIdComposer alloc] initWithStorage:storage];
            });

            it(@"Should return nil", ^{
                [storage stub:@selector(profileID) andReturn:nil];
                [[[composer compose] should] beNil];
            });
            it(@"Should return non-nil value", ^{
                NSString *profileId = @"894876786";
                [storage stub:@selector(profileID) andReturn:profileId];
                [[[composer compose] should] equal:profileId];
            });
        });
    });
});

SPEC_END
