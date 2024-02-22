
#import <Kiwi/Kiwi.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaProtobufUtils/AppMetricaProtobufUtils.h>
#import "AMAReporterStateStorage+Migration.h"
#import "AMAEnvironmentContainer.h"
#import "AMAMockDatabase.h"
#import "AMAModelSerialization.h"
#import "AMAExtrasContainer.h"
#import "AMAModelSerialization.h"

SPEC_BEGIN(AMAReporterStateStorageTests)

describe(@"AMAReporterStateStorage", ^{

    NSDate *const lastStateSendDate = [NSDate dateWithTimeIntervalSince1970:23];
    NSDate *const lastASATokenSendDate = [NSDate dateWithTimeIntervalSince1970:21];
    NSDate *const lastPrivacySendDate = [NSDate dateWithTimeIntervalSince1970:24];

    NSDate *__block now = nil;

    AMADateProviderMock *__block dateProvider = nil;
    AMAMockDatabase *__block database = nil;
    AMAEnvironmentContainer *__block eventEnvironment = nil;
    AMAReporterStateStorage *__block storage = nil;

    beforeEach(^{
        dateProvider = [[AMADateProviderMock alloc] init];
        now = [dateProvider freeze];
        database = [AMAMockDatabase reporterDatabase];
        eventEnvironment = [[AMAEnvironmentContainer alloc] init];
        storage = [[AMAReporterStateStorage alloc] initWithStorageProvider:database.storageProvider
                                                          eventEnvironment:eventEnvironment
                                                              dateProvider:dateProvider];
    });

    it(@"Should add necessary backup keys", ^{
        NSSet *__block actualKeys = nil;
        [((NSObject *)database.storageProvider) stub:@selector(addBackingKeys:) withBlock:^id(NSArray *params) {
            actualKeys = [NSSet setWithArray:params[0]];
            return nil;
        }];
        (void)[[AMAReporterStateStorage alloc] initWithStorageProvider:database.storageProvider
                                                      eventEnvironment:eventEnvironment
                                                          dateProvider:dateProvider];
        [[actualKeys should] equal:[NSSet setWithArray:@[
            @"session_first_event_sent",
            @"session_init_event_sent",
            @"session_update_event_sent",
            @"session_referrer_event_sent",
            @"session_referrer_is_empty",
            @"app_environment",
            @"profile_id",
            @"attribution.id",
            @"session.id",
            @"event.number.global",
            @"request.id",
            @"open.id",
            @"extras",
        ]]];
    });

    context(@"Restore", ^{
        context(@"Empty data", ^{
            beforeEach(^{
                [storage restoreState];
            });
            it(@"Should have valid first event sent", ^{
                [[theValue(storage.firstEventSent) should] beNo];
            });
            it(@"Should have valid init event sent", ^{
                [[theValue(storage.initEventSent) should] beNo];
            });
            it(@"Should have valid update event sent", ^{
                [[theValue(storage.updateEventSent) should] beNo];
            });
            it(@"Should have valid referrer event sent", ^{
                [[theValue(storage.referrerEventSent) should] beNo];
            });
            it(@"Should have valid empty referrer event sent", ^{
                [[theValue(storage.emptyReferrerEventSent) should] beNo];
            });
            it(@"Should have valid session ID", ^{
                NSNumber *number = [storage.sessionIDStorage valueWithStorage:database.storageProvider.syncStorage];
                [[number should] equal:@9999999999];
            });
            it(@"Should have valid request ID", ^{
                NSNumber *number = [storage.requestIDStorage valueWithStorage:database.storageProvider.syncStorage];
                [[number should] equal:@0];
            });
            it(@"Should have valid attribution ID", ^{
                NSNumber *number = [storage.attributionIDStorage valueWithStorage:database.storageProvider.syncStorage];
                [[number should] equal:@1];
            });
            it(@"Should have empty app environment", ^{
                [[storage.appEnvironment.dictionaryEnvironment should] beEmpty];
            });
            it(@"Should have empty error environment", ^{
                [[storage.eventEnvironment.dictionaryEnvironment should] beEmpty];
            });
            it(@"Should have no profile id", ^{
                [[storage.profileID should] beNil];
            });
            it(@"Should have valid last state send date", ^{
                [[storage.lastStateSendDate should] equal:[NSDate distantPast]];
            });
            it(@"Should have valid last ASA token send date", ^{
                [[storage.lastASATokenSendDate should] equal:[NSDate distantPast]];
            });
            it(@"Should have valid open id", ^{
                [[theValue(storage.openID) should] equal:theValue(1)];
            });
            it(@"Should have empty extras", ^{
                [[storage.extrasContainer.dictionaryExtras should] beEmpty];
            });
            it(@"Should have valid last privacy sent date", ^{
                [[storage.privacyLastSendDate should] equal:[NSDate distantPast]];
            });
        });
        context(@"Data exists", ^{
            NSNumber *const sessionID = @16;
            NSNumber *const attributionID = @23;
            NSNumber *const requestID = @42;
            NSDictionary *const appEnvironment = @{ @"appEnv": @"bar" };
            NSString *const profileID = @"PROFILE_ID";
            NSUInteger openID = 666777;
            
            NSDictionary<NSString *, NSData *> *extras = @{
                @"key1": [@"value1" dataUsingEncoding:NSUTF8StringEncoding],
                @"key2": [@"value2" dataUsingEncoding:NSUTF8StringEncoding],
            };
            
            NSData *__block extrasData = nil;
            [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
                Ama__Extras protoExtras;
                ama__extras__init(&protoExtras);
                
                [AMAModelSerialization fillExtrasData:&protoExtras
                                       withDictionary:extras
                                              tracker:tracker];
                
                size_t dataSize = ama__extras__get_packed_size(&protoExtras);
                uint8_t *dataBytes = malloc(dataSize);
                ama__extras__pack(&protoExtras, dataBytes);
                extrasData = [NSData dataWithBytesNoCopy:dataBytes length:dataSize];
            }];

            beforeEach(^{
                id<AMAKeyValueStoring> kvStorage = database.storageProvider.emptyNonPersistentStorage;

                [kvStorage saveBoolNumber:@YES forKey:@"session_first_event_sent" error:nil];
                [kvStorage saveBoolNumber:@YES forKey:@"session_init_event_sent" error:nil];
                [kvStorage saveBoolNumber:@YES forKey:@"session_update_event_sent" error:nil];
                [kvStorage saveBoolNumber:@YES forKey:@"session_referrer_event_sent" error:nil];
                [kvStorage saveBoolNumber:@YES forKey:@"session_referrer_is_empty" error:nil];

                [kvStorage saveLongLongNumber:sessionID forKey:@"session.id" error:nil];
                [kvStorage saveLongLongNumber:attributionID forKey:@"attribution.id" error:nil];
                [kvStorage saveLongLongNumber:requestID forKey:@"request.id" error:nil];
                [kvStorage saveLongLongNumber:@(openID) forKey:@"open.id" error:nil];

                [kvStorage saveJSONDictionary:appEnvironment forKey:@"app_environment" error:nil];
                [eventEnvironment addValue:@"bar" forKey:@"errEnv"];

                [kvStorage saveString:profileID forKey:@"profile_id" error:nil];

                [kvStorage saveDate:lastStateSendDate forKey:@"last_state_send_date" error:nil];
                [kvStorage saveDate:lastASATokenSendDate forKey:@"last_asa_token_send_date" error:NULL];
                [kvStorage saveDate:lastPrivacySendDate forKey:@"last_privacy_send_date" error:NULL];
                [kvStorage saveData:extrasData forKey:@"extras" error:nil];

                [database.storageProvider saveStorage:kvStorage error:nil];

                [storage restoreState];
            });
            it(@"Should have valid first event sent", ^{
                [[theValue(storage.firstEventSent) should] beYes];
            });
            it(@"Should have valid init event sent", ^{
                [[theValue(storage.initEventSent) should] beYes];
            });
            it(@"Should have valid update event sent", ^{
                [[theValue(storage.updateEventSent) should] beYes];
            });
            it(@"Should have valid referrer event sent", ^{
                [[theValue(storage.referrerEventSent) should] beYes];
            });
            it(@"Should have valid empty referrer event sent", ^{
                [[theValue(storage.emptyReferrerEventSent) should] beYes];
            });
            it(@"Should have valid session ID", ^{
                NSNumber *number = [storage.sessionIDStorage valueWithStorage:database.storageProvider.syncStorage];
                [[number should] equal:sessionID];
            });
            it(@"Should have valid request ID", ^{
                NSNumber *number = [storage.requestIDStorage valueWithStorage:database.storageProvider.syncStorage];
                [[number should] equal:requestID];
            });
            it(@"Should have valid attribution ID", ^{
                NSNumber *number = [storage.attributionIDStorage valueWithStorage:database.storageProvider.syncStorage];
                [[number should] equal:attributionID];
            });
            it(@"Should have valid app environment", ^{
                [[storage.appEnvironment.dictionaryEnvironment should] equal:appEnvironment];
            });
            it(@"Should have valid error environment", ^{
                [[storage.eventEnvironment.dictionaryEnvironment should] equal:@{ @"errEnv": @"bar" }];
            });
            it(@"Should have valid profile id", ^{
                [[storage.profileID should] equal:profileID];
            });
            it(@"Should have valid last state send date", ^{
                [[storage.lastStateSendDate should] equal:lastStateSendDate];
            });
            it(@"Should have valid last ASA token send date", ^{
                [[storage.lastASATokenSendDate should] equal:lastASATokenSendDate];
            });
            it(@"Should have valid open id", ^{
                [[theValue(storage.openID) should] equal:theValue(openID)];
            });
            it(@"Should have extras", ^{
                [[storage.extrasContainer.dictionaryExtras should] equal:extras];
            });
        });
    });

    context(@"Restored", ^{
        beforeEach(^{
            [storage restoreState];
        });
        context(@"Flags", ^{
            context(@"First", ^{
                it(@"Should initially be NO", ^{
                    [[theValue(storage.firstEventSent) should] beNo];
                });
                it(@"Should be YES after marked", ^{
                    [storage markFirstEventSent];
                    [[theValue(storage.firstEventSent) should] beYes];
                });
                it(@"Should be YES in database", ^{
                    [storage markFirstEventSent];
                    [[[database.storageProvider.syncStorage boolNumberForKey:@"session_first_event_sent" error:nil] should] equal:@YES];
                });
                it(@"Should not save twice", ^{
                    [storage markFirstEventSent];
                    [[(NSObject *)database.storageProvider.syncStorage shouldNot] receive:@selector(saveBoolNumber:forKey:error:)];
                    [storage markFirstEventSent];
                });
            });
            context(@"Init", ^{
                it(@"Should initially be NO", ^{
                    [[theValue(storage.initEventSent) should] beNo];
                });
                it(@"Should be YES after marked", ^{
                    [storage markInitEventSent];
                    [[theValue(storage.initEventSent) should] beYes];
                });
                it(@"Should be YES in database", ^{
                    [storage markInitEventSent];
                    [[[database.storageProvider.syncStorage boolNumberForKey:@"session_init_event_sent" error:nil] should] equal:@YES];
                });
                it(@"Should not save twice", ^{
                    [storage markInitEventSent];
                    [[(NSObject *)database.storageProvider.syncStorage shouldNot] receive:@selector(saveBoolNumber:forKey:error:)];
                    [storage markInitEventSent];
                });
            });
            context(@"Update", ^{
                it(@"Should initially be NO", ^{
                    [[theValue(storage.updateEventSent) should] beNo];
                });
                it(@"Should be YES after marked", ^{
                    [storage markUpdateEventSent];
                    [[theValue(storage.updateEventSent) should] beYes];
                });
                it(@"Should be YES in database", ^{
                    [storage markUpdateEventSent];
                    [[[database.storageProvider.syncStorage boolNumberForKey:@"session_update_event_sent" error:nil] should] equal:@YES];
                });
                it(@"Should not save twice", ^{
                    [storage markUpdateEventSent];
                    [[(NSObject *)database.storageProvider.syncStorage shouldNot] receive:@selector(saveBoolNumber:forKey:error:)];
                    [storage markUpdateEventSent];
                });
            });
            context(@"Referrer", ^{
                it(@"Should initially be NO", ^{
                    [[theValue(storage.referrerEventSent) should] beNo];
                });
                it(@"Should be YES after marked", ^{
                    [storage markReferrerEventSent];
                    [[theValue(storage.referrerEventSent) should] beYes];
                });
                it(@"Should be YES in database", ^{
                    [storage markReferrerEventSent];
                    [[[database.storageProvider.syncStorage boolNumberForKey:@"session_referrer_event_sent" error:nil] should] equal:@YES];
                });
                it(@"Should not save twice", ^{
                    [storage markReferrerEventSent];
                    [[(NSObject *)database.storageProvider.syncStorage shouldNot] receive:@selector(saveBoolNumber:forKey:error:)];
                    [storage markReferrerEventSent];
                });
            });
            context(@"Empty referrer", ^{
                it(@"Should initially be NO", ^{
                    [[theValue(storage.emptyReferrerEventSent) should] beNo];
                });
                it(@"Should be YES after marked", ^{
                    [storage markEmptyReferrerEventSent];
                    [[theValue(storage.emptyReferrerEventSent) should] beYes];
                });
                it(@"Should be YES in database", ^{
                    [storage markEmptyReferrerEventSent];
                    [[[database.storageProvider.syncStorage boolNumberForKey:@"session_referrer_is_empty" error:nil] should] equal:@YES];
                });
                it(@"Should not save twice", ^{
                    [storage markEmptyReferrerEventSent];
                    [[(NSObject *)database.storageProvider.syncStorage shouldNot] receive:@selector(saveBoolNumber:forKey:error:)];
                    [storage markEmptyReferrerEventSent];
                });
            });
        });
        context(@"App environment", ^{
            it(@"Should save in database", ^{
                [storage.appEnvironment addValue:@"bar" forKey:@"foo"];
                NSDictionary *appEnvironment =
                    [database.storageProvider.syncStorage jsonDictionaryForKey:@"app_environment" error:nil];
                [[appEnvironment should] equal:@{ @"foo": @"bar" }];
            });
        });
        context(@"Profile ID", ^{
            NSString *const profileID = @"PROFILE_ID";
            it(@"Should save in memory", ^{
                storage.profileID = profileID;
                [[storage.profileID should] equal:profileID];
            });
            it(@"Should save in database", ^{
                storage.profileID = profileID;
                [[[database.storageProvider.syncStorage stringForKey:@"profile_id" error:nil] should] equal:profileID];
            });
        });
        context(@"Last state send date", ^{
            it(@"Should save in memory", ^{
                [storage markStateSentNow];
                [[storage.lastStateSendDate should] equal:now];
            });
            it(@"Should save in database", ^{
                [storage markStateSentNow];
                [[[database.storageProvider.syncStorage dateForKey:@"last_state_send_date" error:nil] should] equal:now];
            });
        });
        context(@"Last ASA token send date", ^{
            it(@"Should save in memory", ^{
                [storage markASATokenSentNow];
                [[storage.lastASATokenSendDate should] equal:now];
            });
            it(@"Should save in database", ^{
                [storage markASATokenSentNow];
                [[[database.storageProvider.syncStorage dateForKey:@"last_asa_token_send_date" error:nil] should] equal:now];
            });
        });
        context(@"Privacy sent date", ^{
            it(@"Should save in memory", ^{
                [storage markASATokenSentNow];
                [[storage.lastASATokenSendDate should] equal:now];
            });
            it(@"Should save in database", ^{
                [storage markASATokenSentNow];
                [[[database.storageProvider.syncStorage dateForKey:@"last_asa_token_send_date" error:nil] should] equal:now];
            });
        });
        context(@"Extras", ^{
            it(@"Should save in database", ^{
                NSData *extra = [@"value" dataUsingEncoding:NSUTF8StringEncoding];
                
                [storage.extrasContainer addValue:extra forKey:@"key"];
                NSData *extrasData = [database.storageProvider.syncStorage dataForKey:@"extras" error:nil];
                
                NS_VALID_UNTIL_END_OF_SCOPE AMAProtobufAllocator *allocator = [[AMAProtobufAllocator alloc] init];
                Ama__Extras *protoExtras = ama__extras__unpack(allocator.protobufCAllocator, extrasData.length, extrasData.bytes);
                if (protoExtras == NULL) {
                    XCTAssert(false);
                    return;
                }

                NSDictionary<NSString *, NSData *> *protobufExtras = [AMAModelSerialization extrasFromProtobuf:protoExtras];
                
                [[protobufExtras should] equal:@{ @"key": extra}];
            });
        });
    });

    context(@"Migration", ^{
        beforeEach(^{
            [storage updateAppEnvironmentJSON:@"{\"foo\":\"bar\"}"];
            [storage updateLastStateSendDate:lastStateSendDate];
            [storage incrementOpenID];

            [storage restoreState];
        });
        context(@"App environment", ^{
            it(@"Should have valid value in memory", ^{
                [[storage.appEnvironment.dictionaryEnvironment should] equal:@{ @"foo": @"bar" }];
            });
            it(@"Should have valid value in database", ^{
                NSDictionary *appEnvironmentDictionary =
                    [database.storageProvider.syncStorage jsonDictionaryForKey:@"app_environment" error:nil];
                [[appEnvironmentDictionary should] equal:@{ @"foo": @"bar" }];
            });
        });
        context(@"Last state send date", ^{
            it(@"Should have valid value in memory", ^{
                [[storage.lastStateSendDate should] equal:lastStateSendDate];
            });
            it(@"Should have valid value in database", ^{
                [[[database.storageProvider.syncStorage dateForKey:@"last_state_send_date" error:nil] should] equal:lastStateSendDate];
            });
        });
    });

});

SPEC_END
