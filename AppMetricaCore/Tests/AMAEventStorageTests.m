
#import <Kiwi/Kiwi.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMAEventStorage.h"
#import "AMAEventSerializer.h"
#import "AMAMockDatabase.h"
#import "AMAEventNumbersFiller.h"
#import "AMAEvent.h"
#import "AMASession.h"
#import "AMADatabaseHelper.h"
#import "AMADatabaseConstants.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaFMDB/AppMetricaFMDB.h>

SPEC_BEGIN(AMAEventStorageTests)

describe(@"AMAEventStorage", ^{

    NSError *const expectedError = [NSError errorWithDomain:@"DOMAIN" code:23 userInfo:nil];
    NSDate *const date = [NSDate date];

    AMAEvent *__block event = nil;
    AMASession *__block session = nil;

    AMAMockDatabase *__block database = nil;
    AMAEventSerializer *__block eventSerializer = nil;
    AMAEventNumbersFiller *__block numberFiller = nil;
    AMAEventStorage *__block storage = nil;

    beforeEach(^{
        database = [AMAMockDatabase reporterDatabase];
        eventSerializer = [[AMAEventSerializer alloc] init];
        numberFiller = [[AMAEventNumbersFiller alloc] init];
        storage = [[AMAEventStorage alloc] initWithDatabase:database
                                            eventSerializer:eventSerializer
                                          eventNumberFiller:numberFiller];

        session = [[AMASession alloc] init];
        session.eventSeq = 23;
        [database inDatabase:^(AMAFMDatabase *db) {
            NSDictionary *sessionDictionary = @{
                kAMASessionTableFieldStartTime: @0,
                kAMACommonTableFieldType: @0,
                kAMASessionTableFieldFinished: @NO,
                kAMASessionTableFieldLastEventTime: @0,
                kAMASessionTableFieldPauseTime: @0,
                kAMASessionTableFieldEventSeq: @(session.eventSeq),
                kAMACommonTableFieldDataEncryptionType: @1,
                kAMACommonTableFieldData: [NSData data],
            };
            session.oid = [AMADatabaseHelper insertRowWithDictionary:sessionDictionary
                                                           tableName:kAMASessionTableName
                                                                  db:db
                                                               error:nil];
        }];

        event = [[AMAEvent alloc] init];
        event.createdAt = date;
        event.sessionOid = session.oid;
        event.type = AMAEventTypeAlive;
    });

    id (^fetchSessionField)(NSString *field) = ^(NSString *field) {
        id __block result = nil;
        [database inDatabase:^(AMAFMDatabase *db) {
            NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM sessions WHERE oid = 1 LIMIT 1", field];
            AMAFMResultSet *rs = [db executeQuery:query];
            if ([rs next] == NO) {
                fail(@"Session not found");
            }
            result = [rs objectForColumnIndex:0];
            [rs close];
        }];
        return result;
    };

    context(@"Add event", ^{
        context(@"Valid", ^{
            it(@"Should return true", ^{
                [[theValue([storage addEvent:event toSession:session error:nil]) should] beYes];
            });
            it(@"Should update session sequence number", ^{
                [storage addEvent:event toSession:session error:nil];
                [[fetchSessionField(kAMASessionTableFieldEventSeq) should] equal:@24];
            });
            it(@"Should update last event time", ^{
                [storage addEvent:event toSession:session error:nil];
                [[fetchSessionField(kAMASessionTableFieldLastEventTime) should] equal:@(date.timeIntervalSinceReferenceDate)];
            });
            context(@"In database", ^{
                NSDictionary *__block eventDictionary = nil;
                beforeEach(^{
                    [storage addEvent:event toSession:session error:nil];
                    [database inDatabase:^(AMAFMDatabase *db) {
                        AMAFMResultSet *rs = [db executeQuery:@"SELECT * FROM events LIMIT 1"];
                        if ([rs next] == NO) {
                            fail(@"No items in events table");
                        }
                        eventDictionary = rs.resultDictionary;
                        [rs close];
                    }];
                });
                it(@"Should have valid created at", ^{
                    NSNumber *expected = @(date.timeIntervalSinceReferenceDate);
                    [[eventDictionary[kAMAEventTableFieldCreatedAt] should] equal:expected];
                });
                it(@"Should have valid sequence number", ^{
                    [[eventDictionary[kAMAEventTableFieldSequenceNumber] should] equal:@23];
                });
                it(@"Should have valid type", ^{
                    [[eventDictionary[kAMACommonTableFieldType] should] equal:@(event.type)];
                });
                it(@"Should have non-empty data", ^{
                    [[eventDictionary[kAMACommonTableFieldData] shouldNot] beEmpty];
                });
            });
        });
        context(@"Error", ^{
            context(@"Numbers fill failure", ^{
                beforeEach(^{
                    [numberFiller stub:@selector(fillNumbersOfEvent:session:storage:rollback:error:) withBlock:^id(NSArray *params) {
                        AMARollbackHolder *rollbackHolder = params[3];
                        rollbackHolder.rollback = YES;
                        [AMATestUtilities fillObjectPointerParameter:params[4] withValue:expectedError];
                        return nil;
                    }];
                });
                it(@"Should return NO", ^{
                    [[theValue([storage addEvent:event toSession:session error:nil]) should] beNo];
                });
                it(@"Should fill error", ^{
                    NSError *error = nil;
                    [storage addEvent:event toSession:session error:&error];
                    [[error should] equal:expectedError];
                });
                it(@"Should not add event", ^{
                    [storage addEvent:event toSession:session error:nil];
                    [database inDatabase:^(AMAFMDatabase *db) {
                        AMAFMResultSet *rs = [db executeQuery:@"SELECT * FROM events LIMIT 1"];
                        [[theValue([rs next]) should] beNo];
                        [rs close];
                    }];
                });
                it(@"Should not update session sequence number", ^{
                    [storage addEvent:event toSession:session error:nil];
                    [[fetchSessionField(kAMASessionTableFieldEventSeq) should] equal:@23];
                });
            });
            context(@"Event serialization failure", ^{
                beforeEach(^{
                    [eventSerializer stub:@selector(dictionaryForEvent:error:) withBlock:^id(NSArray *params) {
                        [AMATestUtilities fillObjectPointerParameter:params[1] withValue:expectedError];
                        return nil;
                    }];
                });
                it(@"Should return NO", ^{
                    [[theValue([storage addEvent:event toSession:session error:nil]) should] beNo];
                });
                it(@"Should fill error", ^{
                    NSError *error = nil;
                    [storage addEvent:event toSession:session error:&error];
                    [[error should] equal:expectedError];
                });
                it(@"Should not add event", ^{
                    [storage addEvent:event toSession:session error:nil];
                    [database inDatabase:^(AMAFMDatabase *db) {
                        AMAFMResultSet *rs = [db executeQuery:@"SELECT * FROM events LIMIT 1"];
                        [[theValue([rs next]) should] beNo];
                        [rs close];
                    }];
                });
                it(@"Should not update session sequence number", ^{
                    [storage addEvent:event toSession:session error:nil];
                    [[fetchSessionField(kAMASessionTableFieldEventSeq) should] equal:@23];
                });
            });
            context(@"Event add failure", ^{
                beforeEach(^{
                    [AMADatabaseHelper stub:@selector(insertRowWithDictionary:tableName:db:error:) withBlock:^id(NSArray *params) {
                        [AMATestUtilities fillObjectPointerParameter:params[3] withValue:expectedError];
                        return nil;
                    }];
                });
                it(@"Should return NO", ^{
                    [[theValue([storage addEvent:event toSession:session error:nil]) should] beNo];
                });
                it(@"Should fill error", ^{
                    NSError *error = nil;
                    [storage addEvent:event toSession:session error:&error];
                    [[error should] equal:expectedError];
                });
                it(@"Should not add event", ^{
                    [storage addEvent:event toSession:session error:nil];
                    [database inDatabase:^(AMAFMDatabase *db) {
                        AMAFMResultSet *rs = [db executeQuery:@"SELECT * FROM events LIMIT 1"];
                        [[theValue([rs next]) should] beNo];
                        [rs close];
                    }];
                });
                it(@"Should not update session sequence number", ^{
                    [storage addEvent:event toSession:session error:nil];
                    [[fetchSessionField(kAMASessionTableFieldEventSeq) should] equal:@23];
                });
            });
            context(@"Session update failure", ^{
                beforeEach(^{
                    [AMADatabaseHelper stub:@selector(updateFieldsWithDictionary:keyField:key:tableName:db:error:)
                                  withBlock:^id(NSArray *params) {
                        [AMATestUtilities fillObjectPointerParameter:params[5] withValue:expectedError];
                        return nil;
                    }];
                });
                it(@"Should return NO", ^{
                    [[theValue([storage addEvent:event toSession:session error:nil]) should] beNo];
                });
                it(@"Should fill error", ^{
                    NSError *error = nil;
                    [storage addEvent:event toSession:session error:&error];
                    [[error should] equal:expectedError];
                });
                it(@"Should not add event", ^{
                    [storage addEvent:event toSession:session error:nil];
                    [database inDatabase:^(AMAFMDatabase *db) {
                        AMAFMResultSet *rs = [db executeQuery:@"SELECT * FROM events LIMIT 1"];
                        [[theValue([rs next]) should] beNo];
                        [rs close];
                    }];
                });
                it(@"Should not update session sequence number", ^{
                    [storage addEvent:event toSession:session error:nil];
                    [[fetchSessionField(kAMASessionTableFieldEventSeq) should] equal:@23];
                });
            });
        });
    });

    context(@"Total count", ^{
        NSArray *const specificTypes = @[ @(AMAEventTypeAlive), @(AMAEventTypeClient) ];
        context(@"Empty", ^{
            it(@"Should return 0 for all types", ^{
                [[theValue([storage totalCountOfEventsWithTypes:@[]]) should] beZero];
            });
            it(@"Should return 0 for specific types", ^{
                [[theValue([storage totalCountOfEventsWithTypes:specificTypes]) should] beZero];
            });
        });
        context(@"Non-empty", ^{
            beforeEach(^{
                event.type = AMAEventTypeAlive;
                [storage addEvent:event toSession:session error:nil];
                event.oid = nil;
                event.type = AMAEventTypeClient;
                [storage addEvent:event toSession:session error:nil];
            });
            it(@"Should return 2 for all types", ^{
                [[theValue([storage totalCountOfEventsWithTypes:@[]]) should] equal:theValue(2)];
            });
            it(@"Should return 2 for specific types", ^{
                [[theValue([storage totalCountOfEventsWithTypes:specificTypes]) should] equal:theValue(2)];
            });
            it(@"Should return 1 for partially matching types", ^{
                NSArray *types = @[ @(AMAEventTypeAlive), @(AMAEventTypeInit) ];
                [[theValue([storage totalCountOfEventsWithTypes:types]) should] equal:theValue(1)];
            });
            context(@"Error", ^{
                beforeEach(^{
                    [AMADatabaseHelper stub:@selector(countWhereField:inArray:andNotInArray:tableName:db:error:) withBlock:^id(NSArray *params) {
                        [AMATestUtilities fillObjectPointerParameter:params[5] withValue:expectedError];
                        return nil;
                    }];
                });
                it(@"Should return 0 for all types", ^{
                    [[theValue([storage totalCountOfEventsWithTypes:@[]]) should] beZero];
                });
                it(@"Should return 0 for specific types", ^{
                    [[theValue([storage totalCountOfEventsWithTypes:specificTypes]) should] beZero];
                });
            });
        });
    });
    context(@"All events", ^{
        AMAEventSerializer *__block mockedEventSerializer = nil;
        AMAEventNumbersFiller *__block mockedNumberFiller = nil;
        AMAEvent *__block firstEvent = nil;
        AMAEvent *__block secondEvent = nil;
        NSDictionary *firstDictionary = @{ @"aaa" : @"bbb "};
        NSDictionary *secondDictionary = @{ @"ccc" : @"ddd "};
        id __block mockedDatabase = nil;
        AMAFMDatabase *__block fmDatabase = nil;
        SEL dbHelperSelector = @selector(enumerateRowsWithFilter:order:valuesArray:tableName:limit:db:error:block:);
        beforeEach(^{
            fmDatabase = [AMAFMDatabase nullMock];
            firstEvent = [AMAEvent nullMock];
            secondEvent = [AMAEvent nullMock];
            mockedEventSerializer = [AMAEventSerializer nullMock];
            mockedNumberFiller = [AMAEventNumbersFiller nullMock];
            mockedDatabase = [KWMock nullMockForProtocol:@protocol(AMADatabaseProtocol)];
            [mockedDatabase stub:@selector(inDatabase:) withBlock:^id (NSArray *params) {
                void (^block)(AMAFMDatabase *) = params[0];
                block(fmDatabase);
                return nil;
            }];
            storage = [[AMAEventStorage alloc] initWithDatabase:mockedDatabase
                                                eventSerializer:mockedEventSerializer
                                              eventNumberFiller:mockedNumberFiller];
        });
        context(@"Has deserialization error", ^{
            it(@"Single element", ^{
                [mockedEventSerializer stub:@selector(eventForDictionary:error:) withBlock:^id (NSArray *params) {
                    NSDictionary *dict = params[0];
                    if ([dict isEqualToDictionary:firstDictionary]) {
                        [AMATestUtilities fillObjectPointerParameter:params[1]
                                                           withValue:[NSError errorWithDomain:NSURLErrorDomain
                                                                                         code:0
                                                                                     userInfo:@{}]];
                        return firstEvent;
                    }
                    return nil;
                }];
                [AMADatabaseHelper stub:dbHelperSelector withBlock:^id (NSArray *params) {
                    void (^block)(NSDictionary *) = params[7];
                    block(firstDictionary);
                    return nil;
                }];
                [[storage.allEvents should] equal:@[]];
            });
            it(@"Multiple elements", ^{
                [mockedEventSerializer stub:@selector(eventForDictionary:error:) withBlock:^id (NSArray *params) {
                    NSDictionary *dict = params[0];
                    if ([dict isEqualToDictionary:firstDictionary]) {
                        [AMATestUtilities fillObjectPointerParameter:params[1]
                                                           withValue:[NSError errorWithDomain:NSURLErrorDomain
                                                                                         code:0
                                                                                     userInfo:@{}]];
                        return firstEvent;
                    } else if ([dict isEqualToDictionary:secondDictionary]) {
                        return secondEvent;
                    }
                    return nil;
                }];
                [AMADatabaseHelper stub:dbHelperSelector withBlock:^id (NSArray *params) {
                    void (^block)(NSDictionary *) = params[7];
                    block(firstDictionary);
                    block(secondDictionary);
                    return nil;
                }];
                [[storage.allEvents should] equal:@[ secondEvent ]];
            });
        });
        context(@"Has error", ^{
            it(@"Single element", ^{
                [mockedEventSerializer stub:@selector(eventForDictionary:error:) andReturn:firstEvent withArguments:firstDictionary, kw_any()];
                [AMADatabaseHelper stub:dbHelperSelector withBlock:^id (NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[6]
                                                       withValue:[NSError errorWithDomain:NSURLErrorDomain
                                                                                     code:0
                                                                                 userInfo:@{}]];
                    void (^block)(NSDictionary *) = params[7];
                    block(firstDictionary);
                    return nil;
                }];
                [[storage.allEvents should] equal:@[ firstEvent ]];
            });
            it(@"Multiple elements", ^{
                [mockedEventSerializer stub:@selector(eventForDictionary:error:) andReturn:firstEvent withArguments:firstDictionary, kw_any()];
                [mockedEventSerializer stub:@selector(eventForDictionary:error:) andReturn:secondEvent withArguments:secondDictionary, kw_any()];
                [AMADatabaseHelper stub:dbHelperSelector withBlock:^id (NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[6]
                                                       withValue:[NSError errorWithDomain:NSURLErrorDomain
                                                                                     code:0
                                                                                 userInfo:@{}]];
                    void (^block)(NSDictionary *) = params[7];
                    block(firstDictionary);
                    block(secondDictionary);
                    return nil;
                }];
                [[storage.allEvents should] equal:@[ firstEvent, secondEvent ]];
            });
        });
        context(@"Event is nil", ^{
            it(@"Single element", ^{
                [mockedEventSerializer stub:@selector(eventForDictionary:error:) andReturn:nil withArguments:firstDictionary, kw_any()];
                [AMADatabaseHelper stub:dbHelperSelector withBlock:^id (NSArray *params) {
                    void (^block)(NSDictionary *) = params[7];
                    block(firstDictionary);
                    return nil;
                }];
                [[storage.allEvents should] equal:@[]];
            });
            it(@"Multiple elements", ^{
                [mockedEventSerializer stub:@selector(eventForDictionary:error:) andReturn:nil withArguments:firstDictionary, kw_any()];
                [mockedEventSerializer stub:@selector(eventForDictionary:error:) andReturn:secondEvent withArguments:secondDictionary, kw_any()];
                [AMADatabaseHelper stub:dbHelperSelector withBlock:^id (NSArray *params) {
                    void (^block)(NSDictionary *) = params[7];
                    block(firstDictionary);
                    block(secondDictionary);
                    return nil;
                }];
                [[storage.allEvents should] equal:@[ secondEvent ]];

            });
        });
        context(@"Success", ^{
            it(@"Multiple elements", ^{
                [mockedEventSerializer stub:@selector(eventForDictionary:error:) andReturn:firstEvent withArguments:firstDictionary, kw_any()];
                [mockedEventSerializer stub:@selector(eventForDictionary:error:) andReturn:secondEvent withArguments:secondDictionary, kw_any()];
                [AMADatabaseHelper stub:dbHelperSelector withBlock:^id (NSArray *params) {
                    void (^block)(NSDictionary *) = params[7];
                    block(firstDictionary);
                    block(secondDictionary);
                    return nil;
                }];
                [[storage.allEvents should] equal:@[ firstEvent, secondEvent ]];
            });
        });
    });

});

SPEC_END

