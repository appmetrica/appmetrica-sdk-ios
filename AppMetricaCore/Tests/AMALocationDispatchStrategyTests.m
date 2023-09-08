
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMALocationDispatchStrategy.h"
#import "AMALocationStorage.h"
#import "AMALocationCollectingConfiguration.h"
#import "AMAStatisticsRestrictionController.h"

SPEC_BEGIN(AMALocationDispatchStrategyTests)

describe(@"AMALocationDispatchStrategy", ^{

    NSUInteger const maxCount = 10;
    NSTimeInterval const maxAge = 10.0;

    NSDate *__block now = nil;
    AMAStatisticsRestrictionController *__block restrictionController = nil;
    AMALocationStorage *__block storage = nil;
    NSObject<AMALSSLocationsProviding> *__block storageState = nil;
    AMALocationCollectingConfiguration *__block configuration = nil;
    AMADateProviderMock *__block dateProvider = nil;
    AMALocationDispatchStrategy *__block strategy = nil;

    beforeEach(^{
        restrictionController = [AMAStatisticsRestrictionController nullMock];
        [restrictionController stub:@selector(shouldEnableLocationSending) andReturn:theValue(YES)];
        [AMAStatisticsRestrictionController stub:@selector(sharedInstance) andReturn:restrictionController];
        storageState = [KWMock nullMockForProtocol:@protocol(AMALSSLocationsProviding)];
        storage = [AMALocationStorage nullMock];
        [storage stub:@selector(locationStorageState) andReturn:storageState];
        configuration = [AMALocationCollectingConfiguration nullMock];
        [configuration stub:@selector(recordsCountToForceFlush) andReturn:theValue(maxCount)];
        [configuration stub:@selector(maxAgeToForceFlush) andReturn:theValue(maxAge)];
        dateProvider = [[AMADateProviderMock alloc] init];
        now = [dateProvider freeze];
        strategy = [[AMALocationDispatchStrategy alloc] initWithStorage:storage
                                                          configuration:configuration
                                                           dateProvider:dateProvider];
    });

    context(@"Before limits", ^{
        beforeEach(^{
            [storageState stub:@selector(locationsCount) andReturn:theValue(maxCount - 1)];
            [storageState stub:@selector(firstLocationDate) andReturn:[now dateByAddingTimeInterval:-(maxAge - 1.0)]];
        });
        it(@"Should return NO", ^{
            [[theValue([strategy shouldSendLocation]) should] beNo];
        });
    });
    context(@"After count limit", ^{
        beforeEach(^{
            [storageState stub:@selector(locationsCount) andReturn:theValue(maxCount)];
            [storageState stub:@selector(firstLocationDate) andReturn:[now dateByAddingTimeInterval:-(maxAge - 1.0)]];
        });
        it(@"Should return YES", ^{
            [[theValue([strategy shouldSendLocation]) should] beYes];
        });
    });
    context(@"After age limit", ^{
        beforeEach(^{
            [storageState stub:@selector(locationsCount) andReturn:theValue(maxCount - 1)];
            [storageState stub:@selector(firstLocationDate) andReturn:[now dateByAddingTimeInterval:-(maxAge + 0.1)]];
        });
        it(@"Should return YES", ^{
            [[theValue([strategy shouldSendLocation]) should] beYes];
        });
    });
    context(@"After all limits", ^{
        beforeEach(^{
            [storageState stub:@selector(firstLocationDate) andReturn:[now dateByAddingTimeInterval:-(maxAge + 0.1)]];
        });
        it(@"Should return YES", ^{
            [[theValue([strategy shouldSendLocation]) should] beYes];
        });
        context(@"After failed request", ^{
            beforeEach(^{
                [strategy handleRequestFailure];
            });
            context(@"Locations", ^{
                
                beforeEach(^{
                    [storageState stub:@selector(locationsCount) andReturn:theValue(maxCount)];
                });
                
                it(@"Should return NO immediately", ^{
                    [[theValue([strategy shouldSendLocation]) should] beNo];
                });
                it(@"Should return NO before timout", ^{
                    [dateProvider freezeWithDate:[now dateByAddingTimeInterval:9.0]];
                    [[theValue([strategy shouldSendLocation]) should] beNo];
                });
                it(@"Should return YES after timout", ^{
                    [dateProvider freezeWithDate:[now dateByAddingTimeInterval:11.0]];
                    [[theValue([strategy shouldSendLocation]) should] beYes];
                });
            });
            context(@"Visits", ^{
                
                beforeEach(^{
                    [storageState stub:@selector(visitsCount) andReturn:@10];
                });
                
                it(@"Should return NO immediately", ^{
                    [[theValue([strategy shouldSendVisit]) should] beNo];
                });
                it(@"Should return NO before timout", ^{
                    [dateProvider freezeWithDate:[now dateByAddingTimeInterval:9.0]];
                    [[theValue([strategy shouldSendVisit]) should] beNo];
                });
                it(@"Should return YES after timout", ^{
                    [dateProvider freezeWithDate:[now dateByAddingTimeInterval:11.0]];
                    [[theValue([strategy shouldSendVisit]) should] beYes];
                });
            });
        });
        it(@"Should send visits visits available", ^{
            [storageState stub:@selector(visitsCount) andReturn:@10];
            [[theValue([strategy shouldSendVisit]) should] beYes];
        });
        it(@"Should not send visits visits available", ^{
            [storageState stub:@selector(visitsCount) andReturn:0];
            [[theValue([strategy shouldSendVisit]) should] beNo];
        });
    });

    context(@"Restricted", ^{
        beforeEach(^{
            [restrictionController stub:@selector(shouldEnableLocationSending) andReturn:theValue(NO)];
        });
        context(@"Location", ^{
            context(@"Before limits", ^{
                beforeEach(^{
                    [storageState stub:@selector(locationsCount) andReturn:theValue(maxCount - 1)];
                    [storageState stub:@selector(firstLocationDate) andReturn:[now dateByAddingTimeInterval:-(maxAge - 1.0)]];
                });
                it(@"Should return NO", ^{
                    [[theValue([strategy shouldSendLocation]) should] beNo];
                });
            });
            context(@"After all limits", ^{
                beforeEach(^{
                    [storageState stub:@selector(locationsCount) andReturn:theValue(maxCount)];
                    [storageState stub:@selector(firstLocationDate) andReturn:[now dateByAddingTimeInterval:-(maxAge + 0.1)]];
                });
                it(@"Should return NO", ^{
                    [[theValue([strategy shouldSendLocation]) should] beNo];
                });
            });
        });
        context(@"Visits", ^{
            it(@"Should return NO if no visits are available", ^{
                [storageState stub:@selector(visitsCount) andReturn:@0];
                [[theValue([strategy shouldSendVisit]) should] beNo];
            });
            it(@"Should return NO if visits available", ^{
                [storageState stub:@selector(visitsCount) andReturn:@10];
                [[theValue([strategy shouldSendVisit]) should] beNo];
            });
        });
    });

});

SPEC_END

