
#import <Kiwi/Kiwi.h>
#import "AMAStorageTrimManager.h"
#import "AMANotificationsListener.h"
#import "AMAReporterNotifications.h"
#import "AMADatabaseProtocol.h"
#import "AMAStorageEventsTrimTransaction.h"
#import "AMAEventsCountStorageTrimmer.h"
#import "AMAPlainStorageTrimmer.h"
#import "AMAEventsCleaner.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAStorageTrimManagerTests)

describe(@"AMAStorageTrimManager", ^{

    NSString *const apiKey = @"API_KEY";

    AMANotificationsListenerCallback __block callback = nil;
    NSObject<AMADatabaseProtocol> *__block database = nil;
    AMAStorageEventsTrimTransaction *__block transaction = nil;
    AMAEventsCleaner *__block eventsCleaner = nil;
    AMANotificationsListener *__block listener = nil;
    AMAStorageTrimManager *__block manager = nil;

    beforeEach(^{
        database = [KWMock nullMockForProtocol:@protocol(AMADatabaseProtocol)];
        transaction = [AMAStorageEventsTrimTransaction stubbedNullMockForInit:@selector(initWithCleaner:)];
        eventsCleaner = [AMAEventsCleaner nullMock];

        listener = [AMANotificationsListener nullMock];
        manager = [[AMAStorageTrimManager alloc] initWithApiKey:apiKey
                                                  eventsCleaner:eventsCleaner
                                          notificationsListener:listener];
    });

    it(@"Should unsubscribe database", ^{
        [[listener should] receive:@selector(unsubscribeObject:) withArguments:database];
        [manager unsubscribeDatabase:database];
    });

    context(@"Persistent DB", ^{
        AMAEventsCountStorageTrimmer *__block trimmer = nil;
        beforeEach(^{
            trimmer = [AMAEventsCountStorageTrimmer stubbedNullMockForInit:@selector(initWithApiKey:trimTransaction:)];
            [database stub:@selector(databaseType) andReturn:theValue(AMADatabaseTypePersistent)];
        });
        context(@"Subscribe", ^{
            it(@"Should create valid trimmer", ^{
                [[trimmer should] receive:@selector(initWithApiKey:trimTransaction:)
                            withArguments:apiKey, transaction];
                [manager subscribeDatabase:database];
            });
            it(@"Should create valid transaction", ^{
                [[transaction should] receive:@selector(initWithCleaner:) withArguments:eventsCleaner];
                [manager subscribeDatabase:database];
            });
            it(@"Should use valid notification", ^{
                [[listener should] receive:@selector(subscribeObject:toNotification:withCallback:)
                             withArguments:database, kAMAReporterDidAddEventNotification, kw_any()];
                [manager subscribeDatabase:database];
            });
            context(@"Subscribed", ^{
                beforeEach(^{
                    KWCaptureSpy *spy = [listener captureArgument:@selector(subscribeObject:toNotification:withCallback:)
                                                          atIndex:2];
                    [manager subscribeDatabase:database];
                    callback = spy.argument;
                });
                it(@"Should not be nil", ^{
                    [[theValue(callback) shouldNot] equal:theValue(nil)];
                });
                context(@"Nil notification", ^{
                    it(@"Should not handle event add", ^{
                        [[trimmer shouldNot] receive:@selector(handleEventAdding)];
                        callback(nil);
                    });
                    it(@"Should not trim database", ^{
                        [[trimmer shouldNot] receive:@selector(trimDatabase:)];
                        callback(nil);
                    });
                });
                context(@"Different apiKey notification", ^{
                    NSNotification *const notification =
                        [NSNotification notificationWithName:kAMAReporterDidAddEventNotification object:nil userInfo:@{
                            kAMAReporterDidAddEventNotificationUserInfoKeyApiKey: @"DIFFERENT",
                        }];
                    it(@"Should not handle event add", ^{
                        [[trimmer shouldNot] receive:@selector(handleEventAdding)];
                        callback(notification);
                    });
                    it(@"Should not trim database", ^{
                        [[trimmer shouldNot] receive:@selector(trimDatabase:)];
                        callback(notification);
                    });
                });
                context(@"Valid apiKey notification", ^{
                    NSNotification *const notification =
                        [NSNotification notificationWithName:kAMAReporterDidAddEventNotification object:nil userInfo:@{
                            kAMAReporterDidAddEventNotificationUserInfoKeyApiKey: apiKey,
                        }];
                    it(@"Should handle event add", ^{
                        [[trimmer should] receive:@selector(handleEventAdding)];
                        callback(notification);
                    });
                    it(@"Should trim database", ^{
                        [[trimmer should] receive:@selector(trimDatabase:) withArguments:database];
                        callback(notification);
                    });
                });
            });
        });
    });

    context(@"In memory DB", ^{
        AMAPlainStorageTrimmer *__block trimmer = nil;
        beforeEach(^{
            trimmer = [AMAPlainStorageTrimmer stubbedNullMockForInit:@selector(initWithTrimTransaction:)];
            [database stub:@selector(databaseType) andReturn:theValue(AMADatabaseTypeInMemory)];
        });
        context(@"Subscribe", ^{
            it(@"Should create valid trimmer", ^{
                [[trimmer should] receive:@selector(initWithTrimTransaction:)
                            withArguments:transaction];
                [manager subscribeDatabase:database];
            });
            it(@"Should create valid transaction", ^{
                [[transaction should] receive:@selector(initWithCleaner:) withArguments:eventsCleaner];
                [manager subscribeDatabase:database];
            });
            it(@"Should use valid notification", ^{
                [[listener should] receive:@selector(subscribeObject:toNotification:withCallback:)
                             withArguments:database, UIApplicationDidReceiveMemoryWarningNotification, kw_any()];
                [manager subscribeDatabase:database];
            });
            context(@"Subscribed", ^{
                beforeEach(^{
                    KWCaptureSpy *spy = [listener captureArgument:@selector(subscribeObject:toNotification:withCallback:)
                                                          atIndex:2];
                    [manager subscribeDatabase:database];
                    callback = spy.argument;
                });
                it(@"Should not be nil", ^{
                    [[theValue(callback) shouldNot] equal:theValue(nil)];
                });
                it(@"Should trim database", ^{
                    [[trimmer should] receive:@selector(trimDatabase:) withArguments:database];
                    callback(nil);
                });
            });
        });
        
        it(@"Should conform to AMAStorageTrimming", ^{
            [[trimmer should] conformToProtocol:@protocol(AMAStorageTrimming)];
        });
    });
});

SPEC_END
