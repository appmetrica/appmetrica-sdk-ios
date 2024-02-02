#import <Kiwi/Kiwi.h>
#import <AppMetricaCore/AppMetricaCore.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMACrashReporter.h"
#import "AMACrashProcessingReporting.h"
#import "AMACrashEventType.h"
#import "AMAExceptionFormatter.h"
#import "AMAErrorEnvironment.h"
#import "AMAErrorModelFactory.h"

// FIXME: Fix exposing properties
@interface AMACrashReporter ()
@property (nonatomic, strong, readonly) id<AMAAppMetricaReporting> libraryErrorReporter;
@property (nonatomic, strong, readonly) id<AMAExceptionFormatting> exceptionFormatter;
@property (nonatomic, strong, readonly) AMAErrorModelFactory *errorModelFactory;
@property (nonatomic, strong) AMAEnvironmentContainer *errorEnvironment;
@end

SPEC_BEGIN(AMACrashReporterTests)

describe(@"AMACrashReporter", ^{
    NSString *const testsAPIKey = @"550e8400-e29b-41d4-a716-446655440000";
    
    AMACrashReporter *__block crashReporter = nil;
    
    NSObject *__block mockReporter = nil;
    NSObject *__block extendedReporter = nil;
    
    AMAExceptionFormatter *__block exceptionFormatter = nil;
    AMAErrorModelFactory *__block errorModelFactory = nil;
    
    beforeEach(^{
        errorModelFactory = [AMAErrorModelFactory nullMock];
        
        exceptionFormatter = [AMAExceptionFormatter nullMock];
        
        crashReporter = [[AMACrashReporter alloc] initWithApiKey:testsAPIKey];
        mockReporter = [KWMock nullMockForProtocol:@protocol(AMAAppMetricaReporting)];
        
        extendedReporter = [KWMock nullMockForProtocol:@protocol(AMAAppMetricaExtendedReporting)];
        
        [crashReporter stub:@selector(libraryErrorReporter) andReturn:mockReporter];
        
        [AMAAppMetrica stub:@selector(extendedReporterForApiKey:) andReturn:extendedReporter withArguments:testsAPIKey];
    });
    
    context(@"Reporting crash", ^{
        
        NSError *const failureError = [NSError errorWithDomain:@"TestFailureDomain" code:999 userInfo:nil];
        __block void (^onFailureBlock)(NSError *);
        
        beforeEach(^{
            [extendedReporter stub:@selector(reportBinaryEventWithType:data:name:gZipped:eventEnvironment:appEnvironment:extras:bytesTruncated:onFailure:) withBlock:^id(NSArray *params) {
                void (^failureBlock)(NSError *) = params[8];
                if ([failureBlock isEqual:NSNull.null] == NO) {
                    failureBlock(failureError);
                }
                return nil;
            }];
            
            [extendedReporter stub:@selector(reportFileEventWithType:data:fileName:gZipped:encrypted:truncated:eventEnvironment:appEnvironment:extras:onFailure:) withBlock:^id(NSArray *params) {
                void (^failureBlock)(NSError *) = params[9];
                if ([failureBlock isEqual:NSNull.null] == NO) {
                    failureBlock(failureError);
                }
                return nil;
            }];
        });
        
        it(@"Should report a crash", ^{
            [[extendedReporter should] receive:@selector(reportFileEventWithType:
                                                         data:
                                                         fileName:
                                                         gZipped:
                                                         encrypted:
                                                         truncated:
                                                         eventEnvironment:
                                                         appEnvironment:
                                                         extras:
                                                         onFailure:)
                                 withArguments:theValue(AMACrashEventTypeCrash), kw_any(), kw_any(),
             theValue(YES), theValue(NO), theValue(NO), kw_any(), kw_any(), kw_any(), kw_any()];
            
            [crashReporter reportCrashWithParameters:[[AMAEventPollingParameters alloc] initWithEventType:99]];
        });
        
        it(@"Should report an ANR", ^{
            [[extendedReporter should] receive:@selector(reportFileEventWithType:
                                                         data:
                                                         fileName:
                                                         gZipped:
                                                         encrypted:
                                                         truncated:
                                                         eventEnvironment:
                                                         appEnvironment:
                                                         extras:
                                                         onFailure:)
                                 withArguments:theValue(AMACrashEventTypeANR), kw_any(), kw_any(),
             theValue(YES), theValue(NO), theValue(NO), kw_any(), kw_any(), kw_any(), kw_any()];
            
            [crashReporter reportANRWithParameters:[[AMAEventPollingParameters alloc] initWithEventType:99]];
        });
        
        it(@"Should report an Error", ^{
            [crashReporter stub:@selector(exceptionFormatter) andReturn:exceptionFormatter];
            [crashReporter stub:@selector(errorModelFactory) andReturn:errorModelFactory];
            [exceptionFormatter stub:@selector(formattedError:error:) andReturn:[NSData data]];
            
            id errorModel = [KWMock nullMockForProtocol:@protocol(AMAErrorRepresentable)];
            [[errorModelFactory should] receive:@selector(modelForErrorRepresentable:options:) withArguments:errorModel, kw_any()];
            
            [[extendedReporter should] receive:@selector(reportBinaryEventWithType:
                                                         data:
                                                         name:
                                                         gZipped:
                                                         eventEnvironment:
                                                         appEnvironment:
                                                         extras:
                                                         bytesTruncated:
                                                         onFailure:)
                                 withArguments:theValue(AMACrashEventTypeError), kw_any(), kw_any(),
             theValue(YES), kw_any(), kw_any(), kw_any(), theValue(0), kw_any(), kw_any()];
            
            [crashReporter reportError:errorModel onFailure:nil];
        });
        
        it(@"Should report a NSError", ^{
            [crashReporter stub:@selector(exceptionFormatter) andReturn:exceptionFormatter];
            [crashReporter stub:@selector(errorModelFactory) andReturn:errorModelFactory];
            [exceptionFormatter stub:@selector(formattedError:error:) andReturn:[NSData data]];
            
            NSError *error = [NSError nullMock];
            [[errorModelFactory should] receive:@selector(modelForNSError:options:) withArguments:error, kw_any()];
            
            [[extendedReporter should] receive:@selector(reportBinaryEventWithType:
                                                         data:
                                                         name:
                                                         gZipped:
                                                         eventEnvironment:
                                                         appEnvironment:
                                                         extras:
                                                         bytesTruncated:
                                                         onFailure:)
                                 withArguments:theValue(AMACrashEventTypeError), kw_any(), kw_any(),
             theValue(YES), kw_any(), kw_any(), kw_any(), theValue(0), kw_any(), kw_any()];
            
            [crashReporter reportNSError:error onFailure:nil];
        });
        
        // TODO: Add arguments check
        context(@"Plugin error reporting", ^{
            NSString *const message = @"message";
            
            it(@"Should report an Unhandled exception", ^{
                [crashReporter stub:@selector(exceptionFormatter) andReturn:exceptionFormatter];
                [exceptionFormatter stub:@selector(formattedCrashErrorDetails:bytesTruncated:error:) 
                               andReturn:[NSData data]];
                
                [[extendedReporter should] receive:@selector(reportBinaryEventWithType:
                                                             data:
                                                             name:
                                                             gZipped:
                                                             eventEnvironment:
                                                             appEnvironment:
                                                             extras:
                                                             bytesTruncated:
                                                             onFailure:)
                                     withArguments:theValue(AMACrashEventTypeCrash), kw_any(), kw_any(),
                 theValue(YES), kw_any(), kw_any(), kw_any(), theValue(0), kw_any(), kw_any()];
                
                [crashReporter reportUnhandledException:[AMAPluginErrorDetails nullMock] onFailure:nil];
            });
            
            it(@"Should report an exception with message", ^{
                [crashReporter stub:@selector(exceptionFormatter) andReturn:exceptionFormatter];
                [exceptionFormatter stub:@selector(formattedErrorErrorDetails:bytesTruncated:error:)
                               andReturn:[NSData data]];
                
                [[extendedReporter should] receive:@selector(reportBinaryEventWithType:
                                                             data:
                                                             name:
                                                             gZipped:
                                                             eventEnvironment:
                                                             appEnvironment:
                                                             extras:
                                                             bytesTruncated:
                                                             onFailure:)
                                     withArguments:theValue(AMACrashEventTypeError), kw_any(), message,
                 theValue(YES), kw_any(), kw_any(), kw_any(), theValue(0), kw_any(), kw_any()];
                
                [crashReporter reportError:[AMAPluginErrorDetails nullMock] message:message onFailure:nil];
            });
            
            it(@"Should report an error with identifier", ^{
                [crashReporter stub:@selector(exceptionFormatter) andReturn:exceptionFormatter];
                [exceptionFormatter stub:@selector(formattedCustomErrorErrorDetails:identifier:bytesTruncated:error:)
                               andReturn:[NSData data]];
                
                [[extendedReporter should] receive:@selector(reportBinaryEventWithType:
                                                             data:
                                                             name:
                                                             gZipped:
                                                             eventEnvironment:
                                                             appEnvironment:
                                                             extras:
                                                             bytesTruncated:
                                                             onFailure:)
                                     withArguments:theValue(AMACrashEventTypeError), kw_any(), message,
                 theValue(YES), kw_any(), kw_any(), kw_any(), theValue(0), kw_any(), kw_any()];
                
                [crashReporter reportErrorWithIdentifier:@""
                                                 message:message
                                                 details:[AMAPluginErrorDetails nullMock]
                                               onFailure:nil];;
            });
        });
        
        it(@"Should report internal error when AMAAppMetrica's onFailure is called for crash", ^{
            [[mockReporter should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:@"internal_error_crash", kw_any(), kw_any()];
            
            [crashReporter reportCrashWithParameters:[[AMAEventPollingParameters alloc] initWithEventType:99]];
        });
        
        it(@"Should report internal error when AMAAppMetrica's onFailure is called for ANR", ^{
            [[mockReporter should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:@"internal_error_anr", kw_any(), kw_any()];
            
            [crashReporter reportANRWithParameters:[[AMAEventPollingParameters alloc] initWithEventType:99]];
        });
        
        it(@"Should call the onFailure block when reporting an Error fails", ^{
            
            __block BOOL onFailureCalled = NO;
            
            void (^failureBlock)(NSError *) = ^(NSError *error){
                onFailureCalled = YES;
                [[error should] equal:failureError];
            };
            
            [crashReporter reportError:[KWMock nullMockForProtocol:@protocol(AMAErrorRepresentable)] onFailure:failureBlock];
            
            [[theValue(onFailureCalled) should] beYes];
        });
        
        context(@"Error Environment Manipulation", ^{
            
            AMAErrorEnvironment *__block errorEnvironment = nil;
            
            beforeEach(^{
                errorEnvironment = [AMAErrorEnvironment nullMock];
                
                [crashReporter stub:@selector(errorEnvironment) andReturn:errorEnvironment];
            });

            it(@"Should correctly set the error environment value for a given key", ^{
                [[errorEnvironment should] receive:@selector(addValue:forKey:) withArguments:@"sampleValue", @"sampleKey"];
                [crashReporter setErrorEnvironmentValue:@"sampleValue" forKey:@"sampleKey"];
            });

            it(@"Should clear the error environment", ^{
                [[errorEnvironment should] receive:@selector(clearEnvironment)];
                [crashReporter clearErrorEnvironment];
            });
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
