#import <Kiwi/Kiwi.h>

#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

#import "AMACrashSafeTransactor.h"

SPEC_BEGIN(AMACrashSafeTransactorTests)

describe(@"AMACrashSafeTransactor", ^{
    
    __block AMACrashSafeTransactor *transactor = nil;
    __block AMAUserDefaultsMock *defaultsMock = nil;
    __block NSObject<AMATransactionReporter> *reporterMock = nil;
    
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
        reporterMock = [KWMock mockForProtocol:@protocol(AMATransactionReporter)];
        [reporterMock stub:reportingSelector];

        transactor = [[AMACrashSafeTransactor alloc] initWithReporter:reporterMock];
        
        defaultsMock = [[AMAUserDefaultsMock alloc] init];
        [NSUserDefaults stub:@selector(standardUserDefaults) andReturn:defaultsMock];
        
        AMABuildUID *buildUIDMock = [AMABuildUID nullMock];
        [AMABuildUID stub:@selector(buildUID) andReturn:buildUIDMock];
        [buildUIDMock stub:@selector(stringValue) andReturn:buildUID];
    });
    
    it(@"Should remove lock-flag on transaction success", ^{
        [transactor processTransactionWithID:transactionID name:transactionName transaction:^{
        }];
        [[defaultsMock.store should] beEmpty];
    });
    
    it(@"Should leave lock-flag on transaction failure", ^{
        [[theBlock(^{
            [transactor processTransactionWithID:transactionID name:transactionName transaction:^{
                [NSException raise:@"" format:@""];
            }];
        }) should] raise];
        [[defaultsMock.store[transactionKey] should] equal:lockValue];
    });
    
    context(@"After crash", ^{
        AMATestSafeTransactionRollbackContext *const rollbackContext = [AMATestSafeTransactionRollbackContext new];
        NSData *const rollbackData = [NSKeyedArchiver archivedDataWithRootObject:rollbackContext
                                                           requiringSecureCoding:NO
                                                                           error:NULL];
        NSString *const brokenRollbackExceptionName = @"Exception name";
        AMACrashSafeTransactorRollbackBlock brokenRollback = ^NSString *(id context){
            [NSException raise:brokenRollbackExceptionName format:@""];
            return nil;
        };
        
        beforeEach(^{
            NSMutableDictionary *dictionary = [lockValue mutableCopy];
            dictionary[@"rollbackContext"] = rollbackData;
            
            defaultsMock.store[transactionKey] = dictionary;
        });
        
        it(@"Should call rollback", ^{
            BOOL __block rollbackCalled = NO;
            [transactor processTransactionWithID:transactionID name:transactionName transaction:nil
                                        rollback:^NSString *(id context){
                rollbackCalled = YES;
                return nil;
            }];
            [[theValue(rollbackCalled) should] beYes];
        });
        
        it(@"Should remove lock-flag after rollback", ^{
            [transactor processTransactionWithID:transactionID name:transactionName transaction:nil
                                        rollback:^NSString *(id context){
                return nil;
            }];
            [[defaultsMock.store should] beEmpty];
        });
        
        it(@"Should leave flag if no rollback passed", ^{
            [transactor processTransactionWithID:transactionID name:transactionName transaction:nil
                                        rollback:^NSString *(id context){
                [NSException raise:@"" format:@""];
                return nil;
            }];
            [[defaultsMock.store[transactionKey] should] beNonNil];
        });
        
        context(@"Context", ^{
            
            it(@"Returned context should be equal to the old NSKeyedArchiver API context saved", ^{
                NSMutableDictionary *dictionary = [lockValue mutableCopy];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                dictionary[@"rollbackContext"] = [NSKeyedArchiver archivedDataWithRootObject:rollbackContext];
#pragma clang diagnostic pop
                
                defaultsMock.store[transactionKey] = dictionary;
                
                
                __block BOOL rollbackContextEqual = NO;
                [transactor processTransactionWithID:transactionID name:transactionName transaction:nil
                                            rollback:^NSString *(AMATestSafeTransactionRollbackContext *context){
                    rollbackContextEqual = [rollbackContext isEqual:context];
                    
                    return nil;
                }];
                [[theValue(rollbackContextEqual) should] beYes];
            });
            
            it(@"Returned context should be equal to the context saved", ^{
                __block BOOL rollbackContextEqual = NO;
                [transactor processTransactionWithID:transactionID name:transactionName transaction:nil
                                            rollback:^NSString *(AMATestSafeTransactionRollbackContext *context){
                    rollbackContextEqual = [rollbackContext isEqual:context];
                    
                    return nil;
                }];
                [[theValue(rollbackContextEqual) should] beYes];
            });
        });
        
        it(@"Should not call transaction after empty rollback block processed", ^{
            BOOL __block transactionCalled = NO;
            [transactor processTransactionWithID:transactionID name:transactionName transaction:nil];
            [transactor processTransactionWithID:transactionID name:transactionName transaction:^{
                transactionCalled = YES;
            }];
            [[theValue(transactionCalled) should] beNo];
        });
        
        it(@"Should not call transaction", ^{
            BOOL __block transactionCalled = NO;
            [transactor processTransactionWithID:transactionID name:transactionName transaction:^{
                transactionCalled = YES;
            }];
            [[theValue(transactionCalled) should] beNo];
        });
        
        context(@"Reporting", ^{
            
            it(@"Should report valid event for transaction without rollback", ^{
                [[reporterMock should] receive:reportingSelector
                                 withArguments:transactionID, transactionName, nil, nil, theValue(NO)];
                [transactor processTransactionWithID:transactionID
                                                name:transactionName
                                         transaction:nil];
            });
            
            it(@"Should report valid event for successful rollback", ^{
                NSString *rollbackReturnValue = @"rollback_value";
                [[reporterMock should] receive:reportingSelector
                                 withArguments:transactionID, transactionName, rollbackReturnValue, nil, theValue(NO)];
                [transactor processTransactionWithID:transactionID
                                                name:transactionName
                                         transaction:nil
                                            rollback:^NSString *(id context) {
                    return rollbackReturnValue;
                }];
            });
            
            it(@"Should report valid event for rollback with exception", ^{
                [[reporterMock should] receive:reportingSelector
                                 withArguments:transactionID, transactionName, nil, kw_any(), theValue(YES)];
                [transactor processTransactionWithID:transactionID
                                                name:transactionName
                                         transaction:nil
                                            rollback:brokenRollback];
            });
            
            it(@"Should report event with rollback exception", ^{
                KWCaptureSpy *spy = [reporterMock captureArgument:reportingSelector atIndex:3];
                [transactor processTransactionWithID:transactionID
                                                name:transactionName
                                         transaction:nil
                                            rollback:brokenRollback];
                NSException *raisedException = spy.argument;
                [[raisedException.name should] equal:brokenRollbackExceptionName];
            });
            
            it(@"Should not report event about transaction failure twice", ^{
                [[reporterMock should] receive:reportingSelector withCount:1];
                [transactor processTransactionWithID:transactionID name:transactionName transaction:nil];
                [transactor processTransactionWithID:transactionID name:transactionName transaction:nil];
            });
            
        });
        
        context(@"Rollback failed", ^{
            
            it(@"Should catch exception in rollback", ^{
                [[theBlock(^{
                    [transactor processTransactionWithID:transactionID
                                                    name:transactionName
                                             transaction:nil
                                                rollback:brokenRollback];
                }) shouldNot] raise];
            });
            
            it(@"Should leave transaction lock flag", ^{
                [transactor processTransactionWithID:transactionID
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
            [transactor processTransactionWithID:transactionID
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
            [transactor processTransactionWithID:transactionID name:transactionName
                                     transaction:^{}];
            [[defaultsMock.store should] beEmpty];
        });
        
    });
    
});

SPEC_END
