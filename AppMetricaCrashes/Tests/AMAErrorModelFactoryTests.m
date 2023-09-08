
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAErrorModelFactory.h"
#import "AMAErrorRepresentable.h"
#import "AMAError.h"
#import "AMAErrorCustomData.h"
#import "AMAErrorNSErrorData.h"
#import "AMAErrorModel.h"
#import "AMAVirtualMachineError.h"
#import "AMAPluginErrorDetails.h"

#include <execinfo.h>

static AMAErrorModel *amaModelForNSError(AMAErrorModelFactory *factory,
                                         NSError *error,
                                         AMAErrorReportingOptions options)
{
    return [factory modelForNSError:error options:options];
}

static AMAErrorModel *amaModelForErrorRepresentable(AMAErrorModelFactory *factory,
                                                    id<AMAErrorRepresentable> error,
                                                    AMAErrorReportingOptions options)
{
    return [factory modelForErrorRepresentable:error options:options];
}

@interface AMATestMinimalError: NSObject <AMAErrorRepresentable>

@property (nonatomic, copy) NSString *identifier;

@end

@implementation AMATestMinimalError

@end

SPEC_BEGIN(AMAErrorModelFactoryTests)

describe(@"AMAErrorModelFactory", ^{
    NSDictionary *const parameters = @{
        @"foo": @"bar",
        @"non-serializable": [NSDate dateWithTimeIntervalSince1970:23.0],
        @[@"arr"]: @{@"a": @"b"},
    };

    AMAErrorModel *__block model = nil;
    AMAErrorModelFactory *__block factory = nil;

    __auto_type symbolicate = ^NSArray<NSString *> *(NSArray<NSNumber *> *backtrace) {
        NSMutableArray *backtraceSymbols = [NSMutableArray array];
        for (NSNumber *address in backtrace) {
            void *ptr = (void *)address.unsignedLongLongValue;
            char **str = backtrace_symbols(&ptr, 1);
            NSString *line = [NSString stringWithUTF8String:*str];
            free(str);
            [backtraceSymbols addObject:line];
        }
        return [backtraceSymbols copy];
    };
    __auto_type parseParameters = ^NSDictionary *(void) {
        NSData *data = [model.parametersString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *parameters = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:0
                                                                     error:NULL];
        return parameters;
    };

    beforeEach(^{
        model = nil;
        factory = [[AMAErrorModelFactory alloc] init];
    });

    context(@"AMAError", ^{

        NSDictionary *const expectedParameters = @{
            @"foo": @"bar",
            @"non-serializable": @"1970-01-01 00:00:23 +0000",
            @"(\n    arr\n)": @"{\n    a = b;\n}",
        };

        AMAError *__block error = nil;

        beforeEach(^{
            AMAError *underlyingError = [AMAError errorWithIdentifier:@"UNDERLYING_ERROR"];

            error = [AMAError errorWithIdentifier:@"IDENTIFIER"
                                          message:@"MESSAGE"
                                       parameters:parameters
                                        backtrace:@[ @1, @2, @3 ]
                                  underlyingError:underlyingError];
        });

        context(@"No options", ^{
            beforeEach(^{
                model = amaModelForErrorRepresentable(factory, error, 0);
            });

            it(@"Should have valid type", ^{
                [[theValue(model.type) should] equal:theValue(AMAErrorModelTypeCustom)];
            });
            context(@"Custom Data", ^{
                it(@"Should have valid id", ^{
                    [[model.customData.identifier should] equal:error.identifier];
                });
                it(@"Should have valid message", ^{
                    [[model.customData.message should] equal:error.message];
                });
            });
            it(@"Should have nil NSError data", ^{
                [[model.nsErrorData should] beNil];
            });
            it(@"Should have valid parameters", ^{
                [[parseParameters() should] equal:expectedParameters];
            });
            it(@"Should have valid user provided backtrace", ^{
                [[model.userProvidedBacktrace should] equal:error.backtrace];
            });
            it(@"Should have valid function as first frame in report call backtrace", ^{
                [[symbolicate(model.reportCallBacktrace).firstObject should] containString:@"amaModelForErrorRepresentable"];
            });
            it(@"Should not have virtual machine error", ^{
                [[model.virtualMachineError should] beNil];
            });
            context(@"Underlying", ^{
                it(@"Should have valid id", ^{
                    [[model.underlyingError.customData.identifier should] equal:error.underlyingError.identifier];
                });
                it(@"Should have nil user provided backtrace", ^{
                    [[model.underlyingError.userProvidedBacktrace should] beNil];
                });
                it(@"Should have nil report call backtrace", ^{
                    [[model.underlyingError.reportCallBacktrace should] beNil];
                });
                it (@"Should not have virtual machine error", ^{
                    [[model.underlyingError.virtualMachineError should] beNil];
                });
            });
        });

        context(@"No backtrace", ^{
            beforeEach(^{
                model = amaModelForErrorRepresentable(factory, error, AMAErrorReportingOptionsNoBacktrace);
            });

            it(@"Should have valid type", ^{
                [[theValue(model.type) should] equal:theValue(AMAErrorModelTypeCustom)];
            });
            it(@"Should have valid id", ^{
                [[model.customData.identifier should] equal:error.identifier];
            });
            it(@"Should have valid user provided backtrace", ^{
                [[model.userProvidedBacktrace should] equal:error.backtrace];
            });
            it(@"Should have nil report call backtrace", ^{
                [[model.reportCallBacktrace should] beNil];
            });
            it (@"Should not have virtual machine error", ^{
                [[model.virtualMachineError should] beNil];
            });
            context(@"Underlying", ^{
                it(@"Should have valid id", ^{
                    [[model.underlyingError.customData.identifier should] equal:error.underlyingError.identifier];
                });
                it(@"Should have nil user provided backtrace", ^{
                    [[model.underlyingError.userProvidedBacktrace should] beNil];
                });
                it(@"Should have nil report call backtrace", ^{
                    [[model.underlyingError.reportCallBacktrace should] beNil];
                });
                it (@"Should not have virtual machine error", ^{
                    [[model.underlyingError.virtualMachineError should] beNil];
                });
            });
        });

        context(@"Invalid custom backtrace", ^{
            beforeEach(^{
                [error stub:@selector(backtrace) andReturn:@[ @1, @2, @"string" ]];
                model = amaModelForErrorRepresentable(factory, error, 0);
            });
            it(@"Should have valid type", ^{
                [[theValue(model.type) should] equal:theValue(AMAErrorModelTypeCustom)];
            });
            it(@"Should have valid id", ^{
                [[model.customData.identifier should] equal:error.identifier];
            });
            it(@"Should have no user provided backtrace", ^{
                [[model.userProvidedBacktrace should] beNil];
            });
            it (@"Should not have virtual machine error", ^{
                [[model.virtualMachineError should] beNil];
            });
        });
    });

    context(@"NSError", ^{

        NSDictionary *const expectedParameters = @{
            @"foo": @"bar",
            @"non-serializable": @"1970-01-01 00:00:23 +0000",
            @"(\n    arr\n)": @"{\n    a = b;\n}",
            @"NSLocalizedDescription": @"DESCRIPTION",
        };

        NSError *__block underlyingError = nil;
        NSError *__block error = nil;

        beforeEach(^{
            underlyingError = [NSError errorWithDomain:@"UNDERLYING_ERROR_DOMAIN" code:42 userInfo:nil];

            NSMutableDictionary *userInfo = [parameters mutableCopy];
            userInfo[NSLocalizedDescriptionKey] = @"DESCRIPTION";
            userInfo[NSUnderlyingErrorKey] = underlyingError;
            userInfo[AMABacktraceErrorKey] = @[ @1, @2, @3 ];
            error = [NSError errorWithDomain:@"ERROR_DOMAIN" code:23 userInfo:userInfo];
        });

        context(@"No options", ^{
            beforeEach(^{
                model = amaModelForNSError(factory, error, 0);
            });

            it(@"Should have valid type", ^{
                [[theValue(model.type) should] equal:theValue(AMAErrorModelTypeNSError)];
            });
            it(@"Should have nil Custom data", ^{
                [[model.customData should] beNil];
            });
            it (@"Should not have virtual machine error", ^{
                [[model.virtualMachineError should] beNil];
            });
            context(@"NSError Data", ^{
                it(@"Should have valid domain", ^{
                    [[model.nsErrorData.domain should] equal:error.domain];
                });
                it(@"Should have valid code", ^{
                    [[theValue(model.nsErrorData.code) should] equal:theValue(error.code)];
                });
            });
            it(@"Should have valid parameters", ^{
                [[parseParameters() should] equal:expectedParameters];
            });
            it(@"Should have valid user provided backtrace", ^{
                [[model.userProvidedBacktrace should] equal:error.userInfo[AMABacktraceErrorKey]];
            });
            it(@"Should have valid function as first frame in report call backtrace", ^{
                [[symbolicate(model.reportCallBacktrace).firstObject should] containString:@"amaModelForNSError"];
            });
            context(@"Underlying", ^{
                context(@"NSError Data", ^{
                    it(@"Should have valid domain", ^{
                        [[model.underlyingError.nsErrorData.domain should] equal:underlyingError.domain];
                    });
                    it(@"Should have valid code", ^{
                        [[theValue(model.underlyingError.nsErrorData.code) should] equal:theValue(underlyingError.code)];
                    });
                });
                it(@"Should have nil user provided backtrace", ^{
                    [[model.underlyingError.userProvidedBacktrace should] beNil];
                });
                it(@"Should have nil report call backtrace", ^{
                    [[model.underlyingError.reportCallBacktrace should] beNil];
                });
                it (@"Should not have virtual machine error", ^{
                    [[model.underlyingError.virtualMachineError should] beNil];
                });
            });
        });

        context(@"No backtrace", ^{
            beforeEach(^{
                model = amaModelForNSError(factory, error, AMAErrorReportingOptionsNoBacktrace);
            });

            it(@"Should have valid user provided backtrace", ^{
                [[model.userProvidedBacktrace should] equal:error.userInfo[AMABacktraceErrorKey]];
            });
            it(@"Should have nil report call backtrace", ^{
                [[model.reportCallBacktrace should] beNil];
            });
            it (@"Should not have virtual machine error", ^{
                [[model.virtualMachineError should] beNil];
            });
            context(@"Underlying", ^{
                it(@"Should have nil user provided backtrace", ^{
                    [[model.underlyingError.userProvidedBacktrace should] beNil];
                });
                it(@"Should have nil report call backtrace", ^{
                    [[model.underlyingError.reportCallBacktrace should] beNil];
                });
            });
        });

        context(@"Invalid custom backtrace", ^{
            beforeEach(^{
                NSMutableDictionary *userInfo = error.userInfo.mutableCopy;
                userInfo[AMABacktraceErrorKey] = @[ @1, @2, @"string" ];
                [error stub:@selector(userInfo) andReturn:userInfo];
                model = amaModelForNSError(factory, error, 0);
            });
            it(@"Should have valid type", ^{
                [[theValue(model.type) should] equal:theValue(AMAErrorModelTypeNSError)];
            });
            it(@"Should have valid id", ^{
                [[model.nsErrorData.domain should] equal:error.domain];
            });
            it(@"Should have no user provided backtrace", ^{
                [[model.userProvidedBacktrace should] beNil];
            });
            it (@"Should not have virtual machine error", ^{
                [[model.virtualMachineError should] beNil];
            });
        });
    });

    context(@"Minimal error", ^{
        AMATestMinimalError *__block error = nil;
        beforeEach(^{
            error = [[AMATestMinimalError alloc] init];
            error.identifier = @"IDENTIFIER";
        });

        context(@"No options", ^{
            beforeEach(^{
                model = amaModelForErrorRepresentable(factory, error, 0);
            });

            it(@"Should have valid type", ^{
                [[theValue(model.type) should] equal:theValue(AMAErrorModelTypeCustom)];
            });
            context(@"Custom Data", ^{
                it(@"Should have valid id", ^{
                    [[model.customData.identifier should] equal:error.identifier];
                });
                it(@"Should have no message", ^{
                    [[model.customData.message should] beNil];
                });
            });
            it(@"Should have no NSError data", ^{
                [[model.nsErrorData should] beNil];
            });
            it(@"Should have no parameters", ^{
                [[model.parametersString should] beNil];
            });
            it(@"Should have no user provided backtrace", ^{
                [[model.userProvidedBacktrace should] beNil];
            });
            it(@"Should have valid function as first frame in report call backtrace", ^{
                [[symbolicate(model.reportCallBacktrace).firstObject should] containString:@"amaModelForErrorRepresentable"];
            });
            it(@"Should have no underlying error", ^{
                [[model.underlyingError should] beNil];
            });
            it (@"Should not have virtual machine error", ^{
                [[model.virtualMachineError should] beNil];
            });
        });

        context(@"No backtrace", ^{
            beforeEach(^{
                model = amaModelForErrorRepresentable(factory, error, AMAErrorReportingOptionsNoBacktrace);
            });

            it(@"Should have valid id", ^{
                [[model.customData.identifier should] equal:error.identifier];
            });
            it(@"Should have nil report call backtrace", ^{
                [[model.reportCallBacktrace should] beNil];
            });
            it(@"Should have no underlying error", ^{
                [[model.underlyingError should] beNil];
            });
            it (@"Should not have virtual machine error", ^{
                [[model.virtualMachineError should] beNil];
            });
        });
    });

    context(@"Default model for error details", ^{
        NSString *const exceptionClass = @"some exception";
        NSString *const message = @"some message";
        AMAPluginErrorDetails *const errorDetails = [[AMAPluginErrorDetails alloc] initWithExceptionClass:exceptionClass
                                                                                                  message:message
                                                                                                backtrace:@[]
                                                                                                 platform:@"flutter"
                                                                                    virtualMachineVersion:@"5.7.9"
                                                                                        pluginEnvironment:@{}];
        AMAErrorModel *__block errorModel;
        beforeEach(^{
            errorModel = [factory defaultModelForErrorDetails:errorDetails bytesTruncated:NULL];
        });
        it(@"Should have valid type", ^{
            [[theValue(errorModel.type) should] equal:theValue(AMAErrorModelTypeVirtualMachine)];
        });
        it(@"Should not have custom data", ^{
            [[errorModel.customData should] beNil];
        });
        it(@"Should not have nserror data", ^{
            [[errorModel.nsErrorData should] beNil];
        });
        it(@"Should not have parameters", ^{
            [[errorModel.parametersString should] beNil];
        });
        it(@"Should not have report call backtrace", ^{
            [[errorModel.reportCallBacktrace should] beNil];
        });
        it(@"Should not have user provided backtrace", ^{
            [[errorModel.userProvidedBacktrace should] beNil];
        });
        it(@"Should not underlying error", ^{
            [[errorModel.underlyingError should] beNil];
        });
        it(@"Should not have bytes truncated", ^{
            [[theValue(errorModel.bytesTruncated) should] beZero];
        });
        context(@"Virtual machine error", ^{
            it(@"Should have class name", ^{
                [[errorModel.virtualMachineError.className should] equal:exceptionClass];
            });
            it(@"Should have message", ^{
                [[errorModel.virtualMachineError.message should] equal:message];
            });
        });
    });

    context(@"Default model for nil error details", ^{
        AMAErrorModel *__block errorModel;
        beforeEach(^{
            errorModel = [factory defaultModelForErrorDetails:nil bytesTruncated:NULL];
        });
        it(@"Should have valid type", ^{
            [[theValue(errorModel.type) should] equal:theValue(AMAErrorModelTypeVirtualMachine)];
        });
        it(@"Should not have custom data", ^{
            [[errorModel.customData should] beNil];
        });
        it(@"Should not have nserror data", ^{
            [[errorModel.nsErrorData should] beNil];
        });
        it(@"Should not have parameters", ^{
            [[errorModel.parametersString should] beNil];
        });
        it(@"Should not have report call backtrace", ^{
            [[errorModel.reportCallBacktrace should] beNil];
        });
        it(@"Should not have user provided backtrace", ^{
            [[errorModel.userProvidedBacktrace should] beNil];
        });
        it(@"Should not underlying error", ^{
            [[errorModel.underlyingError should] beNil];
        });
        it(@"Should not have bytes truncated", ^{
            [[theValue(errorModel.bytesTruncated) should] beZero];
        });
        it(@"Should not have virtual machine error", ^{
            [[errorModel.virtualMachineError should] beNil];
        });
    });

    context(@"Custom model for error details", ^{
        NSString *const identifier = @"444-555";
        NSString *const exceptionClass = @"some exception";
        NSString *const message = @"some message";
        AMAPluginErrorDetails *const errorDetails = [[AMAPluginErrorDetails alloc] initWithExceptionClass:exceptionClass
                                                                                                  message:message
                                                                                                backtrace:@[]
                                                                                                 platform:@"flutter"
                                                                                    virtualMachineVersion:@"5.7.9"
                                                                                        pluginEnvironment:@{}];
        AMAErrorModel *__block errorModel;
        beforeEach(^{
            errorModel = [factory customModelForErrorDetails:errorDetails identifier:identifier bytesTruncated:NULL];
        });
        it(@"Should have valid type", ^{
            [[theValue(errorModel.type) should] equal:theValue(AMAErrorModelTypeVirtualMachineCustom)];
        });
        it(@"Should not have virtual machine error", ^{
            [[errorModel.virtualMachineError should] beNil];
        });
        it(@"Should not have nserror data", ^{
            [[errorModel.nsErrorData should] beNil];
        });
        it(@"Should not have parameters", ^{
            [[errorModel.parametersString should] beNil];
        });
        it(@"Should not have report call backtrace", ^{
            [[errorModel.reportCallBacktrace should] beNil];
        });
        it(@"Should not have user provided backtrace", ^{
            [[errorModel.userProvidedBacktrace should] beNil];
        });
        it(@"Should not underlying error", ^{
            [[errorModel.underlyingError should] beNil];
        });
        it(@"Should not have bytes truncated", ^{
            [[theValue(errorModel.bytesTruncated) should] beZero];
        });
        context(@"Custom data", ^{
            it(@"Should have class name", ^{
                [[errorModel.customData.className should] equal:exceptionClass];
            });
            it(@"Should have message", ^{
                [[errorModel.customData.message should] equal:message];
            });
            it(@"Should have identifier", ^{
                [[errorModel.customData.identifier should] equal:identifier];
            });
        });
    });
    context(@"Custom model for nil error details", ^{
        NSString *const identifier = @"444-555";
        AMAErrorModel *__block errorModel;
        beforeEach(^{
            errorModel = [factory customModelForErrorDetails:nil identifier:identifier bytesTruncated:NULL];
        });
        it(@"Should have valid type", ^{
            [[theValue(errorModel.type) should] equal:theValue(AMAErrorModelTypeVirtualMachineCustom)];
        });
        it(@"Should not have virtual machine error", ^{
            [[errorModel.virtualMachineError should] beNil];
        });
        it(@"Should not have nserror data", ^{
            [[errorModel.nsErrorData should] beNil];
        });
        it(@"Should not have parameters", ^{
            [[errorModel.parametersString should] beNil];
        });
        it(@"Should not have report call backtrace", ^{
            [[errorModel.reportCallBacktrace should] beNil];
        });
        it(@"Should not have user provided backtrace", ^{
            [[errorModel.userProvidedBacktrace should] beNil];
        });
        it(@"Should not underlying error", ^{
            [[errorModel.underlyingError should] beNil];
        });
        it(@"Should not have bytes truncated", ^{
            [[theValue(errorModel.bytesTruncated) should] beZero];
        });
        context(@"Custom data", ^{
            it(@"Should not have class name", ^{
                [[errorModel.customData.className should] beNil];
            });
            it(@"Should have message", ^{
                [[errorModel.customData.message should] beNil];
            });
            it(@"Should have identifier", ^{
                [[errorModel.customData.identifier should] equal:identifier];
            });
        });
    });

    context(@"Truncation", ^{
        NSString *const expectedTruncatedString = @"TRUNCATED_STRING";
        NSDictionary *const expectedTruncatedDictionary = @{ @"truncated key" : @"truncated value", @"another key" : @"another valuer" };
        NSUInteger const expectedBytesTruncated = 23;

        AMATestTruncator *__block domainTruncator = nil;
        AMATestTruncator *__block identifierTruncator = nil;
        AMATestTruncator *__block messageTruncator = nil;
        AMATestTruncator *__block environmentTruncator = nil;
        AMATestTruncator *__block shortStringTruncator = nil;

        beforeEach(^{
            domainTruncator = [[AMATestTruncator alloc] init];
            identifierTruncator = [[AMATestTruncator alloc] init];
            messageTruncator = [[AMATestTruncator alloc] init];
            environmentTruncator = [[AMATestTruncator alloc] init];
            shortStringTruncator = [[AMATestTruncator alloc] init];
            [NSThread stub:@selector(callStackReturnAddresses) andReturn:@[ @0, @0, @0, @23, @42 ]];
            factory = [[AMAErrorModelFactory alloc] initWithDomainTruncator:domainTruncator
                                                        identifierTruncator:identifierTruncator
                                                           messageTruncator:messageTruncator
                                                       environmentTruncator:environmentTruncator
                                                       shortStringTruncator:shortStringTruncator
                                                   maxUnderlyingErrorsCount:2
                                                    maxBacktraceFramesCount:2];
        });

        context(@"AMAError", ^{
            AMAError *__block underlyingError = nil;
            AMAError *__block error = nil;
            beforeEach(^{
                underlyingError = [AMAError errorWithIdentifier:@"UNDERLYING_ERROR"];
                error = [AMAError errorWithIdentifier:@"IDENTIFIER"
                                              message:@"MESSAGE"
                                           parameters:@{ @"foo": @"bar" }
                                            backtrace:@[ @1, @2 ]
                                      underlyingError:underlyingError];
            });
            __auto_type createModel = ^{
                model = amaModelForErrorRepresentable(factory, error, 0);
            };
            context(@"Identifier", ^{
                beforeEach(^{
                    [identifierTruncator enableTruncationWithResult:expectedTruncatedString
                                                     bytesTruncated:expectedBytesTruncated];
                    createModel();
                });
                it(@"Should have truncated value", ^{
                    [[model.customData.identifier should] equal:expectedTruncatedString];
                });
                it(@"Should have valid bytes truncated", ^{
                    // 2 errors in chain => 2 identifiers => truncated twice
                    [[theValue(model.bytesTruncated) should] equal:theValue(expectedBytesTruncated * 2)];
                });
            });
            context(@"Message", ^{
                beforeEach(^{
                    [messageTruncator enableTruncationWithResult:expectedTruncatedString
                                                  bytesTruncated:expectedBytesTruncated];
                    createModel();
                });
                it(@"Should have truncated value", ^{
                    [[model.customData.message should] equal:expectedTruncatedString];
                });
                it(@"Should have valid bytes truncated", ^{
                    [[theValue(model.bytesTruncated) should] equal:theValue(expectedBytesTruncated)];
                });
            });
            context(@"Environment", ^{
                beforeEach(^{
                    [environmentTruncator enableTruncationWithResult:expectedTruncatedDictionary
                                                      bytesTruncated:expectedBytesTruncated];
                    createModel();
                });
                it(@"Should have truncated value", ^{
                    [[parseParameters() should] equal:expectedTruncatedDictionary];
                });
                it(@"Should have valid bytes truncated", ^{
                    [[theValue(model.bytesTruncated) should] equal:theValue(expectedBytesTruncated)];
                });
            });
            context(@"Undelrying errors limit", ^{
                beforeEach(^{
                    [error stub:@selector(underlyingError) andReturn:error];
                    createModel();
                });
                it(@"Should have valid first error", ^{
                    [[model.customData.identifier should] equal:error.identifier];
                });
                it(@"Should have valid second error", ^{
                    [[model.underlyingError.customData.identifier should] equal:error.identifier];
                });
                it(@"Should have no third error", ^{
                    [[model.underlyingError.underlyingError should] beNil];
                });
            });
            context(@"Custom backtrace limit", ^{
                beforeEach(^{
                    [error stub:@selector(backtrace) andReturn:@[ @1, @2, @3, @4, @5 ]];
                    createModel();
                });
                it(@"Should have truncated value", ^{
                    [[model.userProvidedBacktrace should] equal:@[ @1, @2 ]];
                });
                it(@"Should have valid bytes truncated", ^{
                    [[theValue(model.bytesTruncated) should] equal:theValue(3 * sizeof(uintptr_t))];
                });
            });
            context(@"Report call backtrace limit", ^{
                beforeEach(^{
                    [NSThread stub:@selector(callStackReturnAddresses) andReturn:@[ @0, @0, @0, @1, @2, @3, @4 ]];
                    createModel();
                });
                it(@"Should have truncated value", ^{
                    [[model.reportCallBacktrace should] equal:@[ @1, @2 ]];
                });
                it(@"Should have valid bytes truncated", ^{
                    [[theValue(model.bytesTruncated) should] equal:theValue(2 * sizeof(uintptr_t))];
                });
            });
        });

        context(@"NSError", ^{
            NSError *__block underlyingError = nil;
            NSError *__block error = nil;
            beforeEach(^{
                underlyingError = [NSError errorWithDomain:@"UNDERLYING_DOMAIN" code:23 userInfo:nil];
                error = [NSError errorWithDomain:@"DOMAIN" code:42 userInfo:@{
                    AMABacktraceErrorKey: @[ @1, @2 ],
                    NSUnderlyingErrorKey: underlyingError,
                    @"foo": @"bar",
                }];
            });
            __auto_type createModel = ^{
                model = amaModelForNSError(factory, error, 0);
            };
            context(@"Domain", ^{
                beforeEach(^{
                    [domainTruncator enableTruncationWithResult:expectedTruncatedString
                                                 bytesTruncated:expectedBytesTruncated];
                    createModel();
                });
                it(@"Should have truncated value", ^{
                    [[model.nsErrorData.domain should] equal:expectedTruncatedString];
                });
                it(@"Should have valid bytes truncated", ^{
                    // 2 errors in chain => 2 identifiers => truncated twice
                    [[theValue(model.bytesTruncated) should] equal:theValue(expectedBytesTruncated * 2)];
                });
            });
            context(@"Environment", ^{
                beforeEach(^{
                    [environmentTruncator enableTruncationWithResult:expectedTruncatedDictionary
                                                      bytesTruncated:expectedBytesTruncated];
                    createModel();
                });
                it(@"Should have truncated value", ^{
                    [[parseParameters() should] equal:expectedTruncatedDictionary];
                });
                it(@"Should have valid bytes truncated", ^{
                    [[theValue(model.bytesTruncated) should] equal:theValue(2 * expectedBytesTruncated)];
                });
            });
            context(@"Undelrying errors limit", ^{
                beforeEach(^{
                    NSMutableDictionary *userInfo = error.userInfo.mutableCopy;
                    userInfo[NSUnderlyingErrorKey] = error;
                    [error stub:@selector(userInfo) andReturn:userInfo];
                    createModel();
                });
                it(@"Should have valid first error", ^{
                    [[model.nsErrorData.domain should] equal:error.domain];
                });
                it(@"Should have valid second error", ^{
                    [[model.underlyingError.nsErrorData.domain should] equal:error.domain];
                });
                it(@"Should have no third error", ^{
                    [[model.underlyingError.underlyingError should] beNil];
                });
            });
            context(@"Custom backtrace limit", ^{
                beforeEach(^{
                    NSMutableDictionary *userInfo = error.userInfo.mutableCopy;
                    userInfo[AMABacktraceErrorKey] = @[ @1, @2, @3, @4, @5 ];
                    [error stub:@selector(userInfo) andReturn:userInfo];
                    createModel();
                });
                it(@"Should have truncated value", ^{
                    [[model.userProvidedBacktrace should] equal:@[ @1, @2 ]];
                });
                it(@"Should have valid bytes truncated", ^{
                    [[theValue(model.bytesTruncated) should] equal:theValue(3 * sizeof(uintptr_t))];
                });
            });
            context(@"Report call backtrace limit", ^{
                beforeEach(^{
                    [NSThread stub:@selector(callStackReturnAddresses) andReturn:@[ @0, @0, @0, @1, @2, @3, @4 ]];
                    createModel();
                });
                it(@"Should have truncated value", ^{
                    [[model.reportCallBacktrace should] equal:@[ @1, @2 ]];
                });
                it(@"Should have valid bytes truncated", ^{
                    [[theValue(model.bytesTruncated) should] equal:theValue(2 * sizeof(uintptr_t))];
                });
            });
        });

        context(@"Plugin error details", ^{
            NSString *const exceptionClass = @"some exception";
            NSString *const message = @"some message";
            NSString *const truncatedMessage = @"Truncated message";
            NSString *const truncatedClassName = @"Truncated class name";
            NSString *const platform = @"flutter";
            NSString *const virtualMachineVersion = @"5.7.9";
            NSUInteger const messageBytesTruncated = 18;
            NSUInteger const classNameBytesTruncated = 16;
            NSUInteger __block bytesTruncated;
            NSDictionary *const pluginEnvironment = @{ @"key1" : @"value1", @"key2" : @"value2", @"key3" : @"value3" };
            AMAPluginErrorDetails *const errorDetails = [[AMAPluginErrorDetails alloc] initWithExceptionClass:exceptionClass
                                                                                                      message:message
                                                                                                    backtrace:@[]
                                                                                                     platform:platform
                                                                                        virtualMachineVersion:virtualMachineVersion
                                                                                            pluginEnvironment:pluginEnvironment];
            AMAErrorModel *__block errorModel;
            beforeEach(^{
                bytesTruncated = 0;
            });
            context(@"Default error", ^{
                context(@"Class name", ^{
                    beforeEach(^{
                        [shortStringTruncator enableTruncationWithResult:truncatedClassName
                                                          bytesTruncated:classNameBytesTruncated];
                        errorModel = [factory defaultModelForErrorDetails:errorDetails bytesTruncated:&bytesTruncated];
                    });
                    it(@"Should have correct class name", ^{
                        [[errorModel.virtualMachineError.className should] equal:truncatedClassName];
                    });
                    it(@"Should have correct bytes truncated", ^{
                        [[theValue(errorModel.bytesTruncated) should] equal:theValue(classNameBytesTruncated)];
                    });
                    it(@"Should fill bytes truncated", ^{
                        [[theValue(bytesTruncated) should] equal:theValue(classNameBytesTruncated)];
                    });
                });
                context(@"Message", ^{
                    beforeEach(^{
                        [messageTruncator enableTruncationWithResult:truncatedMessage
                                                      bytesTruncated:messageBytesTruncated];
                        errorModel = [factory defaultModelForErrorDetails:errorDetails bytesTruncated:&bytesTruncated];
                    });
                    it(@"Should have correct message", ^{
                        [[errorModel.virtualMachineError.message should] equal:truncatedMessage];
                    });
                    it(@"Should have correct bytes truncated", ^{
                        [[theValue(errorModel.bytesTruncated) should] equal:theValue(messageBytesTruncated)];
                    });
                    it(@"Should fill bytes truncated", ^{
                        [[theValue(bytesTruncated) should] equal:theValue(messageBytesTruncated)];
                    });
                });
                context(@"Several truncations", ^{
                    beforeEach(^{
                        [shortStringTruncator enableTruncationWithResult:truncatedClassName
                                                          bytesTruncated:classNameBytesTruncated];
                        [messageTruncator enableTruncationWithResult:truncatedMessage
                                                      bytesTruncated:messageBytesTruncated];
                        errorModel = [factory defaultModelForErrorDetails:errorDetails bytesTruncated:&bytesTruncated];
                    });
                    it(@"Should have correct bytes truncated", ^{
                        [[theValue(errorModel.bytesTruncated) should] equal:theValue(classNameBytesTruncated + messageBytesTruncated)];
                    });
                    it(@"Should fill bytes truncated", ^{
                        [[theValue(bytesTruncated) should] equal:theValue(classNameBytesTruncated + messageBytesTruncated)];
                    });
                });
            });
            context(@"Custom error", ^{
                NSString *const identifier = @"some identifier";
                NSString *const truncatedIdentifier = @"truncated identifier";
                NSUInteger const identifierBytesTruncated = 8;
                context(@"Class name", ^{
                    beforeEach(^{
                        [shortStringTruncator enableTruncationWithResult:truncatedClassName
                                                          bytesTruncated:classNameBytesTruncated];
                        errorModel = [factory customModelForErrorDetails:errorDetails
                                                              identifier:identifier
                                                          bytesTruncated:&bytesTruncated];
                    });
                    it(@"Should have correct class name", ^{
                        [[errorModel.customData.className should] equal:truncatedClassName];
                    });
                    it(@"Should have correct bytes truncated", ^{
                        [[theValue(errorModel.bytesTruncated) should] equal:theValue(classNameBytesTruncated)];
                    });
                    it(@"Should fill bytes truncated", ^{
                        [[theValue(bytesTruncated) should] equal:theValue(classNameBytesTruncated)];
                    });
                });
                context(@"Message", ^{
                    beforeEach(^{
                        [messageTruncator enableTruncationWithResult:truncatedMessage
                                                      bytesTruncated:messageBytesTruncated];
                        errorModel = [factory customModelForErrorDetails:errorDetails
                                                              identifier:identifier
                                                          bytesTruncated:&bytesTruncated];
                    });
                    it(@"Should have correct message", ^{
                        [[errorModel.customData.message should] equal:truncatedMessage];
                    });
                    it(@"Should have correct bytes truncated", ^{
                        [[theValue(errorModel.bytesTruncated) should] equal:theValue(messageBytesTruncated)];
                    });
                    it(@"Should fill bytes truncated", ^{
                        [[theValue(bytesTruncated) should] equal:theValue(messageBytesTruncated)];
                    });
                });
                context(@"Identifier", ^{
                    beforeEach(^{
                        [identifierTruncator enableTruncationWithResult:truncatedIdentifier
                                                         bytesTruncated:identifierBytesTruncated];
                        errorModel = [factory customModelForErrorDetails:errorDetails
                                                              identifier:identifier
                                                          bytesTruncated:&bytesTruncated];
                    });
                    it(@"Should have correct identifier", ^{
                        [[errorModel.customData.identifier should] equal:truncatedIdentifier];
                    });
                    it(@"Should have correct bytes truncated", ^{
                        [[theValue(errorModel.bytesTruncated) should] equal:theValue(identifierBytesTruncated)];
                    });
                    it(@"Should fill bytes truncated", ^{
                        [[theValue(bytesTruncated) should] equal:theValue(identifierBytesTruncated)];
                    });
                });
                context(@"Several truncations", ^{
                    beforeEach(^{
                        [shortStringTruncator enableTruncationWithResult:truncatedClassName
                                                          bytesTruncated:classNameBytesTruncated];
                        [messageTruncator enableTruncationWithResult:truncatedMessage
                                                      bytesTruncated:messageBytesTruncated];
                        [identifierTruncator enableTruncationWithResult:truncatedIdentifier
                                                         bytesTruncated:identifierBytesTruncated];
                        errorModel = [factory customModelForErrorDetails:errorDetails
                                                              identifier:identifier
                                                          bytesTruncated:&bytesTruncated];
                    });
                    it(@"Should have correct bytes truncated", ^{
                        [[theValue(errorModel.bytesTruncated) should]
                            equal:theValue(classNameBytesTruncated + messageBytesTruncated + identifierBytesTruncated)];
                    });
                    it(@"Should fill bytes truncated", ^{
                        [[theValue(bytesTruncated) should]
                            equal:theValue(classNameBytesTruncated + messageBytesTruncated + identifierBytesTruncated)];
                    });
                });

            });
        });
    });
});

SPEC_END
