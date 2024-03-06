#import <Kiwi/Kiwi.h>
#import <mach/exception.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <KSCrash.h>
#import "AMADecodedCrashSerializer.h"
#import "AMAExceptionFormatter.h"
#import "AMADecodedCrash.h"
#import "AMABacktraceFrame.h"
#import "AMACrashReportCrash.h"
#import "AMAThread.h"
#import "AMABacktrace.h"
#import "AMABinaryImage.h"
#import "AMACrashReportError.h"
#import "AMANSException.h"
#import "AMAMach.h"
#import "AMASignal.h"
#import "AMANonFatal.h"
#import "AMAErrorModel.h"
#import "AMAErrorCustomData.h"
#import "AMAErrorNSErrorData.h"
#import "AMABacktraceSymbolicator.h"
#import "AMAVirtualMachineError.h"
#import "AMAPluginErrorDetails.h"
#import "AMAStackTraceElement.h"
#import "AMAInfo.h"
#import "AMAVirtualMachineInfo.h"
#import "AMACrashReportDecoder.h"
#import "AMASystem.h"
#import "AMAKSCrash.h"
#import "AMACppException.h"
#import "AMAVirtualMachineCrash.h"
#import "AMARegistersContainer.h"
#import "AMAStack.h"
#import "AMAErrorModelFactory.h"
#import "AMACrashObjectsFactory.h"
#import "AMABuildUID.h"

static NSException *nsExceptionMock(NSString *name, NSString *reason, NSDictionary *userInfo, NSNumber *frame)
{
    NSException *exception = [NSException exceptionWithName:name reason:reason userInfo:userInfo];
    [exception stub:@selector(callStackReturnAddresses) andReturn:@[ frame ]];
    return exception;
}

SPEC_BEGIN(AMAExceptionFormatterTests)

