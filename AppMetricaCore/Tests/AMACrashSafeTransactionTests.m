
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMACrashSafeTransactor.h"
#import "AMAAppMetrica+Internal.h"
#import "AMAInternalEventsReporter.h"
#import "AMAMetricaConfigurationTestUtilities.h"

SPEC_BEGIN(AMACrashSafeTransactorTests)

describe(@"AMACrashSafeTransactor", ^{

    AMAUserDefaultsMock *__block defaultsMock = nil;
    AMAInternalEventsReporter *__block reporter = nil;

    NSString *buildUID = @"BUILD";
    NSString *transactionID = @"TRANSACTION";
    NSString *transactionName = @"NAME";
    NSString *transactionKey = [NSString stringWithFormat:@"AMATransaction:%@%@", transactionID, transactionName];

    SEL const reportingSelector =
        @selector(reportFailedTransactionWithID:ownerName:rollbackContent:rollbackException:rollbackFailed:);

    NSDictionary *lockValue = @{
        @"name": transactionName,
        @"buildUID": buildUID,
        @"shouldBeReported": @YES,
        @"rollbackLocked": @NO
    };

    beforeEach(^{
        reporter = [AMAInternalEventsReporter nullMock];
        [AMAAppMetrica stub:@selector(sharedInternalEventsReporter) andReturn:reporter];
        
        defaultsMock = [[AMAUserDefaultsMock alloc] init];
        [NSUserDefaults stub:@selector(standardUserDefaults) andReturn:defaultsMock];

        [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];
        AMABuildUID *buildUIDMock = [AMABuildUID nullMock];
        [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(appBuildUID) andReturn:buildUIDMock];
        [buildUIDMock stub:@selector(stringValue) andReturn:buildUID];
    });

    it(@"Should remove lock-flag on transaction success", ^{
        [AMACrashSafeTransactor processTransactionWithID:transactionID name:transactionName transaction:^{
        }];
        [[defaultsMock.store should] beEmpty];
    });

    it(@"Should leave lock-flag on transaction failure", ^{
        [[theBlock(^{
            [AMACrashSafeTransactor processTransactionWithID:transactionID name:transactionName transaction:^{
                [NSException raise:@"" format:@""];
            }];
        }) should] raise];
        [[defaultsMock.store[transactionKey] should] equal:lockValue];
    });

    context(@"After crash", ^{
        AMATestSafeTransactionRollbackContext *rollbackContext = [AMATestSafeTransactionRollbackContext new];
        NSData *rollbackData = [NSKeyedArchiver archivedDataWithRootObject:rollbackContext];
        NSString *brokenRollbackExceptionName = @"Exception name";
        AMACrashSafeTransactorRollbackBlock brokenRollback = ^NSString *(id context){
            [NSException raise:brokenRollbackExceptionName format:@""];
            return nil;
        };

        beforeEach(^{
            NSMutableDictionary *dictionary = [lockValue mutableCopy];
            [dictionary setObject:rollbackData forKey:@"rollbackContext"];

            defaultsMock.store[transactionKey] = dictionary;
        });

        it(@"Should call rollback", ^{
            BOOL __block rollbackCalled = NO;
            [AMACrashSafeTransactor processTransactionWithID:transactionID name:transactionName transaction:nil
                                                    rollback:^NSString *(id context){
                rollbackCalled = YES;
                return nil;
            }];
            [[theValue(rollbackCalled) should] beYes];
        });

        it(@"Should remove lock-flag after rollback", ^{
            [AMACrashSafeTransactor processTransactionWithID:transactionID name:transactionName transaction:nil
                                                    rollback:^NSString *(id context){
                return nil;
            }];
            [[defaultsMock.store should] beEmpty];
        });

        it(@"Should leave flag if no rollback passed", ^{
            [AMACrashSafeTransactor processTransactionWithID:transactionID name:transactionName transaction:nil
                                                        rollback:^NSString *(id context){
                [NSException raise:@"" format:@""];
                return nil;
            }];
            [[defaultsMock.store[transactionKey] should] beNonNil];
        });

        it(@"Returned context should be equal to the context saved", ^{
            __block BOOL rollbackContextEqual = NO;
            [AMACrashSafeTransactor processTransactionWithID:transactionID name:transactionName transaction:nil
                                                    rollback:^NSString *(AMATestSafeTransactionRollbackContext *context){
                rollbackContextEqual = [rollbackContext isEqual:context];

                return nil;
            }];
            [[theValue(rollbackContextEqual) should] beYes];
        });

        it(@"Should not call transaction after empty rollback block processed", ^{
            BOOL __block transactionCalled = NO;
            [AMACrashSafeTransactor processTransactionWithID:transactionID name:transactionName transaction:nil];
            [AMACrashSafeTransactor processTransactionWithID:transactionID name:transactionName transaction:^{
                transactionCalled = YES;
            }];
            [[theValue(transactionCalled) should] beNo];
        });

        it(@"Should not call transaction", ^{
            BOOL __block transactionCalled = NO;
            [AMACrashSafeTransactor processTransactionWithID:transactionID name:transactionName transaction:^{
                transactionCalled = YES;
            }];
            [[theValue(transactionCalled) should] beNo];
        });

        context(@"Reporting", ^{

            it(@"Should report valid event for transaction without rollback", ^{
                [[reporter should] receive:reportingSelector
                             withArguments:transactionID, transactionName, nil, nil, theValue(NO)];
                [AMACrashSafeTransactor processTransactionWithID:transactionID
                                                            name:transactionName
                                                     transaction:nil];
            });

            it(@"Should report valid event for successful rollback", ^{
                NSString *rollbackReturnValue = @"rollback_value";
                [[reporter should] receive:reportingSelector
                             withArguments:transactionID, transactionName, rollbackReturnValue, nil, theValue(NO)];
                [AMACrashSafeTransactor processTransactionWithID:transactionID
                                                            name:transactionName
                                                     transaction:nil
                                                        rollback:^NSString *(id context) {
                                                            return rollbackReturnValue;
                                                        }];
            });

            it(@"Should report valid event for rollback with exception", ^{
                [[reporter should] receive:reportingSelector
                             withArguments:transactionID, transactionName, nil, kw_any(), theValue(YES)];
                [AMACrashSafeTransactor processTransactionWithID:transactionID
                                                            name:transactionName
                                                     transaction:nil
                                                        rollback:brokenRollback];
            });

            it(@"Should report event with rollback exception", ^{
                KWCaptureSpy *spy = [reporter captureArgument:reportingSelector atIndex:3];
                [AMACrashSafeTransactor processTransactionWithID:transactionID
                                                            name:transactionName
                                                     transaction:nil
                                                        rollback:brokenRollback];
                NSException *raisedException = spy.argument;
                [[raisedException.name should] equal:brokenRollbackExceptionName];
            });

            it(@"Should not report event about transaction failure twice", ^{
                [[reporter should] receive:reportingSelector withCount:1];
                [AMACrashSafeTransactor processTransactionWithID:transactionID name:transactionName transaction:nil];
                [AMACrashSafeTransactor processTransactionWithID:transactionID name:transactionName transaction:nil];
            });

        });

        context(@"Rollback failed", ^{

            it(@"Should catch exception in rollback", ^{
                [[theBlock(^{
                    [AMACrashSafeTransactor processTransactionWithID:transactionID
                                                                name:transactionName
                                                         transaction:nil
                                                            rollback:brokenRollback];
                }) shouldNot] raise];
            });

            it(@"Should leave transaction lock flag", ^{
                [AMACrashSafeTransactor processTransactionWithID:transactionID
                                                            name:transactionName
                                                     transaction:nil
                                                        rollback:brokenRollback];
                [[defaultsMock.store[transactionKey] should] beNonNil];
            });

        });
    });

    context(@"After update", ^{

        beforeEach(^{
            NSMutableDictionary *oldLockValue = [lockValue mutableCopy];
            oldLockValue[@"buildUID"] = @"OLD_BUILD";
            defaultsMock.store[transactionKey] = [oldLockValue copy];
        });

        it(@"Should not call rollback", ^{
            BOOL __block rollbackCalled = NO;
            [AMACrashSafeTransactor processTransactionWithID:transactionID
                                                        name:transactionName
                                                 transaction:nil
                                                    rollback:^NSString *(id context){
                rollbackCalled = YES;
                return nil;
            }];
            [[theValue(rollbackCalled) should] beNo];
        });

        it(@"Should remove lock-flag after transaction", ^{
            defaultsMock.store[transactionKey] = nil;
            [AMACrashSafeTransactor processTransactionWithID:transactionID name:transactionName
                                                 transaction:^{}];
            [[defaultsMock.store should] beEmpty];
        });

    });

});

SPEC_END
