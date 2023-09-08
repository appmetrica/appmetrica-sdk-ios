
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAEventsCleanupInfo.h"
#import "AMAEvent.h"

SPEC_BEGIN(AMAEventsCleanupInfoTests)

describe(@"AMAEventsCleanupInfo", ^{

    AMAEventsCleanupInfo *__block info = nil;

    __auto_type eventWith = ^AMAEvent *(NSNumber *oid, NSUInteger type, NSUInteger globalNumber, NSUInteger numberOfType) {
        AMAEvent *event = [[AMAEvent alloc] init];
        event.oid = oid;
        event.type = type;
        event.globalNumber = globalNumber;
        event.numberOfType = numberOfType;
        return event;
    };
    __auto_type reportWith = ^(NSString *reason,
                               NSArray *eventTypes,
                               NSArray *globalNumbers,
                               NSArray *numbersOfType,
                               NSNumber *actualDeletedNumber,
                               NSNumber *corruptedNumber)
    {
        return @{
            @"details": @{
                @"reason": reason,
                @"cleared": @{
                    @"event_type": eventTypes,
                    @"global_number": globalNumbers,
                    @"number_of_type": numbersOfType,
                },
                @"actual_deleted_number": actualDeletedNumber,
                @"corrupted_number": corruptedNumber,
            },
        };
    };

    context(@"Bad Request", ^{
        NSString *const reason = @"bad_request";

        beforeEach(^{
            info = [[AMAEventsCleanupInfo alloc] initWithReasonType:AMAEventsCleanupReasonTypeBadRequest];
        });

        it(@"Should add valid event", ^{
            [[theValue([info addEvent:eventWith(@4, 8, 15, 16)]) should] beYes];
        });
        it(@"Should not add event without oid", ^{
            [[theValue([info addEvent:eventWith(nil, 8, 15, 16)]) should] beNo];
        });
        it(@"Should not add nil", ^{
            [[theValue([info addEvent:nil]) should] beNo];
        });

        context(@"Single event", ^{
            beforeEach(^{
                [info addEvent:eventWith(@4, 8, 15, 16)];
            });
            it(@"Should report", ^{
                [[theValue(info.shouldReport) should] beYes];
            });
            it(@"Should have valid oids", ^{
                [[info.eventOids should] equal:@[ @4 ]];
            });
            it(@"Should have valid report", ^{
                [[info.cleanupReport should] equal:reportWith(reason, @[ @8 ], @[ @15 ], @[ @16 ], @0, @0)];
            });
            context(@"With actual deleted number", ^{
                beforeEach(^{
                    info.actualDeletedNumber = 23;
                });
                it(@"Should have valid report", ^{
                    [[info.cleanupReport should] equal:reportWith(reason, @[ @8 ], @[ @15 ], @[ @16 ], @23, @0)];
                });
            });
            context(@"With some corrupted events", ^{
                beforeEach(^{
                    [info addEventByOid:@23];
                    [info addEventByOid:@42];
                });
                it(@"Should have valid oids", ^{
                    [[info.eventOids should] equal:@[ @4, @23, @42 ]];
                });
                it(@"Should have valid report", ^{
                    [[info.cleanupReport should] equal:reportWith(reason, @[ @8 ], @[ @15 ], @[ @16 ], @0, @2)];
                });
            });
        });

        context(@"Multiple events", ^{
            beforeEach(^{
                [info addEvent:eventWith(@1, 2, 3, 4)];
                [info addEvent:eventWith(@5, 6, 7, 8)];
                [info addEvent:eventWith(@9, 10, 11, 12)];
                [info addEventByOid:@13];
                [info addEventByOid:@14];
                [info addEventByOid:@15];
                info.actualDeletedNumber = 16;
            });
            it(@"Should report", ^{
                [[theValue(info.shouldReport) should] beYes];
            });
            it(@"Should have valid oids", ^{
                [[info.eventOids should] equal:@[ @1, @5, @9, @13, @14, @15 ]];
            });
            it(@"Should have valid report", ^{
                [[info.cleanupReport should] equal:reportWith(reason,
                                                              @[ @2, @6, @10 ],
                                                              @[ @3, @7, @11 ],
                                                              @[ @4, @8, @12 ],
                                                              @16, @3)];
            });
        });

        context(@"Multiple with nil and no-oid", ^{
            beforeEach(^{
                [info addEvent:eventWith(@1, 2, 3, 4)];
                [info addEvent:nil];
                [info addEvent:eventWith(nil, 5, 6, 7)];
                [info addEventByOid:@8];
                info.actualDeletedNumber = 9;
            });
            it(@"Should report", ^{
                [[theValue(info.shouldReport) should] beYes];
            });
            it(@"Should have valid oids", ^{
                [[info.eventOids should] equal:@[ @1, @8 ]];
            });
            it(@"Should have valid report", ^{
                [[info.cleanupReport should] equal:reportWith(reason, @[ @2 ], @[ @3 ], @[ @4 ], @9, @1)];
            });
        });
    });

    context(@"Successful Report", ^{
        beforeEach(^{
            info = [[AMAEventsCleanupInfo alloc] initWithReasonType:AMAEventsCleanupReasonTypeSuccessfulReport];
            [info addEvent:eventWith(@1, 2, 3, 4)];
            [info addEventByOid:@5];
            info.actualDeletedNumber = 6;
        });
        it(@"Should not report", ^{
            [[theValue(info.shouldReport) should] beNo];
        });
        it(@"Should have valid oids", ^{
            [[info.eventOids should] equal:@[ @1, @5 ]];
        });
        it(@"Should have valid report", ^{
            [[info.cleanupReport should] equal:reportWith(@"successful_report", @[ @2 ], @[ @3 ], @[ @4 ], @6, @1)];
        });
    });

    context(@"Entity Too Large", ^{
        beforeEach(^{
            info = [[AMAEventsCleanupInfo alloc] initWithReasonType:AMAEventsCleanupReasonTypeEntityTooLarge];
            [info addEvent:eventWith(@1, 2, 3, 4)];
            [info addEventByOid:@5];
            info.actualDeletedNumber = 6;
        });
        it(@"Should report", ^{
            [[theValue(info.shouldReport) should] beYes];
        });
        it(@"Should have valid oids", ^{
            [[info.eventOids should] equal:@[ @1, @5 ]];
        });
        it(@"Should have valid report", ^{
            [[info.cleanupReport should] equal:reportWith(@"entity_too_large", @[ @2 ], @[ @3 ], @[ @4 ], @6, @1)];
        });
    });

    context(@"DB Overflow", ^{
        beforeEach(^{
            info = [[AMAEventsCleanupInfo alloc] initWithReasonType:AMAEventsCleanupReasonTypeDBOverflow];
            [info addEvent:eventWith(@1, 2, 3, 4)];
            [info addEventByOid:@5];
            info.actualDeletedNumber = 6;
        });
        it(@"Should report", ^{
            [[theValue(info.shouldReport) should] beYes];
        });
        it(@"Should have valid oids", ^{
            [[info.eventOids should] equal:@[ @1, @5 ]];
        });
        it(@"Should have valid report", ^{
            [[info.cleanupReport should] equal:reportWith(@"db_overflow", @[ @2 ], @[ @3 ], @[ @4 ], @6, @1)];
        });
    });

    context(@"Unknown type", ^{
        beforeEach(^{
            info = [[AMAEventsCleanupInfo alloc] initWithReasonType:(AMAEventsCleanupReasonType)999];
            [info addEvent:eventWith(@1, 2, 3, 4)];
            [info addEventByOid:@5];
            info.actualDeletedNumber = 6;
        });

        it(@"Should assert on shouldReport", ^{
            [[theBlock(^{
                [info shouldReport];
            }) should] raise];
        });
        it(@"Should assert on cleanupReport", ^{
            [[theBlock(^{
                [info cleanupReport];
            }) should] raise];
        });
        context(@"Stub assertions", ^{
            beforeEach(^{
                [AMATestUtilities stubAssertions];
            });
            it(@"Should not report", ^{
                [[theValue(info.shouldReport) should] beNo];
            });
            it(@"Should have valid oids", ^{
                [[info.eventOids should] equal:@[ @1, @5 ]];
            });
            it(@"Should have valid report", ^{
                [[info.cleanupReport should] equal:reportWith(@"unknown", @[ @2 ], @[ @3 ], @[ @4 ], @6, @1)];
            });
        });
    });

});

SPEC_END
