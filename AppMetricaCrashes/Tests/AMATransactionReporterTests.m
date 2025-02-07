
#import <Kiwi/Kiwi.h>
#import <AppMetricaCore/AppMetricaCore.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMATransactionReporter.h"

SPEC_BEGIN(AMATransactionReporterTests)

describe(@"AMATransactionReporter", ^{
    NSString *const testsAPIKey = @"550e8400-e29b-41d4-a716-446655440000";
    
    AMATransactionReporter *__block reporter = nil;
    
    NSObject *__block mockReporter = nil;
    
    beforeEach(^{
        reporter = [[AMATransactionReporter alloc] initWithApiKey:testsAPIKey];
        mockReporter = [KWMock nullMockForProtocol:@protocol(AMAAppMetricaReporting)];
        
        [reporter stub:@selector(libraryReporter) andReturn:mockReporter];
    });
    
    context(@"Reporting failed transactions", ^{
        NSString *const testTransactionID = @"TestTransactionID";
        NSString *const testOwnerName = @"TestOwner";
        NSString *const testRollbackContent = @"TestRollbackContent";
        BOOL const testRollbackFailed = YES;
        NSException *const testException = [NSException exceptionWithName:@"TestExceptionName"
                                                                   reason:@"TestExceptionReason"
                                                                 userInfo:@{@"key": @"value"}];
        
        it(@"Should properly report failed transactions", ^{
            
            NSDictionary *expectedExceptionParameters = @{
                @"name" : @"TestExceptionName",
                @"reason" : @"TestExceptionReason",
                @"userInfo" : @{@"key" : @"value"}
            };
            
            NSMutableDictionary *expectedParameters = [NSMutableDictionary dictionary];
            expectedParameters[@"name"] = testOwnerName;
            expectedParameters[@"exception"] = expectedExceptionParameters;
            expectedParameters[@"rollbackcontent"] = testRollbackContent;
            expectedParameters[@"rollback"] = @"failed";
            
            [[mockReporter should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:@"TransactionFailure", @{
                testTransactionID : [expectedParameters copy]
            }, kw_any()];
            
            [reporter reportFailedTransactionWithID:testTransactionID
                                          ownerName:testOwnerName
                                    rollbackContent:testRollbackContent
                                  rollbackException:testException
                                     rollbackFailed:testRollbackFailed];
        });
        
        context(@"Edge cases for reporting failed transactions", ^{
            
            it(@"Should handle an empty userInfo dictionary in exception", ^{
                NSException *emptyUserInfoException = [NSException exceptionWithName:@"TestExceptionName" reason:@"TestExceptionReason" userInfo:@{}];
                
                NSDictionary *expectedExceptionParameters = @{
                    @"name" : @"TestExceptionName",
                    @"reason" : @"TestExceptionReason",
                    @"userInfo" : @{}
                };
                
                NSMutableDictionary *expectedParameters = [NSMutableDictionary dictionary];
                expectedParameters[@"name"] = @"TestOwner";
                expectedParameters[@"exception"] = expectedExceptionParameters;
                expectedParameters[@"rollbackcontent"] = @"TestRollbackContent";
                expectedParameters[@"rollback"] = @"failed";
                
                [[mockReporter should] receive:@selector(reportEvent:parameters:onFailure:)
                                 withArguments:@"TransactionFailure", @{
                    @"TestTransactionID" : [expectedParameters copy]
                }, kw_any()];
                
                [reporter reportFailedTransactionWithID:@"TestTransactionID"
                                              ownerName:@"TestOwner"
                                        rollbackContent:@"TestRollbackContent"
                                      rollbackException:emptyUserInfoException
                                         rollbackFailed:YES];
            });
            
            it(@"Should handle a nil userInfo dictionary in exception", ^{
                NSException *nilUserInfoException = [NSException exceptionWithName:@"TestExceptionName" reason:@"TestExceptionReason" userInfo:nil];
                
                NSDictionary *expectedExceptionParameters = @{
                    @"name" : @"TestExceptionName",
                    @"reason" : @"TestExceptionReason"
                };
                
                NSMutableDictionary *expectedParameters = [NSMutableDictionary dictionary];
                expectedParameters[@"name"] = @"TestOwner";
                expectedParameters[@"exception"] = expectedExceptionParameters;
                expectedParameters[@"rollbackcontent"] = @"TestRollbackContent";
                expectedParameters[@"rollback"] = @"failed";
                
                [[mockReporter should] receive:@selector(reportEvent:parameters:onFailure:)
                                 withArguments:@"TransactionFailure", @{
                    @"TestTransactionID" : [expectedParameters copy]
                }, kw_any()];
                
                [reporter reportFailedTransactionWithID:@"TestTransactionID"
                                              ownerName:@"TestOwner"
                                        rollbackContent:@"TestRollbackContent"
                                      rollbackException:nilUserInfoException
                                         rollbackFailed:YES];
            });
            
            it(@"Should handle a nil exception", ^{
                NSMutableDictionary *expectedParameters = [NSMutableDictionary dictionary];
                expectedParameters[@"name"] = @"TestOwner";
                expectedParameters[@"rollbackcontent"] = @"TestRollbackContent";
                expectedParameters[@"rollback"] = @"failed";
                
                [[mockReporter should] receive:@selector(reportEvent:parameters:onFailure:)
                                 withArguments:@"TransactionFailure", @{
                    @"TestTransactionID" : [expectedParameters copy]
                }, kw_any()];
                
                [reporter reportFailedTransactionWithID:@"TestTransactionID"
                                              ownerName:@"TestOwner"
                                        rollbackContent:@"TestRollbackContent"
                                      rollbackException:nil
                                         rollbackFailed:YES];
            });
            
        });
    });
});

SPEC_END
