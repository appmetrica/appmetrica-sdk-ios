#import <Kiwi/Kiwi.h>

#import <AppMetricaCore/AppMetricaCore.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

#import "AMACrashReporter.h"

#import "AMACrashProcessingReporting.h"

SPEC_BEGIN(AMACrashReporterTests)

describe(@"AMACrashReporter", ^{
    
    let(mockReporter, ^{ return [KWMock nullMockForProtocol:@protocol(AMAAppMetricaReporting)]; });
    let(crashReporter, ^{ return [[AMACrashReporter alloc] initWithReporter:mockReporter]; });
    
    context(@"Reporting crash", ^{
        
        NSError *const failureError = [NSError errorWithDomain:@"TestFailureDomain" code:999 userInfo:nil];
        __block void (^onFailureBlock)(NSError *);
        
        beforeEach(^{
            [AMAAppMetrica stub:@selector(reportEventWithParameters:onFailure:) withBlock:^id(NSArray *params) {
                void (^failureBlock)(NSError *) = params[1];
                if ([failureBlock isEqual:NSNull.null] == NO) {
                    failureBlock(failureError);
                }
                return nil;
            }];
        });
        
        it(@"Should properly report a crash", ^{
            [[AMAAppMetrica should] receive:@selector(reportEventWithParameters:onFailure:)];
            
            [crashReporter reportCrashWithParameters:[AMAEventPollingParameters mock]];
        });
        
        it(@"Should properly report an ANR", ^{
            [[AMAAppMetrica should] receive:@selector(reportEventWithParameters:onFailure:)];
            
            [crashReporter reportANRWithParameters:[AMAEventPollingParameters mock]];
        });
        
        it(@"Should properly report an Error", ^{
            [[AMAAppMetrica should] receive:@selector(reportEventWithParameters:onFailure:)];
            
            [crashReporter reportErrorWithParameters:[AMAEventPollingParameters mock] onFailure:nil];
        });
        
        it(@"Should report internal error when AMAAppMetrica's onFailure is called for crash", ^{
            [[mockReporter should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:@"internal_error_crash", kw_any(), kw_any()];
            
            [crashReporter reportCrashWithParameters:[AMAEventPollingParameters mock]];
        });
        
        it(@"Should report internal error when AMAAppMetrica's onFailure is called for ANR", ^{
            [[mockReporter should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:@"internal_error_anr", kw_any(), kw_any()];
            
            [crashReporter reportANRWithParameters:[AMAEventPollingParameters mock]];
        });
        
        it(@"Should call the onFailure block when reporting an Error fails", ^{
            
            __block BOOL onFailureCalled = NO;
            
            void (^failureBlock)(NSError *) = ^(NSError *error){
                onFailureCalled = YES;
                [[error should] equal:failureError];
            };
            
            [crashReporter reportErrorWithParameters:[AMAEventPollingParameters mock] onFailure:failureBlock];
            
            [[theValue(onFailureCalled) should] beYes];
        });
    });
    
    
    context(@"Reporting crash with extended reporters", ^{
        
        let(extendedReporterMock1, ^id{
            return [KWMock mockForProtocol:@protocol(AMACrashProcessingReporting)];
        });
        let(extendedReporterMock2, ^id{
            return [KWMock mockForProtocol:@protocol(AMACrashProcessingReporting)];
        });
        
        beforeEach(^{
            [crashReporter.extendedCrashReporters addObject:extendedReporterMock1];
            [crashReporter.extendedCrashReporters addObject:extendedReporterMock2];
        });
        
        it(@"Should call reportCrash: on extendedCrashReporters", ^{
            [[extendedReporterMock1 should] receive:@selector(reportCrash:) withArguments:@"Unhandled crash"];
            [[extendedReporterMock2 should] receive:@selector(reportCrash:) withArguments:@"Unhandled crash"];
            
            [crashReporter reportCrashWithParameters:[AMAEventPollingParameters mock]];
        });
    });
    
    context(@"Reporting internal errors with specific event names", ^{
        
        NSError *const invalidNameError = [NSError errorWithDomain:@"AMAAppMetricaEventErrorCodeDomain"
                                                              code:AMAAppMetricaEventErrorCodeInvalidName
                                                          userInfo:nil];
        NSError *const recrashError = [NSError errorWithDomain:@"AMAAppMetricaEventErrorCodeDomain"
                                                          code:AMAAppMetricaInternalEventErrorCodeRecrash
                                                      userInfo:nil];
        NSError *const unsupportedVersionError = [NSError errorWithDomain:@"AMAAppMetricaEventErrorCodeDomain"
                                                                     code:AMAAppMetricaInternalEventErrorCodeUnsupportedReportVersion
                                                                 userInfo:nil];
        
        it(@"Should report 'corrupted_crash_report_invalid_name' for InvalidName error", ^{
            [[mockReporter should] receive:@selector(reportEvent:parameters:onFailure:) 
                             withArguments:@"corrupted_crash_report_invalid_name", kw_any(), kw_any()];
            
            [crashReporter reportInternalError:invalidNameError];
        });
        
        it(@"Should report 'crash_report_recrash' for Recrash error", ^{
            [[mockReporter should] receive:@selector(reportEvent:parameters:onFailure:) 
                             withArguments:@"crash_report_recrash", kw_any(), kw_any()];
            
            [crashReporter reportInternalError:recrashError];
        });
        
        it(@"Should report 'crash_report_version_unsupported' for UnsupportedReportVersion error", ^{
            [[mockReporter should] receive:@selector(reportEvent:parameters:onFailure:) 
                             withArguments:@"crash_report_version_unsupported", kw_any(), kw_any()];
            
            [crashReporter reportInternalError:unsupportedVersionError];
        });
        
        it(@"Should not report for errors with unrecognized error codes", ^{
            NSError *const unrecognizedError = [NSError errorWithDomain:@"AMAAppMetricaEventErrorCodeDomain"
                                                                   code:9999 // Some arbitrary code that's not in your list
                                                               userInfo:nil];
            
            [[mockReporter shouldNot] receive:@selector(reportEvent:parameters:onFailure:)];
            
            [crashReporter reportInternalError:unrecognizedError];
        });
        
        context(@"Reporting internal errors with specific event names", ^{
            
            it(@"Should report correctly for InvalidName error with no userInfo", ^{
                NSError *const invalidNameError = [NSError errorWithDomain:@"AMAAppMetricaEventErrorCodeDomain"
                                                                      code:AMAAppMetricaEventErrorCodeInvalidName
                                                                  userInfo:nil];
                
                [[mockReporter should] receive:@selector(reportEvent:parameters:onFailure:)
                                 withArguments:@"corrupted_crash_report_invalid_name", @{
                    @"domain" : @"AMAAppMetricaEventErrorCodeDomain",
                    @"error_code" : @(AMAAppMetricaEventErrorCodeInvalidName),
                    @"error_details" : @"No error details supplied"
                }, kw_any()];
                
                [crashReporter reportInternalError:invalidNameError];
            });
            
            it(@"Should report correctly for InvalidName error with userInfo", ^{
                NSError *const invalidNameError = [NSError errorWithDomain:@"AMAAppMetricaEventErrorCodeDomain"
                                                                      code:AMAAppMetricaEventErrorCodeInvalidName
                                                                  userInfo:@{ @"info" : @"Some detail" }];
                
                [[mockReporter should] receive:@selector(reportEvent:parameters:onFailure:)
                                 withArguments:@"corrupted_crash_report_invalid_name", @{
                    @"domain" : @"AMAAppMetricaEventErrorCodeDomain",
                    @"error_code" : @(AMAAppMetricaEventErrorCodeInvalidName),
                    @"error_details" : @"{\n    info = \"Some detail\";\n}"
                }, kw_any()];
                
                [crashReporter reportInternalError:invalidNameError];
            });
        });
        
        context(@"Reporting internal corrupted errors and crashes", ^{
            
            NSError *const someError = [NSError errorWithDomain:@"AMAAppMetricaEventErrorCodeDomain"
                                                           code:101
                                                       userInfo:nil];
            
            it(@"Should report 'corrupted_crash_report' when reportInternalCorruptedCrash: is called", ^{
                [[mockReporter should] receive:@selector(reportEvent:parameters:onFailure:)
                                 withArguments:@"corrupted_crash_report", @{
                    @"domain" : @"AMAAppMetricaEventErrorCodeDomain",
                    @"error_code" : @(101),
                    @"error_details" : @"No error details supplied"
                }, kw_any()];
                
                [crashReporter reportInternalCorruptedCrash:someError];
            });
            
            it(@"Should report 'corrupted_error_report' when reportInternalCorruptedError: is called", ^{
                [[mockReporter should] receive:@selector(reportEvent:parameters:onFailure:)
                                 withArguments:@"corrupted_error_report", @{
                    @"domain" : @"AMAAppMetricaEventErrorCodeDomain",
                    @"error_code" : @(101),
                    @"error_details" : @"No error details supplied"
                }, kw_any()];
                
                [crashReporter reportInternalCorruptedError:someError];
            });
        });
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
            
            [crashReporter reportFailedTransactionWithID:testTransactionID
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
                
                [crashReporter reportFailedTransactionWithID:@"TestTransactionID"
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
                
                [crashReporter reportFailedTransactionWithID:@"TestTransactionID"
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
                
                [crashReporter reportFailedTransactionWithID:@"TestTransactionID"
                                                   ownerName:@"TestOwner"
                                             rollbackContent:@"TestRollbackContent"
                                           rollbackException:nil
                                              rollbackFailed:YES];
            });
            
        });
    });
});

SPEC_END
