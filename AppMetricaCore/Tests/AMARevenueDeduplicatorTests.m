
#import <Kiwi/Kiwi.h>
#import "AMAAttributionModelConfiguration.h"
#import "AMARevenueDeduplicator.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAMetricaConfiguration.h"

SPEC_BEGIN(AMARevenueDeduplicatorTests)

describe(@"AMARevenueDeduplicator", ^{

    AMAAttributionModelConfiguration *__block config = nil;
    AMARevenueDeduplicator *__block revenueDeduplicator = nil;
    AMAMetricaPersistentConfiguration *__block persistent = nil;

    beforeEach(^{
        config = [AMAAttributionModelConfiguration nullMock];
        AMAMetricaConfiguration *configuration = [AMAMetricaConfiguration nullMock];
        persistent = [AMAMetricaPersistentConfiguration nullMock];
        [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:configuration];
        [configuration stub:@selector(persistent) andReturn:persistent];
        revenueDeduplicator = [[AMARevenueDeduplicator alloc] initWithConfig:config];
    });
    afterEach(^{
        [AMAMetricaConfiguration clearStubs];
    });

    context(@"Read saved ids from disk", ^{
        beforeEach(^{
            [config stub:@selector(maxSavedRevenueIDs) andReturn:@100];
        });
        context(@"Nil", ^{
            beforeEach(^{
                [persistent stub:@selector(revenueTransactionIds) andReturn:nil];
            });
            it(@"Should ask only first time", ^{
                [[persistent should] receive:@selector(revenueTransactionIds)];
                [revenueDeduplicator checkForID:@"a"];
                [[persistent shouldNot] receive:@selector(revenueTransactionIds)];
                [revenueDeduplicator checkForID:@"b"];
            });
            it(@"Should update in-memory", ^{
                [[theValue([revenueDeduplicator checkForID:@"a"]) should] beYes];
                [[theValue([revenueDeduplicator checkForID:@"a"]) should] beNo];
            });
            it(@"Should update on disk", ^{
                [[persistent should] receive:@selector(setRevenueTransactionIds:) withArguments:@[ @"a" ]];
                [revenueDeduplicator checkForID:@"a"];
                [[persistent should] receive:@selector(setRevenueTransactionIds:) withArguments:@[ @"a", @"b" ]];
                [revenueDeduplicator checkForID:@"b"];
            });
        });
        context(@"Non-nil", ^{
            beforeEach(^{
                [persistent stub:@selector(revenueTransactionIds) andReturn:@[ @"c" ]];
            });
            it(@"Should ask only first time", ^{
                [[persistent should] receive:@selector(revenueTransactionIds)];
                [revenueDeduplicator checkForID:@"a"];
                [[persistent shouldNot] receive:@selector(revenueTransactionIds)];
                [revenueDeduplicator checkForID:@"b"];
            });
            it(@"Should update in-memory", ^{
                [[theValue([revenueDeduplicator checkForID:@"a"]) should] beYes];
                [[theValue([revenueDeduplicator checkForID:@"a"]) should] beNo];
            });
            it(@"Should update on disk", ^{
                [[persistent should] receive:@selector(setRevenueTransactionIds:) withArguments:@[ @"c", @"a" ]];
                [revenueDeduplicator checkForID:@"a"];
                [[persistent should] receive:@selector(setRevenueTransactionIds:) withArguments:@[ @"c", @"a", @"b" ]];
                [revenueDeduplicator checkForID:@"b"];
            });
        });
    });
    context(@"Check for ID", ^{
        context(@"Null identifier", ^{
            it(@"Should be YES", ^{
                [[theValue([revenueDeduplicator checkForID:nil]) should] beYes];
            });
            it(@"Should not read saved transaction ids", ^{
                [[persistent shouldNot] receive:@selector(revenueTransactionIds)];
                [revenueDeduplicator checkForID:nil];
            });
            it(@"Should not save transaction ids", ^{
                [[persistent shouldNot] receive:@selector(setRevenueTransactionIds:)];
                [revenueDeduplicator checkForID:nil];
            });
        });
        context(@"Empty identifier", ^{
            it(@"Should be YES", ^{
                [[theValue([revenueDeduplicator checkForID:@""]) should] beYes];
            });
            it(@"Should not read saved transaction ids", ^{
                [[persistent shouldNot] receive:@selector(revenueTransactionIds)];
                [revenueDeduplicator checkForID:@""];
            });
            it(@"Should not save transaction ids", ^{
                [[persistent shouldNot] receive:@selector(setRevenueTransactionIds:)];
                [revenueDeduplicator checkForID:@""];
            });
        });
        context(@"Non empty identifier", ^{
            NSString *identifier = @"id1";
            context(@"Saved ids is nil", ^{
                beforeEach(^{
                    [persistent stub:@selector(revenueTransactionIds) andReturn:nil];
                });
                it(@"Should be YES", ^{
                    [[theValue([revenueDeduplicator checkForID:identifier]) should] beYes];
                });
                it(@"Should not save if max value is 0", ^{
                    [config stub:@selector(maxSavedRevenueIDs) andReturn:@0];
                    [[persistent should] receive:@selector(setRevenueTransactionIds:) withArguments:@[]];
                    [revenueDeduplicator checkForID:identifier];
                });
                it(@"Should save if max value is 1", ^{
                    [config stub:@selector(maxSavedRevenueIDs) andReturn:@1];
                    [[persistent should] receive:@selector(setRevenueTransactionIds:) withArguments:@[ identifier ]];
                    [revenueDeduplicator checkForID:identifier];
                });
            });
            context(@"Saved ids is empty", ^{
                beforeEach(^{
                    [persistent stub:@selector(revenueTransactionIds) andReturn:@[]];
                });
                it(@"Should be YES", ^{
                    [[theValue([revenueDeduplicator checkForID:identifier]) should] beYes];
                });
                it(@"Should not save if max value is 0", ^{
                    [config stub:@selector(maxSavedRevenueIDs) andReturn:@0];
                    [[persistent should] receive:@selector(setRevenueTransactionIds:) withArguments:@[]];
                    [revenueDeduplicator checkForID:identifier];
                });
                it(@"Should save if max value is 1", ^{
                    [config stub:@selector(maxSavedRevenueIDs) andReturn:@1];
                    [[persistent should] receive:@selector(setRevenueTransactionIds:) withArguments:@[ identifier ]];
                    [revenueDeduplicator checkForID:identifier];
                });
            });
            context(@"Saved ids contains id", ^{
                beforeEach(^{
                    [persistent stub:@selector(revenueTransactionIds) andReturn:@[ @"id0", identifier, @"id2"]];
                });
                it(@"Should be NO", ^{
                    [[theValue([revenueDeduplicator checkForID:identifier]) should] beNo];
                });
                it(@"Should not save", ^{
                    [config stub:@selector(maxSavedRevenueIDs) andReturn:@100];
                    [[persistent shouldNot] receive:@selector(setRevenueTransactionIds:)];
                    [revenueDeduplicator checkForID:identifier];
                });
            });
            context(@"Saved ids does not contain id", ^{
                beforeEach(^{
                    [persistent stub:@selector(revenueTransactionIds) andReturn:@[ @"id0", @"id2"]];
                });
                it(@"Should be YES", ^{
                    [[theValue([revenueDeduplicator checkForID:identifier]) should] beYes];
                });
                it(@"Should save if max is 2", ^{
                    [config stub:@selector(maxSavedRevenueIDs) andReturn:@2];
                    [[persistent should] receive:@selector(setRevenueTransactionIds:) withArguments:@[ @"id2", identifier ]];
                    [revenueDeduplicator checkForID:identifier];
                });
                it(@"Should save if max is 3", ^{
                    [config stub:@selector(maxSavedRevenueIDs) andReturn:@3];
                    [[persistent should] receive:@selector(setRevenueTransactionIds:) withArguments:@[ @"id0", @"id2", identifier ]];
                    [revenueDeduplicator checkForID:identifier];
                });
            });
        });
    });
});

SPEC_END
