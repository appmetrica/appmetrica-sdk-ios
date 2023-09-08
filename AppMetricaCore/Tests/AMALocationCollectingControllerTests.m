
#import <CoreLocation/CoreLocation.h>
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMALocationCollectingController.h"
#import "AMALocationCollectingConfiguration.h"
#import "AMALocationStorage.h"
#import "AMALocationFilter.h"
#import "AMALocationDispatcher.h"
#import "AMALocation.h"
#import "AMAVisit.h"


SPEC_BEGIN(AMALocationCollectingControllerTests)

describe(@"AMALocationCollectingController", ^{

    NSDate *__block now = nil;
    CLLocation *__block location = nil;
#if TARGET_OS_IOS
    CLVisit *__block visit = nil;
#endif
    AMALocation *__block locationModel = nil;
    AMAVisit *__block visitModel = nil;

    AMALocationCollectingConfiguration *__block configuration = nil;
    AMALocationStorage *__block storage = nil;
    AMALocationFilter *__block filter = nil;
    AMALocationDispatcher *__block dispatcher = nil;
    NSObject<AMACancelableExecuting> *__block executor = nil;
    AMADateProviderMock *__block dateProvider = nil;
    AMALocationCollectingController *__block controller = nil;

    beforeEach(^{
        now = [NSDate date];
        location = [CLLocation nullMock];
#if TARGET_OS_IOS
        visit = [CLVisit nullMock];
#endif
        locationModel = [AMALocation stubbedNullMockForInit:@selector(initWithIdentifier:collectDate:location:provider:)];
        visitModel = [AMAVisit stubbedNullMockForInit:@selector(initWithIdentifier:
                                                                collectDate:
                                                                arrivalDate:
                                                                departureDate:
                                                                latitude:
                                                                longitude:
                                                                precision:)];

        configuration = [AMALocationCollectingConfiguration nullMock];
        [configuration stub:@selector(collectingEnabled) andReturn:theValue(YES)];
        [configuration stub:@selector(visitsCollectingEnabled) andReturn:theValue(YES)];
        storage = [AMALocationStorage nullMock];
        filter = [AMALocationFilter nullMock];
        [filter stub:@selector(shouldAddLocation:atDate:) andReturn:theValue(YES)];
        dispatcher = [AMALocationDispatcher nullMock];
        executor = [[AMACurrentQueueExecutor alloc] init];
        dateProvider = [[AMADateProviderMock alloc] init];
        [dateProvider freezeWithDate:now];
        controller = [[AMALocationCollectingController alloc] initWithConfiguration:configuration
                                                                            storage:storage
                                                                             filter:filter
                                                                         dispatcher:dispatcher
                                                                           executor:executor
                                                                       dateProvider:dateProvider];
    });

    context(@"Successful", ^{
        context(@"Locations", ^{
            it(@"Should filter location", ^{
                [[filter should] receive:@selector(shouldAddLocation:atDate:) withArguments:location, now];
                [controller addSystemLocations:@[ location ]];
            });
            it(@"Should update filter", ^{
                [[filter should] receive:@selector(updateLastLocation:atDate:) withArguments:location, now];
                [controller addSystemLocations:@[ location ]];
            });
            it(@"Should add location to storage", ^{
                [[storage should] receive:@selector(addLocations:) withArguments:@[ locationModel ]];
                [controller addSystemLocations:@[ location ]];
            });
            it(@"Should trigger locations dispatching", ^{
                [[dispatcher should] receive:@selector(handleLocationAdd)];
                [controller addSystemLocations:@[ location ]];
            });
        });
#if TARGET_OS_IOS
        context(@"Visits", ^{
            it(@"Should have nil arrival date if CLVisit does not include arrival information", ^{
                [visit stub:@selector(arrivalDate) andReturn:NSDate.distantPast];
                KWCaptureSpy *spy = [visitModel captureArgument:@selector(initWithIdentifier:
                                                                          collectDate:
                                                                          arrivalDate:
                                                                          departureDate:
                                                                          latitude:
                                                                          longitude:
                                                                          precision:) atIndex:2];
                [controller addVisit:visit];
                [[spy.argument should] beNil];
            });
            it(@"Should have nil arrival date if CLVisit does not include departure information", ^{
                [visit stub:@selector(departureDate) andReturn:NSDate.distantFuture];
                KWCaptureSpy *spy = [visitModel captureArgument:@selector(initWithIdentifier:
                                                                          collectDate:
                                                                          arrivalDate:
                                                                          departureDate:
                                                                          latitude:
                                                                          longitude:
                                                                          precision:) atIndex:3];
                [controller addVisit:visit];
                [[spy.argument should] beNil];
            });
            context(@"Enabled", ^{
                it(@"Should add visit to storage", ^{
                    [[storage should] receive:@selector(addVisit:) withArguments:visitModel];
                    [controller addVisit:visit];
                });
                it(@"Should trigger visit dispatching", ^{
                    [[dispatcher should] receive:@selector(handleVisitAdd)];
                    [controller addVisit:visit];
                });
            });
            context(@"Disabled", ^{
                beforeEach(^{
                    [configuration stub:@selector(visitsCollectingEnabled) andReturn:theValue(NO)];
                });
                it(@"Should not add visit to storage", ^{
                    [[storage shouldNot] receive:@selector(addVisit:) withArguments:visitModel];
                    [controller addVisit:visit];
                });
                it(@"Should not trigger visit dispatching", ^{
                    [[dispatcher shouldNot] receive:@selector(handleVisitAdd)];
                    [controller addVisit:visit];
                });
            });
        });
#endif
    });

    context(@"Disabled", ^{
        beforeEach(^{
            [configuration stub:@selector(collectingEnabled) andReturn:theValue(NO)];
        });
        it(@"Should not filter location", ^{
            [[filter shouldNot] receive:@selector(shouldAddLocation:atDate:)];
            [controller addSystemLocations:@[ location ]];
        });
        it(@"Should not update filter", ^{
            [[filter shouldNot] receive:@selector(updateLastLocation:atDate:)];
            [controller addSystemLocations:@[ location ]];
        });
        it(@"Should not add location to storage", ^{
            [[storage shouldNot] receive:@selector(addLocations:)];
            [controller addSystemLocations:@[ location ]];
        });
        it(@"Should not trigger locations dispatching", ^{
            [[dispatcher shouldNot] receive:@selector(handleLocationAdd)];
            [controller addSystemLocations:@[ location ]];
        });
#if TARGET_OS_IOS
        context(@"Visits", ^{
            it(@"Should add visit to storage", ^{
                [[storage should] receive:@selector(addVisit:) withArguments:visitModel];
                [controller addVisit:visit];
            });
            it(@"Should trigger visit dispatching", ^{
                [[dispatcher should] receive:@selector(handleVisitAdd)];
                [controller addVisit:visit];
            });
        });
#endif
    });

    context(@"Filtered", ^{
        beforeEach(^{
            [filter stub:@selector(shouldAddLocation:atDate:) andReturn:theValue(NO)];
        });
        it(@"Should not update filter", ^{
            [[filter shouldNot] receive:@selector(updateLastLocation:atDate:)];
            [controller addSystemLocations:@[ location ]];
        });
        it(@"Should not add location to storage", ^{
            [[storage shouldNot] receive:@selector(addLocations:)];
            [controller addSystemLocations:@[ location ]];
        });
        it(@"Should not trigger locations dispatching", ^{
            [[dispatcher shouldNot] receive:@selector(handleLocationAdd)];
            [controller addSystemLocations:@[ location ]];
        });
    });

});

SPEC_END