describe(@"AMAExceptionFormatter", ^{

    __block AMADecodedCrash *decodedCrash = nil;
    __block AMADecodedCrashSerializer *serializer = nil;
    __block KWCaptureSpy *serializerSpy = nil;
    __block KWCaptureSpy *serializerErrorSpy = nil;
    __block AMAExceptionFormatter *formatter = nil;
    __block AMADateProviderMock *dateProvider = nil;
    __block AMABacktraceSymbolicator *symbolicator = nil;
    __block AMACrashReportDecoder *decoder = nil;
    __block AMASystem *systemInfo = nil;

    beforeEach(^{
        decoder = [AMACrashReportDecoder nullMock];
        systemInfo = [AMASystem nullMock];
        serializer = [[AMADecodedCrashSerializer alloc] init];
        serializerSpy = [serializer captureArgument:@selector(dataForCrash:error:) atIndex:0];
        serializerErrorSpy = [serializer captureArgument:@selector(dataForCrash:error:) atIndex:1];
        dateProvider = [[AMADateProviderMock alloc] init];
        [dateProvider freeze];
        symbolicator = [AMABacktraceSymbolicator nullMock];
        formatter = [[AMAExceptionFormatter alloc] initWithDateProvider:dateProvider
                                                             serializer:serializer
                                                           symbolicator:symbolicator
                                                                decoder:decoder];
        AMAKSCrash *ksCrash = [AMAKSCrash nullMock];
        [AMAKSCrash stub:@selector(sharedInstance) andReturn:ksCrash];
        NSDictionary *systemDict = @{ @"key" : @"value" };
        [ksCrash stub:@selector(systemInfo) andReturn:systemDict];
        [decoder stub:@selector(systemInfoForDictionary:) andReturn:systemInfo withArguments:systemDict];
    });

    context(@"Symbolicated frame parsing", ^{

        NSArray *const binaryImages = @[ [AMABinaryImage nullMock], [AMABinaryImage nullMock] ];
        AMABacktrace *const backtrace = [AMABacktrace nullMock];

        __block NSException *exception = nil;
        
        NSString *const kExpectedExceptionName = @"ExceptionName";
        NSString *const kExpectedExceptionReason = @"ExceptionReason";
        NSString *const kExpectedUserInfo = @"{\n    TestKey = TestValue;\n}";

        beforeEach(^{
            [symbolicator stub:@selector(backtraceForInstructionAddresses:binaryImages:) withBlock:^id(NSArray *params) {
                NSArray *addresses = params[0];
                if (addresses == (id)[NSNull null] || addresses.count == 0) {
                    return nil;
                }
                [AMATestUtilities fillObjectPointerParameter:params[1] withValue:[NSSet setWithArray:binaryImages]];
                return backtrace;
            }];
            exception = nsExceptionMock(kExpectedExceptionName,
                                        kExpectedExceptionReason,
                                        @{ @"TestKey" : @"TestValue" },
                                        @((uintptr_t)&nsExceptionMock + 3));
            [formatter formattedException:exception error:NULL];
            decodedCrash = serializerSpy.argument;
        });

        it(@"Should use provided backtrace object name", ^{
            [[decodedCrash.crash.threads.firstObject.backtrace should] equal:backtrace];
        });

        it(@"Should use provided binary image", ^{
            [[decodedCrash.binaryImages should] containObjectsInArray:binaryImages];
        });
        
        it(@"Should use provided exception reason", ^{
            [[decodedCrash.crash.error.reason should] equal:kExpectedExceptionReason];
        });
        
        it(@"Should use provided exception name", ^{
            [[decodedCrash.crash.error.nsException.name should] equal:kExpectedExceptionName];
        });
        
        it(@"Should use provided exception userInfo", ^{
            [[decodedCrash.crash.error.nsException.userInfo should] equal:kExpectedUserInfo];
        });
        
        it(@"Should set mach exception to EXC_CRASH", ^{
            [[theValue(decodedCrash.crash.error.mach.exceptionType) should] equal:theValue(EXC_CRASH)];
        });
        
        it(@"Should set BSD signal to SIGABRT", ^{
            [[theValue(decodedCrash.crash.error.signal.signal) should] equal:theValue(SIGABRT)];
        });
        
        context(@"Failures", ^{
            it(@"Should set NSError when serialization fails", ^{
                NSError *serializationError = [NSError errorWithDomain:@"TestErrorDomain" code:123 userInfo:nil];
                [serializer stub:@selector(dataForCrash:error:) withBlock:^id(NSArray *params) {
                    NSError *__autoreleasing *error = NULL;
                    [((NSValue *)params[1]) getValue:&error];
                    *error = serializationError;
                    return nil;
                }];

                NSError *error = nil;
                NSData *result = [formatter formattedException:exception error:&error];

                [[result should] beNil];
                [[error should] equal:serializationError];
            });
            
            it(@"Should set NSError and return result", ^{
                NSError *serializationError = [NSError errorWithDomain:@"TestErrorDomain" code:123 userInfo:nil];
                NSData *sampleData = NSData.data;
                [serializer stub:@selector(dataForCrash:error:) withBlock:^id(NSArray *params) {
                    NSError *__autoreleasing *error = NULL;
                    [((NSValue *)params[1]) getValue:&error];
                    *error = serializationError;
                    return sampleData;
                }];

                NSError *error = nil;
                NSData *result = [formatter formattedException:exception error:&error];

                [[result should] equal:sampleData];
                [[error should] equal:serializationError];
            });
        });
    });

    context(@"Error", ^{
        AMABinaryImage *const firstBinaryImage = [AMABinaryImage nullMock];
        AMABinaryImage *const secondBinaryImage = [AMABinaryImage nullMock];
        AMABacktrace *const userBacktrace = [AMABacktrace nullMock];
        AMABacktrace *const reportCallBacktrace = [AMABacktrace nullMock];

        __block AMAErrorModel *underlyingError = nil;
        __block AMAErrorModel *errorModel = nil;
        __block AMAVirtualMachineError *virtualMachineError = nil;

        beforeEach(^{
            virtualMachineError = [[AMAVirtualMachineError alloc] initWithClassName:@"error class name"
                                                                            message:@"error message"];
            underlyingError =
                [[AMAErrorModel alloc] initWithType:AMAErrorModelTypeCustom
                                         customData:[[AMAErrorCustomData alloc] initWithIdentifier:@"UNDERLYING"
                                                                                           message:nil
                                                                                         className:nil]
                                        nsErrorData:nil
                                   parametersString:nil
                                reportCallBacktrace:nil
                              userProvidedBacktrace:nil
                                virtualMachineError:nil
                                    underlyingError:nil
                                     bytesTruncated:0];
            errorModel =
                [[AMAErrorModel alloc] initWithType:AMAErrorModelTypeCustom
                                         customData:[[AMAErrorCustomData alloc] initWithIdentifier:@"IDENTIFIER"
                                                                                           message:@"MESSAGE"
                                                                                         className:@"AMAMyClass"]
                                        nsErrorData:nil
                                   parametersString:@"{\"foo\":\"bar\"}"
                                reportCallBacktrace:@[ @1 ]
                              userProvidedBacktrace:@[ @2 ]
                                virtualMachineError:virtualMachineError
                                    underlyingError:underlyingError
                                     bytesTruncated:23];
            [symbolicator stub:@selector(backtraceForInstructionAddresses:binaryImages:) withBlock:^id(NSArray *params) {
                NSArray *addresses = params[0];
                if (addresses == (id)[NSNull null] || addresses.count == 0) {
                    return nil;
                }
                AMABacktrace *backtrace = nil;
                if ([addresses.firstObject isEqual:@1]) {
                    backtrace = reportCallBacktrace;
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:[NSSet setWithObject:firstBinaryImage]];
                }
                else {
                    backtrace = userBacktrace;
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:[NSSet setWithArray:@[
                        firstBinaryImage,
                        secondBinaryImage,
                    ]]];
                }
                return backtrace;
            }];
            [formatter formattedError:errorModel error:NULL];
            decodedCrash = serializerSpy.argument;
        });

        it(@"Should have 2 non fatals in chain", ^{
            [[decodedCrash.crash.error.nonFatalsChain should] haveCountOf:2];
        });

        it(@"Should have valid thread backtrace", ^{
            [[decodedCrash.crash.threads.firstObject.backtrace should] equal:reportCallBacktrace];
        });

        context(@"First Non Fatal", ^{
            AMANonFatal *__block nonFatal = nil;
            beforeEach(^{
                nonFatal = decodedCrash.crash.error.nonFatalsChain.firstObject;
            });

            it(@"Should be non-nil", ^{
                [[nonFatal shouldNot] beNil];
            });

            it(@"Should have valid model", ^{
                [[nonFatal.model should] equal:errorModel];
            });

            it(@"Should have valid backtrace", ^{
                [[nonFatal.backtrace should] equal:userBacktrace];
            });
        });

        context(@"Second Non Fatal", ^{
            AMANonFatal *__block nonFatal = nil;
            beforeEach(^{
                nonFatal = decodedCrash.crash.error.nonFatalsChain.lastObject;
            });

            it(@"Should be non-nil", ^{
                [[nonFatal shouldNot] beNil];
            });

            it(@"Should have valid model", ^{
                [[nonFatal.model should] equal:underlyingError];
            });

            it(@"Should have no backtrace", ^{
                [[nonFatal.backtrace should] beNil];
            });
        });

        context(@"Binary images", ^{
            it(@"Should have 2 images", ^{
                [[decodedCrash.binaryImages should] haveCountOf:2];
            });

            it(@"Should have valid binary images", ^{
                [[decodedCrash.binaryImages should] containObjectsInArray:@[ firstBinaryImage, secondBinaryImage ]];
            });
        });
        
        context(@"Failures", ^{
            it(@"Should set NSError when serialization fails", ^{
                NSError *serializationError = [NSError errorWithDomain:@"TestErrorDomain" code:123 userInfo:nil];
                [serializer stub:@selector(dataForCrash:error:) withBlock:^id(NSArray *params) {
                    NSError *__autoreleasing *error = NULL;
                    [((NSValue *)params[1]) getValue:&error];
                    *error = serializationError;
                    return nil;
                }];

                NSError *error = nil;
                NSData *result = [formatter formattedError:errorModel error:&error];

                [[result should] beNil];
                [[error should] equal:serializationError];
            });
            
            it(@"Should set NSError and return result", ^{
                NSError *serializationError = [NSError errorWithDomain:@"TestErrorDomain" code:123 userInfo:nil];
                NSData *sampleData = NSData.data;
                [serializer stub:@selector(dataForCrash:error:) withBlock:^id(NSArray *params) {
                    NSError *__autoreleasing *error = NULL;
                    [((NSValue *)params[1]) getValue:&error];
                    *error = serializationError;
                    return sampleData;
                }];

                NSError *error = nil;
                NSData *result = [formatter formattedError:errorModel error:&error];

                [[result should] equal:sampleData];
                [[error should] equal:serializationError];
            });
        });
    });

    context(@"Plugin error details", ^{
        NSUInteger __block bytesTruncated = 0;
        AMAErrorModel *__block defaultErrorModel = nil;
        AMAErrorModel *__block customErrorModel = nil;
        AMAErrorModelFactory *__block errorModelFactory = nil;
        AMACrashObjectsFactory *__block crashObjectsFactory = nil;
        beforeEach(^{
            bytesTruncated = 0;
            errorModelFactory = [AMAErrorModelFactory nullMock];
            crashObjectsFactory = [AMACrashObjectsFactory nullMock];
            [AMAErrorModelFactory stub:@selector(sharedInstance) andReturn:errorModelFactory];
            [AMACrashObjectsFactory stub:@selector(sharedInstance) andReturn:crashObjectsFactory];
            defaultErrorModel = [AMAErrorModel nullMock];
            customErrorModel = [AMAErrorModel nullMock];
            [errorModelFactory stub:@selector(defaultModelForErrorDetails:bytesTruncated:) andReturn:defaultErrorModel];
            [errorModelFactory stub:@selector(customModelForErrorDetails:identifier:bytesTruncated:) andReturn:customErrorModel];
        });
        context(@"Filled objects", ^{
            AMAVirtualMachineInfo *__block virtualMachineInfo = nil;
            AMAVirtualMachineCrash *__block virtualMachineCrash = nil;
            AMABacktrace *__block backtrace = nil;
            NSString *exceptionClass = @"my class";
            NSString *message = @"my message";
            NSString *platform = @"unity";
            NSString *virtualMachineVersion = @"4.5.6";
            NSDictionary *environment = @{ @"some key" : @"some value", @"another key" : @"another value" };
            NSString *className1 = @"AMAExceptionFormatter";
            NSString *className2 = @"AMAExceptionSerializer";
            NSString *fileName1 = @"AMAExceptionFormatter.m";
            NSString *fileName2 = @"AMAExceptionSerializer.m";
            NSString *methodName1 = @"format";
            NSString *methodName2 = @"serialize";
            NSNumber *line1 = @23;
            NSNumber *line2 = @45;
            NSNumber *column1 = @99;
            NSNumber *column2 = @88;

            NSArray *inputBacktrace = @[
                [[AMAStackTraceElement alloc] initWithClassName:className1
                                                       fileName:fileName1
                                                           line:line1
                                                         column:column1
                                                     methodName:methodName1],
                [[AMAStackTraceElement alloc] initWithClassName:className2
                                                       fileName:fileName2
                                                           line:line2
                                                         column:column2
                                                     methodName:methodName2]
            ];
            AMAPluginErrorDetails *errorDetails = [[AMAPluginErrorDetails alloc] initWithExceptionClass:exceptionClass
                                                                                                message:message
                                                                                              backtrace:inputBacktrace
                                                                                               platform:platform
                                                                                  virtualMachineVersion:virtualMachineVersion
                                                                                      pluginEnvironment:environment];
            __auto_type commonChecksBlock = ^void(AMADecodedCrash * crash) {
                context(@"Binary images", ^{
                    it(@"Should be empty", ^{
                        [[theValue(decodedCrash.binaryImages.count) should] beZero];
                    });
                });
                context(@"Info", ^{
                    it(@"Should fill version", ^{
                        [[decodedCrash.info.version should] equal:@"3.2.0"];
                    });
                    it(@"Should fill identifier", ^{
                        [[theValue(decodedCrash.info.identifier.length) should] beGreaterThan:theValue(0)];
                    });
                    it(@"Should fill date", ^{
                        [[decodedCrash.info.timestamp should] equal:dateProvider.currentDate];
                    });
                    it(@"Should fill virtual machine info", ^{
                        [[decodedCrash.info.virtualMachineInfo should] equal:virtualMachineInfo];
                    });
                });
                context(@"System", ^{
                    it(@"Should fill system", ^{
                        [[decodedCrash.system should] equal:systemInfo];
                    });
                });
                context(@"App BuildUID", ^{
                    it(@"Should not fill app BuildUID", ^{
                        [[decodedCrash.appBuildUID should] beNil];
                    });
                });
                context(@"App environment", ^{
                    it(@"Should not fill app environment", ^{
                        [[decodedCrash.appEnvironment should] beNil];
                    });
                });
                context(@"Error environment", ^{
                    it(@"Should not fill error environment", ^{
                        [[decodedCrash.errorEnvironment should] beNil];
                    });
                });
                context(@"App state", ^{
                    it(@"Should not fill app state", ^{
                        [[decodedCrash.appState should] beNil];
                    });
                });
                context(@"Crash", ^{
                    context(@"Error", ^{
                        AMACrashReportError *__block error = nil;
                        beforeEach(^{
                            error = decodedCrash.crash.error;
                        });
                        it(@"Should have zero address", ^{
                            [[theValue(error.address) should] beZero];
                        });
                        it(@"Should have nil mach", ^{
                            [[error.mach should] beNil];
                        });
                        it(@"Should have nil signal", ^{
                            [[error.signal should] beNil];
                        });
                        it(@"Should have nil cpp exception", ^{
                            [[error.cppException should] beNil];
                        });
                        it(@"Should have nil ns exception", ^{
                            [[error.nsException should] beNil];
                        });
                        it(@"Should not have reason", ^{
                            [[theValue(error.reason.length) should] beZero];
                        });
                    });
                });

            };
            beforeEach(^{
                virtualMachineInfo = [AMAVirtualMachineInfo nullMock];
                virtualMachineCrash = [AMAVirtualMachineCrash nullMock];
                backtrace = [AMABacktrace nullMock];

                [crashObjectsFactory stub:@selector(virtualMachineInfoForErrorDetails:bytesTruncated:)
                                andReturn:virtualMachineInfo
                            withArguments:errorDetails, kw_any()];
                [crashObjectsFactory stub:@selector(virtualMachineCrashForErrorDetails:bytesTruncated:)
                                andReturn:virtualMachineCrash
                            withArguments:errorDetails, kw_any()];
                [crashObjectsFactory stub:@selector(backtraceFrom:bytesTruncated:)
                                andReturn:backtrace
                            withArguments:inputBacktrace, kw_any()];
            });
            context(@"Format crash", ^{
                beforeEach(^{
                    [formatter formattedCrashErrorDetails:errorDetails bytesTruncated:NULL error:NULL];
                    decodedCrash = serializerSpy.argument;
                });

                context(@"Common checks", ^{
                    commonChecksBlock(decodedCrash);
                });
                it(@"Should use correct arguments", ^{
                    [[crashObjectsFactory should] receive:@selector(virtualMachineCrashForErrorDetails:bytesTruncated:)
                                            withArguments:errorDetails, theValue(&bytesTruncated)];
                    [[crashObjectsFactory should] receive:@selector(virtualMachineInfoForErrorDetails:bytesTruncated:)
                                            withArguments:errorDetails, theValue(&bytesTruncated)];
                    [[crashObjectsFactory should] receive:@selector(backtraceFrom:bytesTruncated:)
                                            withArguments:inputBacktrace, theValue(&bytesTruncated)];
                    [formatter formattedCrashErrorDetails:errorDetails bytesTruncated:&bytesTruncated error:NULL];
                });
                it(@"Should have correct backtrace", ^{
                    [[decodedCrash.crashedThreadBacktrace should] equal:backtrace];
                });
                context(@"Crash", ^{
                    context(@"Threads", ^{
                        it(@"Should have one thread", ^{
                            [[theValue(decodedCrash.crash.threads.count) should] equal:theValue(1)];
                        });
                        context(@"Thread", ^{
                            AMAThread *__block thread = nil;
                            beforeEach(^{
                                thread = decodedCrash.crash.threads[0];
                            });
                            it(@"Should have valid backtrace", ^{
                                [[thread.backtrace should] equal:backtrace];
                            });
                            it(@"Should be crashed", ^{
                                [[theValue(thread.crashed) should] beYes];
                            });
                            it(@"Should have zero index", ^{
                                [[theValue(thread.index) should] beZero];
                            });
                            it(@"Should not have queue name", ^{
                                [[thread.queueName should] beNil];
                            });
                            it(@"Should not have registers", ^{
                                [[thread.registers should] beNil];
                            });
                            it(@"Should not have stack", ^{
                                [[thread.stack should] beNil];
                            });
                            it(@"Should not thread name", ^{
                                [[thread.threadName should] beNil];
                            });
                        });
                    });
                    context(@"Error", ^{
                        AMACrashReportError *__block error = nil;
                        beforeEach(^{
                            error = decodedCrash.crash.error;
                        });
                        it(@"Should not have non fatals", ^{
                            [[theValue(error.nonFatalsChain.count) should] beZero];
                        });
                        it(@"Should have valid type", ^{
                            [[theValue(error.type) should] equal:theValue(AMACrashTypeVirtualMachineCrash)];
                        });
                        it(@"Should have valid virtual machine crash", ^{
                            [[error.virtualMachineCrash should] equal:virtualMachineCrash];
                        });
                    });
                });
            });
            context(@"Format error", ^{
                __auto_type commonErrorChecksBlock = ^void(AMADecodedCrash *crash) {
                    it(@"Should not have crashed thread backtrace", ^{
                        [[crash.crashedThreadBacktrace should] beNil];
                    });
                    context(@"Crash", ^{
                        it(@"Should not have threads", ^{
                            [[theValue(crash.crash.threads.count) should] beZero];
                        });
                        context(@"Error", ^{
                            AMACrashReportError *__block error = nil;
                            beforeEach(^{
                                error = decodedCrash.crash.error;
                            });
                            it(@"Should not have virtual machine crash", ^{
                                [[error.virtualMachineCrash should] beNil];
                            });
                            context(@"Non fatals", ^{
                                it(@"Should have 1 non fatal", ^{
                                    [[theValue(error.nonFatalsChain.count) should] equal:theValue(1)];
                                });
                                context(@"Non fatal", ^{
                                    AMANonFatal *__block nonFatal = nil;
                                    beforeEach(^{
                                        nonFatal = error.nonFatalsChain[0];
                                    });
                                    it(@"Should have valid backtrace", ^{
                                        [[nonFatal.backtrace should] equal:backtrace];
                                    });
                                    context(@"Error model", ^{
                                        AMAErrorModel *__block model = nil;
                                        beforeEach(^{
                                            model = nonFatal.model;
                                        });
                                        it(@"Should not have bytes truncated", ^{
                                            [[theValue(model.bytesTruncated) should] beZero];
                                        });
                                        it(@"Should not have ns error data", ^{
                                            [[model.nsErrorData should] beNil];
                                        });
                                        it(@"Should not have parameters", ^{
                                            [[theValue(model.parametersString.length) should] beZero];
                                        });
                                        it(@"Should not have report call backtrace", ^{
                                            [[model.reportCallBacktrace should] beNil];
                                        });
                                        it(@"Should not have underlying error", ^{
                                            [[model.underlyingError should] beNil];
                                        });
                                        it(@"Should not have user provided backtrace", ^{
                                            [[model.userProvidedBacktrace should] beNil];
                                        });
                                    });
                                });
                            });
                        });
                    });
                    context(@"Failures", ^{
                        it(@"Should set NSError when serialization fails", ^{
                            NSError *serializationError = [NSError errorWithDomain:@"TestErrorDomain" code:123 userInfo:nil];
                            [serializer stub:@selector(dataForCrash:error:) withBlock:^id(NSArray *params) {
                                NSError *__autoreleasing *error = NULL;
                                [((NSValue *)params[1]) getValue:&error];
                                *error = serializationError;
                                return nil;
                            }];
                            
                            NSError *error = nil;
                            NSData *result = [formatter formattedCrashErrorDetails:errorDetails
                                                                    bytesTruncated:NULL error:&error];
                            
                            [[result should] beNil];
                            [[error should] equal:serializationError];
                        });
                        
                        it(@"Should set NSError and return result", ^{
                            NSError *serializationError = [NSError errorWithDomain:@"TestErrorDomain" code:123 userInfo:nil];
                            NSData *sampleData = NSData.data;
                            [serializer stub:@selector(dataForCrash:error:) withBlock:^id(NSArray *params) {
                                NSError *__autoreleasing *error = NULL;
                                [((NSValue *)params[1]) getValue:&error];
                                *error = serializationError;
                                return sampleData;
                            }];
                            
                            NSError *error = nil;
                            NSData *result = [formatter formattedCrashErrorDetails:errorDetails
                                                                    bytesTruncated:NULL error:&error];
                            
                            [[result should] equal:sampleData];
                            [[error should] equal:serializationError];
                        });
                    });
                };
                context(@"Format default error", ^{
                    beforeEach(^{
                        [formatter formattedErrorErrorDetails:errorDetails bytesTruncated:NULL error:NULL];
                        decodedCrash = serializerSpy.argument;
                    });
                    context(@"Common checks", ^{
                        commonChecksBlock(decodedCrash);
                    });
                    context(@"Common error checks", ^{
                        commonErrorChecksBlock(decodedCrash);
                    });
                    it(@"Should use correct arguments", ^{
                        [[crashObjectsFactory should] receive:@selector(virtualMachineInfoForErrorDetails:bytesTruncated:)
                                                withArguments:errorDetails, theValue(&bytesTruncated)];
                        [[crashObjectsFactory should] receive:@selector(backtraceFrom:bytesTruncated:)
                                                withArguments:inputBacktrace, theValue(&bytesTruncated)];
                        [formatter formattedErrorErrorDetails:errorDetails bytesTruncated:&bytesTruncated error:NULL];
                    });
                    context(@"Crash", ^{
                        AMACrashReportError *__block reportError = nil;
                        beforeEach(^{
                            reportError = decodedCrash.crash.error;
                        });
                        context(@"Error", ^{
                            it(@"Should have valid type", ^{
                                [[theValue(reportError.type) should] equal:theValue(AMACrashTypeVirtualMachineError)];
                            });
                            context(@"Non fatals", ^{
                                context(@"Non fatal", ^{
                                    it(@"Should have valid error model", ^{
                                        [[reportError.nonFatalsChain[0].model should] equal:defaultErrorModel];
                                    });
                                    it(@"Should use correct arguments", ^{
                                        [[errorModelFactory should] receive:@selector(defaultModelForErrorDetails:bytesTruncated:)
                                                              withArguments:errorDetails, theValue(&bytesTruncated)];
                                        [formatter formattedErrorErrorDetails:errorDetails
                                                               bytesTruncated:&bytesTruncated error:NULL];
                                    });
                                });
                            });
                        });
                    });
                    context(@"Failures", ^{
                        it(@"Should set NSError when serialization fails", ^{
                            NSError *serializationError = [NSError errorWithDomain:@"TestErrorDomain" code:123 userInfo:nil];
                            [serializer stub:@selector(dataForCrash:error:) withBlock:^id(NSArray *params) {
                                NSError *__autoreleasing *error = NULL;
                                [((NSValue *)params[1]) getValue:&error];
                                *error = serializationError;
                                return nil;
                            }];
                            
                            NSError *error = nil;
                            NSData *result = [formatter formattedErrorErrorDetails:errorDetails
                                                                    bytesTruncated:NULL error:&error];
                            
                            [[result should] beNil];
                            [[error should] equal:serializationError];
                        });
                        
                        it(@"Should set NSError and return result", ^{
                            NSError *serializationError = [NSError errorWithDomain:@"TestErrorDomain" code:123 userInfo:nil];
                            NSData *sampleData = NSData.data;
                            [serializer stub:@selector(dataForCrash:error:) withBlock:^id(NSArray *params) {
                                NSError *__autoreleasing *error = NULL;
                                [((NSValue *)params[1]) getValue:&error];
                                *error = serializationError;
                                return sampleData;
                            }];
                            
                            NSError *error = nil;
                            NSData *result = [formatter formattedErrorErrorDetails:errorDetails
                                                                    bytesTruncated:NULL error:&error];
                            
                            [[result should] equal:sampleData];
                            [[error should] equal:serializationError];
                        });
                    });
                });
                context(@"Format custom error", ^{
                    NSString *const identifier = @"555-666";
                    beforeEach(^{
                        [formatter formattedCustomErrorErrorDetails:errorDetails identifier:identifier 
                                                     bytesTruncated:NULL error:NULL];
                        decodedCrash = serializerSpy.argument;
                    });
                    context(@"Common checks", ^{
                        commonChecksBlock(decodedCrash);
                    });
                    context(@"Common error checks", ^{
                        commonErrorChecksBlock(decodedCrash);
                    });
                    it(@"Should use correct arguments", ^{
                        [[crashObjectsFactory should] receive:@selector(virtualMachineInfoForErrorDetails:bytesTruncated:)
                                                withArguments:errorDetails, theValue(&bytesTruncated)];
                        [[crashObjectsFactory should] receive:@selector(backtraceFrom:bytesTruncated:)
                                                withArguments:inputBacktrace, theValue(&bytesTruncated)];
                        [formatter formattedCustomErrorErrorDetails:errorDetails
                                                         identifier:identifier
                                                     bytesTruncated:&bytesTruncated
                                                              error:NULL];
                    });
                    context(@"Crash", ^{
                        AMACrashReportError *__block reportError = nil;
                        beforeEach(^{
                            reportError = decodedCrash.crash.error;
                        });
                        context(@"Error", ^{
                            it(@"Should have valid type", ^{
                                [[theValue(reportError.type) should] equal:theValue(AMACrashTypeVirtualMachineCustomError)];
                            });
                            context(@"Non fatals", ^{
                                context(@"Non fatal", ^{
                                    it(@"Should have valid error model", ^{
                                        [[reportError.nonFatalsChain[0].model should] equal:customErrorModel];
                                    });
                                    it(@"Should use correct arguments", ^{
                                        [[errorModelFactory should] receive:@selector(customModelForErrorDetails:identifier:bytesTruncated:)
                                                              withArguments:errorDetails, identifier, theValue(&bytesTruncated)];
                                        [formatter formattedCustomErrorErrorDetails:errorDetails identifier:identifier
                                                                     bytesTruncated:&bytesTruncated error:NULL];
                                    });
                                });
                            });
                        });
                    });
                    context(@"Failures", ^{
                        it(@"Should set NSError when serialization fails", ^{
                            NSError *serializationError = [NSError errorWithDomain:@"TestErrorDomain" code:123 userInfo:nil];
                            [serializer stub:@selector(dataForCrash:error:) withBlock:^id(NSArray *params) {
                                NSError *__autoreleasing *error = NULL;
                                [((NSValue *)params[1]) getValue:&error];
                                *error = serializationError;
                                return nil;
                            }];
                            
                            NSError *error = nil;
                            NSData *result = [formatter formattedCustomErrorErrorDetails:errorDetails
                                                                              identifier:identifier
                                                                          bytesTruncated:NULL
                                                                                   error:&error];
                            
                            [[result should] beNil];
                            [[error should] equal:serializationError];
                        });
                        
                        it(@"Should set NSError and return result", ^{
                            NSError *serializationError = [NSError errorWithDomain:@"TestErrorDomain" code:123 userInfo:nil];
                            NSData *sampleData = NSData.data;
                            [serializer stub:@selector(dataForCrash:error:) withBlock:^id(NSArray *params) {
                                NSError *__autoreleasing *error = NULL;
                                [((NSValue *)params[1]) getValue:&error];
                                *error = serializationError;
                                return sampleData;
                            }];
                            
                            NSError *error = nil;
                            NSData *result = [formatter formattedCustomErrorErrorDetails:errorDetails
                                                                              identifier:identifier
                                                                          bytesTruncated:NULL
                                                                                   error:&error];;
                            
                            [[result should] equal:sampleData];
                            [[error should] equal:serializationError];
                        });
                    });
                });
            });
        });
        context(@"Nullable objects", ^{
            beforeEach(^{
                [crashObjectsFactory stub:@selector(virtualMachineInfoForErrorDetails:bytesTruncated:) andReturn:nil];
                [crashObjectsFactory stub:@selector(virtualMachineCrashForErrorDetails:bytesTruncated:) andReturn:nil];
                [crashObjectsFactory stub:@selector(backtraceFrom:bytesTruncated:) andReturn:nil];
            });
            __auto_type commonChecksBlock = ^void(AMADecodedCrash * crash) {
                context(@"Binary images", ^{
                    it(@"Should be empty", ^{
                        [[theValue(decodedCrash.binaryImages.count) should] beZero];
                    });
                });
                context(@"Info", ^{
                    it(@"Should fill version", ^{
                        [[decodedCrash.info.version should] equal:@"3.2.0"];
                    });
                    it(@"Should fill identifier", ^{
                        [[theValue(decodedCrash.info.identifier.length) should] beGreaterThan:theValue(0)];
                    });
                    it(@"Should fill date", ^{
                        [[decodedCrash.info.timestamp should] equal:dateProvider.currentDate];
                    });
                    it(@"Should not fill virtual machine info", ^{
                        [[decodedCrash.info.virtualMachineInfo should] beNil];
                    });
                });
                context(@"Error", ^{
                    it(@"Should not have crashed thread backtrace", ^{
                        [[crash.crashedThreadBacktrace should] beNil];
                    });
                    context(@"Crash", ^{
                        it(@"Should not have threads", ^{
                            [[theValue(crash.crash.threads.count) should] beZero];
                        });
                        context(@"Error", ^{
                            AMACrashReportError *__block error = nil;
                            beforeEach(^{
                                error = decodedCrash.crash.error;
                            });
                            it(@"Should not have virtual machine crash", ^{
                                [[error.virtualMachineCrash should] beNil];
                            });
                            context(@"Non fatals", ^{
                                it(@"Should have 1 non fatal", ^{
                                    [[theValue(error.nonFatalsChain.count) should] equal:theValue(1)];
                                });
                                context(@"Non fatal", ^{
                                    AMANonFatal *__block nonFatal = nil;
                                    beforeEach(^{
                                        nonFatal = error.nonFatalsChain[0];
                                    });
                                    it(@"Should not have correct size", ^{
                                        [[theValue(nonFatal.backtrace.frames.count) should] equal:theValue(0)];
                                    });
                                    context(@"Error model", ^{
                                        AMAErrorModel *__block model = nil;
                                        beforeEach(^{
                                            model = nonFatal.model;
                                        });
                                        it(@"Should not have bytes truncated", ^{
                                            [[theValue(model.bytesTruncated) should] beZero];
                                        });
                                        it(@"Should not have ns error data", ^{
                                            [[model.nsErrorData should] beNil];
                                        });
                                        it(@"Should not have parameters", ^{
                                            [[theValue(model.parametersString.length) should] beZero];
                                        });
                                        it(@"Should not have report call backtrace", ^{
                                            [[model.reportCallBacktrace should] beNil];
                                        });
                                        it(@"Should not have underlying error", ^{
                                            [[model.underlyingError should] beNil];
                                        });
                                        it(@"Should not have user provided backtrace", ^{
                                            [[model.userProvidedBacktrace should] beNil];
                                        });
                                    });
                                });
                            });
                        });
                    });
                });

            };
            context(@"Format default error", ^{
                
                __block NSError *error = nil;
                
                beforeEach(^{
                    [formatter formattedErrorErrorDetails:nil bytesTruncated:NULL error:&error];
                    decodedCrash = serializerSpy.argument;
                });
                context(@"Common checks", ^{
                    commonChecksBlock(decodedCrash);
                });
                it(@"Should use correct arguments", ^{
                    [[crashObjectsFactory should] receive:@selector(virtualMachineInfoForErrorDetails:bytesTruncated:)
                                            withArguments:nil, theValue(&bytesTruncated)];
                    [[crashObjectsFactory should] receive:@selector(backtraceFrom:bytesTruncated:)
                                            withArguments:nil, theValue(&bytesTruncated)];
                    [formatter formattedErrorErrorDetails:nil bytesTruncated:&bytesTruncated error:&error];
                });
                context(@"Crash", ^{
                    AMACrashReportError *__block reportError = nil;
                    beforeEach(^{
                        error = nil;
                        reportError = decodedCrash.crash.error;
                    });
                    context(@"Error", ^{
                        it(@"Should have valid type", ^{
                            [[theValue(reportError.type) should] equal:theValue(AMACrashTypeVirtualMachineError)];
                        });
                        context(@"Non fatals", ^{
                            context(@"Non fatal", ^{
                                it(@"Should have valid error model", ^{
                                    [[reportError.nonFatalsChain[0].model should] equal:defaultErrorModel];
                                });
                                it(@"Should use correct arguments", ^{
                                    [[errorModelFactory should] receive:@selector(defaultModelForErrorDetails:bytesTruncated:)
                                                          withArguments:nil, theValue(&bytesTruncated)];
                                    [formatter formattedErrorErrorDetails:nil
                                                           bytesTruncated:&bytesTruncated error:&error];
                                });
                            });
                        });
                    });
                });
            });
            context(@"Format custom error", ^{
                NSString *identifier = @"333-444";
                
                __block NSError *error = nil;
                
                beforeEach(^{
                    [formatter formattedCustomErrorErrorDetails:nil identifier:identifier
                                                 bytesTruncated:NULL error:&error];
                    decodedCrash = serializerSpy.argument;
                });
                context(@"Common checks", ^{
                    commonChecksBlock(decodedCrash);
                });
                it(@"Should use correct arguments", ^{
                    [[crashObjectsFactory should] receive:@selector(virtualMachineInfoForErrorDetails:bytesTruncated:)
                                            withArguments:nil, theValue(&bytesTruncated)];
                    [[crashObjectsFactory should] receive:@selector(backtraceFrom:bytesTruncated:)
                                            withArguments:nil, theValue(&bytesTruncated)];
                    [formatter formattedCustomErrorErrorDetails:nil identifier:identifier
                                                 bytesTruncated:&bytesTruncated error:&error];
                });
                context(@"Crash", ^{
                    __block AMACrashReportError *reportError = nil;
                    __block NSError *error = nil;
                    beforeEach(^{
                        error = nil;
                        reportError = decodedCrash.crash.error;
                    });
                    context(@"Error", ^{
                        it(@"Should have valid type", ^{
                            [[theValue(reportError.type) should] equal:theValue(AMACrashTypeVirtualMachineCustomError)];
                        });
                        context(@"Non fatals", ^{
                            context(@"Non fatal", ^{
                                it(@"Should have valid error model", ^{
                                    [[reportError.nonFatalsChain[0].model should] equal:customErrorModel];
                                });
                                it(@"Should use correct arguments", ^{
                                    [[errorModelFactory should] receive:@selector(customModelForErrorDetails:identifier:bytesTruncated:)
                                                          withArguments:nil, identifier, theValue(&bytesTruncated)];
                                    [formatter formattedCustomErrorErrorDetails:nil identifier:identifier 
                                                                 bytesTruncated:&bytesTruncated error:&error];
                                });
                            });
                        });
                    });
                });
            });
        });
    });

});

SPEC_END
