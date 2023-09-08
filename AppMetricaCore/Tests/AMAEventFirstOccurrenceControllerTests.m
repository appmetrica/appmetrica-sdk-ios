
#import <Kiwi/Kiwi.h>
#import "AMAEventFirstOccurrenceController.h"
#import "AMAEventNameHashesCollection.h"
#import "AMAEventNameHashesStorage.h"
#import "AMAEventNameHashProvider.h"
#import "AMAMetricaConfigurationTestUtilities.h"

SPEC_BEGIN(AMAEventFirstOccurrenceControllerTests)

describe(@"AMAEventFirstOccurrenceController", ^{

    NSString *const eventName = @"EVENT_NAME";
    NSNumber *const eventNameHash = @42;

    AMAMetricaConfiguration *__block configuration = nil;
    AMAEventNameHashesCollection *__block collection = nil;
    AMAEventNameHashesStorage *__block storage = nil;
    AMAEventNameHashProvider *__block hashProvider = nil;
    AMAEventFirstOccurrenceController *__block controller = nil;

    beforeEach(^{
        [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];
        configuration = [AMAMetricaConfiguration sharedInstance];
        [configuration.inMemory stub:@selector(appVersion) andReturn:@"1.0.0"];
        [configuration.inMemory stub:@selector(appBuildNumber) andReturn:theValue(1)];
        collection = [[AMAEventNameHashesCollection alloc] initWithCurrentVersion:@"1.0.0_1"
                                                    hashesCountFromCurrentVersion:1
                                                         handleNewEventsAsUnknown:YES
                                                                  eventNameHashes:[NSMutableSet setWithObject:@23]];
        storage = [AMAEventNameHashesStorage nullMock];
        [storage stub:@selector(loadCollection) andReturn:collection];
        hashProvider = [AMAEventNameHashProvider nullMock];
        [hashProvider stub:@selector(hashForEventName:) andReturn:eventNameHash];
        controller = [[AMAEventFirstOccurrenceController alloc] initWithStorage:storage
                                                                   hashProvider:hashProvider
                                                            maxEventHashesCount:2];
    });

    context(@"Collection creation", ^{
        beforeEach(^{
            collection = nil;
            [storage stub:@selector(loadCollection) andReturn:nil];
            [storage stub:@selector(saveCollection:) withBlock:^id(NSArray *params) {
                collection = params[0];
                return nil;
            }];
        });
        it(@"Should have empty hashes", ^{
            [controller updateVersion];
            [[collection.eventNameHashes should] beEmpty];
        });
        it(@"Should have zero event name haches count", ^{
            [controller updateVersion];
            [[theValue(collection.hashesCountFromCurrentVersion) should] beZero];
        });
        it(@"Should have handleNewEventsAsUnknown", ^{
            [controller updateVersion];
            [[theValue(collection.handleNewEventsAsUnknown) should] beYes];
        });
        it(@"Should have valid version", ^{
            [controller updateVersion];
            [[collection.currentVersion should] equal:@"1.0.0_1"];
        });
    });

    context(@"Update version", ^{
        context(@"Save version", ^{
            it(@"Should load collection", ^{
                [[storage should] receive:@selector(loadCollection)];
                [controller updateVersion];
            });
            it(@"Should not change version", ^{
                [controller updateVersion];
                [[collection.currentVersion should] equal:@"1.0.0_1"];
            });
            it(@"Should not reset hashes count", ^{
                [controller updateVersion];
                [[theValue(collection.hashesCountFromCurrentVersion) should] equal:theValue(1)];
            });
            it(@"Should not remove hashes", ^{
                [controller updateVersion];
                [[collection.eventNameHashes should] contain:@23];
            });
            it(@"Should not reset handleNewEventsAsUnknown", ^{
                [controller updateVersion];
                [[theValue(collection.handleNewEventsAsUnknown) should] beYes];
            });
            it(@"Should not save collection", ^{
                [[storage shouldNot] receive:@selector(saveCollection:)];
                [controller updateVersion];
            });
        });
        context(@"Different version", ^{
            beforeEach(^{
                [configuration.inMemory stub:@selector(appVersion) andReturn:@"2.3.0"];
                [configuration.inMemory stub:@selector(appBuildNumber) andReturn:theValue(42)];
            });
            it(@"Should load collection", ^{
                [[storage should] receive:@selector(loadCollection)];
                [controller updateVersion];
            });
            it(@"Should set new version", ^{
                [controller updateVersion];
                [[collection.currentVersion should] equal:@"2.3.0_42"];
            });
            it(@"Should reset hashes count", ^{
                [controller updateVersion];
                [[theValue(collection.hashesCountFromCurrentVersion) should] beZero];
            });
            it(@"Should not remove hashes", ^{
                [controller updateVersion];
                [[collection.eventNameHashes should] contain:@23];
            });
            it(@"Should not reset handleNewEventsAsUnknown", ^{
                [controller updateVersion];
                [[theValue(collection.handleNewEventsAsUnknown) should] beYes];
            });
            it(@"Should save collection", ^{
                [[storage should] receive:@selector(saveCollection:) withArguments:collection];
                [controller updateVersion];
            });
        });
    });

    context(@"Occurrence", ^{
        beforeEach(^{
            collection.handleNewEventsAsUnknown = NO;
        });
        context(@"New event", ^{
            it(@"Should get hash", ^{
                [[hashProvider should] receive:@selector(hashForEventName:) withArguments:eventName];
                [controller isEventNameFirstOccurred:eventName];
            });
            it(@"Should return true", ^{
                [[theValue([controller isEventNameFirstOccurred:eventName]) should] equal:theValue(AMAOptionalBoolTrue)];
            });
            it(@"Should add hash", ^{
                [controller isEventNameFirstOccurred:eventName];
                [[collection.eventNameHashes should] contain:eventNameHash];
            });
            it(@"Should increase hashes count", ^{
                [controller isEventNameFirstOccurred:eventName];
                [[theValue(collection.hashesCountFromCurrentVersion) should] equal:theValue(2)];
            });
            it(@"Should not change handleNewEventsAsUnknown", ^{
                [controller isEventNameFirstOccurred:eventName];
                [[theValue(collection.handleNewEventsAsUnknown) should] beNo];
            });
            it(@"Should save collection", ^{
                [[storage should] receive:@selector(saveCollection:) withArguments:collection];
                [controller isEventNameFirstOccurred:eventName];
            });
        });
        context(@"Existing event", ^{
            beforeEach(^{
                [collection.eventNameHashes addObject:eventNameHash];
                ++collection.hashesCountFromCurrentVersion;
            });
            it(@"Should return false", ^{
                [[theValue([controller isEventNameFirstOccurred:eventName]) should] equal:theValue(AMAOptionalBoolFalse)];
            });
            it(@"Should add hash", ^{
                [controller isEventNameFirstOccurred:eventName];
                [[collection.eventNameHashes should] contain:eventNameHash];
            });
            it(@"Should not increase hashes count", ^{
                [controller isEventNameFirstOccurred:eventName];
                [[theValue(collection.hashesCountFromCurrentVersion) should] equal:theValue(2)];
            });
            it(@"Should not change handleNewEventsAsUnknown", ^{
                [controller isEventNameFirstOccurred:eventName];
                [[theValue(collection.handleNewEventsAsUnknown) should] beNo];
            });
            it(@"Should not save collection", ^{
                [[storage shouldNot] receive:@selector(saveCollection:)];
                [controller isEventNameFirstOccurred:eventName];
            });
        });
        context(@"First non-fitting event", ^{
            beforeEach(^{
                [collection.eventNameHashes addObjectsFromArray:@[ @32 ]];
                ++collection.hashesCountFromCurrentVersion;
            });
            it(@"Should return true", ^{
                [[theValue([controller isEventNameFirstOccurred:eventName]) should] equal:theValue(AMAOptionalBoolTrue)];
            });
            it(@"Should not add hash", ^{
                [controller isEventNameFirstOccurred:eventName];
                [[collection.eventNameHashes shouldNot] contain:eventNameHash];
            });
            it(@"Should not change hashes count", ^{
                [controller isEventNameFirstOccurred:eventName];
                [[theValue(collection.hashesCountFromCurrentVersion) should] equal:theValue(2)];
            });
            it(@"Should change handleNewEventsAsUnknown", ^{
                [controller isEventNameFirstOccurred:eventName];
                [[theValue(collection.handleNewEventsAsUnknown) should] beYes];
            });
            it(@"Should save collection", ^{
                [[storage should] receive:@selector(saveCollection:) withArguments:collection];
                [controller isEventNameFirstOccurred:eventName];
            });
        });
        context(@"Handle new events as unknown", ^{
            beforeEach(^{
                collection.handleNewEventsAsUnknown = YES;
            });
            it(@"Should return undefined", ^{
                [[theValue([controller isEventNameFirstOccurred:eventName]) should] equal:theValue(AMAOptionalBoolUndefined)];
            });
            it(@"Should add hash", ^{
                [controller isEventNameFirstOccurred:eventName];
                [[collection.eventNameHashes should] contain:eventNameHash];
            });
            it(@"Should change hashes count", ^{
                [controller isEventNameFirstOccurred:eventName];
                [[theValue(collection.hashesCountFromCurrentVersion) should] equal:theValue(2)];
            });
            it(@"Should not change handleNewEventsAsUnknown", ^{
                [controller isEventNameFirstOccurred:eventName];
                [[theValue(collection.handleNewEventsAsUnknown) should] beYes];
            });
            it(@"Should save collection", ^{
                [[storage should] receive:@selector(saveCollection:) withArguments:collection];
                [controller isEventNameFirstOccurred:eventName];
            });
        });
    });

    context(@"Reset", ^{
        it(@"Should remove hashes", ^{
            [controller resetHashes];
            [[collection.eventNameHashes should] beEmpty];
        });
        it(@"Should reset hashes count", ^{
            [controller resetHashes];
            [[theValue(collection.hashesCountFromCurrentVersion) should] beZero];
        });
        it(@"Should reset handleNewEventsAsUnknown", ^{
            [controller resetHashes];
            [[theValue(collection.handleNewEventsAsUnknown) should] beNo];
        });
        it(@"Should save collection", ^{
            [[storage should] receive:@selector(saveCollection:) withArguments:collection];
            [controller resetHashes];
        });
    });

});

SPEC_END
