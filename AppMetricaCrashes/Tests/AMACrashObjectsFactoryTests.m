
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAPluginErrorDetails.h"
#import "AMAVirtualMachineInfo.h"
#import "AMABacktrace.h"
#import "AMAVirtualMachineCrash.h"
#import "AMAStackTraceElement.h"
#import "AMACrashObjectsFactory.h"
#import "AMABacktraceFrame.h"

SPEC_BEGIN(AMACrashObjectsFactoryTests)

describe(@"AMACrashObjectsFactory", ^{

    AMACrashObjectsFactory *__block factory;

    beforeEach(^{
        factory = [[AMACrashObjectsFactory alloc] init];
    });

    context(@"Virtual machine info", ^{
        AMAVirtualMachineInfo *__block info;
        NSString *platform = @"flutter";
        NSString *virtualMachineVersion = @"5.7.9";
        NSDictionary *environment = @{ @"key 1" : @"value 1" };
        AMAPluginErrorDetails *errorDetails = [[AMAPluginErrorDetails alloc] initWithExceptionClass:@"some calss"
                                                                                            message:@"some message"
                                                                                          backtrace:@[]
                                                                                           platform:platform
                                                                              virtualMachineVersion:virtualMachineVersion
                                                                                  pluginEnvironment:environment];

        beforeEach(^{
            info = [factory virtualMachineInfoForErrorDetails:errorDetails bytesTruncated:NULL];
        });
        it(@"Should fill platform", ^{
            [[info.platform should] equal:platform];
        });
        it(@"Should fill virtual machine version", ^{
            [[info.virtualMachineVersion should] equal:virtualMachineVersion];
        });
        it(@"Should fill environment", ^{
            [[info.environment should] equal:environment];
        });
    });

    context(@"Virtual machine info for nil error details", ^{
        AMAVirtualMachineInfo *__block info;
        beforeEach(^{
            info = [factory virtualMachineInfoForErrorDetails:nil bytesTruncated:NULL];
        });
        it(@"Should be nil", ^{
            [[info should] beNil];
        });
    });

    context(@"Virtual machine crash", ^{
        AMAVirtualMachineCrash *__block result;
        NSString *className = @"some class";
        NSString *message = @"some message";
        NSString *platform = @"flutter";
        NSString *virtualMachineVersion = @"5.7.9";
        AMAPluginErrorDetails *errorDetails = [[AMAPluginErrorDetails alloc] initWithExceptionClass:className
                                                                                            message:message
                                                                                          backtrace:@[]
                                                                                           platform:platform
                                                                              virtualMachineVersion:virtualMachineVersion
                                                                                  pluginEnvironment:@{}];

        beforeEach(^{
            result = [factory virtualMachineCrashForErrorDetails:errorDetails bytesTruncated:NULL];
        });
        it(@"Should fill class name", ^{
            [[result.className should] equal:className];
        });
        it(@"Should fill class name", ^{
            [[result.message should] equal:message];
        });
    });

    context(@"Virtual machine crash for nil error details", ^{
        AMAVirtualMachineCrash *__block result;
        beforeEach(^{
            result = [factory virtualMachineCrashForErrorDetails:nil bytesTruncated:NULL];
        });
        it(@"Should be nil", ^{
            [[result should] beNil];
        });
    });

    context(@"Backtrace", ^{
        AMABacktrace *__block result;
        NSString *firstClassName = @"class1";
        NSString *secondClassName = @"class2";
        NSString *firstFileName = @"file1";
        NSString *secondFileName = @"file2";
        NSString *firstMethodName = @"method1";
        NSString *secondMethodName = @"method2";
        NSNumber *firstLine = @7;
        NSNumber *secondLine = @8;
        NSNumber *firstColumn = @17;
        NSNumber *secondColumn = @18;
        AMAStackTraceElement *firstItem = [[AMAStackTraceElement alloc] initWithClassName:firstClassName
                                                                                 fileName:firstFileName
                                                                                     line:firstLine
                                                                                   column:firstColumn
                                                                               methodName:firstMethodName];
        AMAStackTraceElement *secondItem = [[AMAStackTraceElement alloc] initWithClassName:secondClassName
                                                                                  fileName:secondFileName
                                                                                      line:secondLine
                                                                                    column:secondColumn
                                                                                methodName:secondMethodName];
        beforeEach(^{
            result = [factory backtraceFrom:@[firstItem, secondItem] bytesTruncated:NULL];
        });
        it(@"should have correct size", ^{
            [[theValue(result.frames.count) should] equal:theValue(2)];
        });
        context(@"First item", ^{
            AMABacktraceFrame *__block frame = nil;
            beforeEach(^{
                frame = result.frames[0];
            });
            it(@"Should fill class name", ^{
                [[frame.className should] equal:firstClassName];
            });
            it(@"Should fill file name", ^{
                [[frame.sourceFileName should] equal:firstFileName];
            });
            it(@"Should fill method name", ^{
                [[frame.methodName should] equal:firstMethodName];
            });
            it(@"Should fill line", ^{
                [[frame.lineOfCode should] equal:firstLine];
            });
            it(@"Should fill column", ^{
                [[frame.columnOfCode should] equal:firstColumn];
            });
        });
        context(@"second item", ^{
            AMABacktraceFrame *__block frame = nil;
            beforeEach(^{
                frame = result.frames[1];
            });
            it(@"Should fill class name", ^{
                [[frame.className should] equal:secondClassName];
            });
            it(@"Should fill file name", ^{
                [[frame.sourceFileName should] equal:secondFileName];
            });
            it(@"Should fill method name", ^{
                [[frame.methodName should] equal:secondMethodName];
            });
            it(@"Should fill line", ^{
                [[frame.lineOfCode should] equal:secondLine];
            });
            it(@"Should fill column", ^{
                [[frame.columnOfCode should] equal:secondColumn];
            });
        });
    });

    context(@"Backtrace info for nil backtrace", ^{
        AMABacktrace *__block result;
        beforeEach(^{
            result = [factory backtraceFrom:nil bytesTruncated:NULL];
        });
        it(@"Should be empty", ^{
            [[result.frames should] equal:@[]];
        });
    });

    context(@"Truncation", ^{

        AMATestTruncator *__block messageTruncator = nil;
        AMATestTruncator *__block environmentTruncator = nil;
        AMATestTruncator *__block shortStringTruncator = nil;

        NSString *exceptionClass = @"some exception";
        NSString *message = @"some message";
        NSString *truncatedMessage = @"Truncated message";
        NSString *truncatedClassName = @"Truncated class name";
        NSString *platform = @"flutter";
        NSString *virtualMachineVersion = @"5.7.9";
        NSUInteger messageBytesTruncated = 18;
        NSUInteger classNameBytesTruncated = 16;
        NSUInteger __block bytesTruncated;
        NSDictionary *pluginEnvironment = @{ @"key1" : @"value1", @"key2" : @"value2", @"key3" : @"value3" };
        AMAPluginErrorDetails *errorDetails = [[AMAPluginErrorDetails alloc] initWithExceptionClass:exceptionClass
                                                                                            message:message
                                                                                          backtrace:@[]
                                                                                           platform:platform
                                                                              virtualMachineVersion:virtualMachineVersion
                                                                                  pluginEnvironment:pluginEnvironment];

        beforeEach(^{
            bytesTruncated = 0;
            messageTruncator = [[AMATestTruncator alloc] init];
            environmentTruncator = [[AMATestTruncator alloc] init];
            shortStringTruncator = [[AMATestTruncator alloc] init];
            factory = [[AMACrashObjectsFactory alloc] initWithMessageTruncator:messageTruncator
                                                          environmentTruncator:environmentTruncator
                                                          shortStringTruncator:shortStringTruncator
                                                       maxBacktraceFramesCount:2];
        });

        context(@"Virtual machine crash", ^{
            AMAVirtualMachineCrash *__block result = nil;
            context(@"Class name", ^{
                beforeEach(^{
                    [shortStringTruncator enableTruncationWithResult:truncatedClassName
                                                      bytesTruncated:classNameBytesTruncated];
                    result = [factory virtualMachineCrashForErrorDetails:errorDetails
                                                          bytesTruncated:&bytesTruncated];
                });
                it(@"Should have correct class name", ^{
                    [[result.className should] equal:truncatedClassName];
                });
                it(@"Should fill bytes truncated", ^{
                    [[theValue(bytesTruncated) should] equal:theValue(classNameBytesTruncated)];
                });
            });
            context(@"Message", ^{
                beforeEach(^{
                    [messageTruncator enableTruncationWithResult:truncatedMessage
                                                  bytesTruncated:messageBytesTruncated];
                    result = [factory virtualMachineCrashForErrorDetails:errorDetails
                                                          bytesTruncated:&bytesTruncated];
                });
                it(@"Should have correct message", ^{
                    [[result.message should] equal:truncatedMessage];
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
                    result = [factory virtualMachineCrashForErrorDetails:errorDetails
                                                          bytesTruncated:&bytesTruncated];
                });
                it(@"Should fill bytes truncated", ^{
                    [[theValue(bytesTruncated) should] equal:theValue(classNameBytesTruncated + messageBytesTruncated)];
                });
            });
        });
        context(@"Backtrace", ^{
            AMABacktrace *__block result;
            NSString *firstClassName = @"class1";
            NSString *secondClassName = @"class2";
            NSString *firstFileName = @"file1";
            NSString *secondFileName = @"file2";
            NSString *firstMethodName = @"method1";
            NSString *secondMethodName = @"method2";
            NSNumber *firstLine = @7;
            NSNumber *secondLine = @8;
            NSNumber *firstColumn = @17;
            NSNumber *secondColumn = @18;
            AMAStackTraceElement *firstItem = [[AMAStackTraceElement alloc] initWithClassName:firstClassName
                                                                                     fileName:firstFileName
                                                                                         line:firstLine
                                                                                       column:firstColumn
                                                                                   methodName:firstMethodName];
            AMAStackTraceElement *secondItem = [[AMAStackTraceElement alloc] initWithClassName:secondClassName
                                                                                      fileName:secondFileName
                                                                                          line:secondLine
                                                                                        column:secondColumn
                                                                                    methodName:secondMethodName];
            AMAStackTraceElement *thirdItem = [[AMAStackTraceElement alloc] initWithClassName:@"class 3"
                                                                                     fileName:@"file 3"
                                                                                         line:@13
                                                                                       column:@31
                                                                                   methodName:@"method 3"];
            NSString *truncatedFirstClassName = @"truncated class1";
            NSString *truncatedSecondClassName = @"truncated class2";
            NSString *truncatedFirstFileName = @"truncated file1";
            NSString *truncatedSecondFileName = @"truncated file2";
            NSString *truncatedFirstMethodName = @"truncated method1";
            NSString *truncatedSecondMethodName = @"truncated method2";
            NSUInteger firstClassNameBytesTruncated = 12;
            NSUInteger firstMethodNameBytesTruncated = 14;
            NSUInteger firstFileNameBytesTruncated = 16;
            NSUInteger secondClassNameBytesTruncated = 22;
            NSUInteger secondMethodNameBytesTruncated = 24;
            NSUInteger secondFileNameBytesTruncated = 26;
            NSUInteger thirdItemBytesTruncated = sizeof(uintptr_t);
            NSArray *backtrace = @[firstItem, secondItem, thirdItem];
            context(@"Frames count", ^{
                beforeEach(^{
                    result = [factory backtraceFrom:backtrace bytesTruncated:&bytesTruncated];
                });
                it(@"Should have only 2 items", ^{
                    [[theValue(result.frames.count) should] equal:theValue(2)];
                });
                it(@"Should fill bytesTruncated", ^{
                    [[theValue(bytesTruncated) should] equal:theValue(thirdItemBytesTruncated)];
                });
            });
            context(@"First item", ^{
                context(@"Class name", ^{
                    beforeEach(^{
                        [shortStringTruncator enableTruncationWithResult:truncatedFirstClassName
                                                             forArgument:firstClassName
                                                          bytesTruncated:firstClassNameBytesTruncated];
                        result = [factory backtraceFrom:backtrace bytesTruncated:&bytesTruncated];
                    });
                    it(@"Should have correct class name", ^{
                        [[result.frames[0].className should] equal:truncatedFirstClassName];
                    });
                    it(@"Should fill bytes truncated", ^{
                        [[theValue(bytesTruncated) should] equal:theValue(thirdItemBytesTruncated + firstClassNameBytesTruncated)];
                    });
                });
                context(@"File name", ^{
                    beforeEach(^{
                        [shortStringTruncator enableTruncationWithResult:truncatedFirstFileName
                                                             forArgument:firstFileName
                                                          bytesTruncated:firstFileNameBytesTruncated];
                        result = [factory backtraceFrom:backtrace bytesTruncated:&bytesTruncated];
                    });
                    it(@"Should have correct file name", ^{
                        [[result.frames[0].sourceFileName should] equal:truncatedFirstFileName];
                    });
                    it(@"Should fill bytes truncated", ^{
                        [[theValue(bytesTruncated) should] equal:theValue(thirdItemBytesTruncated + firstFileNameBytesTruncated)];
                    });
                });
                context(@"Method name", ^{
                    beforeEach(^{
                        [shortStringTruncator enableTruncationWithResult:truncatedFirstMethodName
                                                             forArgument:firstMethodName
                                                          bytesTruncated:firstMethodNameBytesTruncated];
                        result = [factory backtraceFrom:backtrace bytesTruncated:&bytesTruncated];
                    });
                    it(@"Should have correct method name", ^{
                        [[result.frames[0].methodName should] equal:truncatedFirstMethodName];
                    });
                    it(@"Should fill bytes truncated", ^{
                        [[theValue(bytesTruncated) should] equal:theValue(thirdItemBytesTruncated + firstMethodNameBytesTruncated)];
                    });
                });
            });
            context(@"Second item", ^{
                context(@"Class name", ^{
                    beforeEach(^{
                        [shortStringTruncator enableTruncationWithResult:truncatedSecondClassName
                                                             forArgument:secondClassName
                                                          bytesTruncated:secondClassNameBytesTruncated];
                        result = [factory backtraceFrom:backtrace bytesTruncated:&bytesTruncated];
                    });
                    it(@"Should have correct class name", ^{
                        [[result.frames[1].className should] equal:truncatedSecondClassName];
                    });
                    it(@"Should fill bytes truncated", ^{
                        [[theValue(bytesTruncated) should] equal:theValue(thirdItemBytesTruncated + secondClassNameBytesTruncated)];
                    });
                });
                context(@"File name", ^{
                    beforeEach(^{
                        [shortStringTruncator enableTruncationWithResult:truncatedSecondFileName
                                                             forArgument:secondFileName
                                                          bytesTruncated:secondFileNameBytesTruncated];
                        result = [factory backtraceFrom:backtrace bytesTruncated:&bytesTruncated];
                    });
                    it(@"Should have correct file name", ^{
                        [[result.frames[1].sourceFileName should] equal:truncatedSecondFileName];
                    });
                    it(@"Should fill bytes truncated", ^{
                        [[theValue(bytesTruncated) should] equal:theValue(thirdItemBytesTruncated + secondFileNameBytesTruncated)];
                    });
                });
                context(@"Method name", ^{
                    beforeEach(^{
                        [shortStringTruncator enableTruncationWithResult:truncatedSecondMethodName
                                                             forArgument:secondMethodName
                                                          bytesTruncated:secondMethodNameBytesTruncated];
                        result = [factory backtraceFrom:backtrace bytesTruncated:&bytesTruncated];
                    });
                    it(@"Should have correct method name", ^{
                        [[result.frames[1].methodName should] equal:truncatedSecondMethodName];
                    });
                    it(@"Should fill bytes truncated", ^{
                        [[theValue(bytesTruncated) should] equal:theValue(thirdItemBytesTruncated + secondMethodNameBytesTruncated)];
                    });
                });
            });
            context(@"Several truncations", ^{
                beforeEach(^{
                    [shortStringTruncator enableTruncationWithResult:truncatedFirstClassName
                                                         forArgument:firstClassName
                                                      bytesTruncated:firstClassNameBytesTruncated];
                    [shortStringTruncator enableTruncationWithResult:truncatedFirstFileName
                                                         forArgument:firstFileName
                                                      bytesTruncated:firstFileNameBytesTruncated];
                    [shortStringTruncator enableTruncationWithResult:truncatedFirstMethodName
                                                         forArgument:firstMethodName
                                                      bytesTruncated:firstMethodNameBytesTruncated];
                    [shortStringTruncator enableTruncationWithResult:truncatedSecondClassName
                                                         forArgument:secondClassName
                                                      bytesTruncated:secondClassNameBytesTruncated];
                    [shortStringTruncator enableTruncationWithResult:truncatedSecondFileName
                                                         forArgument:secondFileName
                                                      bytesTruncated:secondFileNameBytesTruncated];
                    [shortStringTruncator enableTruncationWithResult:truncatedSecondMethodName
                                                         forArgument:secondMethodName
                                                      bytesTruncated:secondMethodNameBytesTruncated];
                    result = [factory backtraceFrom:backtrace bytesTruncated:&bytesTruncated];
                });
                it(@"Should fill bytes truncated", ^{
                    [[theValue(bytesTruncated) should]
                        equal:theValue(firstClassNameBytesTruncated + firstFileNameBytesTruncated + firstMethodNameBytesTruncated
                        + secondClassNameBytesTruncated + secondFileNameBytesTruncated + secondMethodNameBytesTruncated
                        + thirdItemBytesTruncated)];
                });
            });

        });
        context(@"Virtual machine info", ^{
            NSString *truncatedPlatform = @"truncated platform";
            NSString *truncatedVirtualMachineVersion = @"truncate virtual machine version";
            NSDictionary *truncatedDictionary = @{ @"truncated key" : @"truncated value", @"another key" : @"another value" };
            NSUInteger platformBytesTruncated = 3;
            NSUInteger virtualMachineVersionBytesTruncated = 31;
            NSUInteger dictionaryBytesTruncated = 5;
            AMAVirtualMachineInfo *__block virtualMachineInfo = nil;
            context(@"Platform", ^{
                beforeEach(^{
                    [shortStringTruncator enableTruncationWithResult:truncatedPlatform
                                                         forArgument:platform
                                                      bytesTruncated:platformBytesTruncated];
                    virtualMachineInfo = [factory virtualMachineInfoForErrorDetails:errorDetails
                                                                     bytesTruncated:&bytesTruncated];
                });
                it(@"Should have correct platform", ^{
                    [[virtualMachineInfo.platform should] equal:truncatedPlatform];
                });
                it(@"Should fill bytes truncated", ^{
                    [[theValue(bytesTruncated) should] equal:theValue(platformBytesTruncated)];
                });
            });
            context(@"Virtual machine version", ^{
                beforeEach(^{
                    [shortStringTruncator enableTruncationWithResult:truncatedVirtualMachineVersion
                                                         forArgument:virtualMachineVersion
                                                      bytesTruncated:virtualMachineVersionBytesTruncated];
                    virtualMachineInfo = [factory virtualMachineInfoForErrorDetails:errorDetails
                                                                     bytesTruncated:&bytesTruncated];
                });
                it(@"Should have correct virtual machine version", ^{
                    [[virtualMachineInfo.virtualMachineVersion should] equal:truncatedVirtualMachineVersion];
                });
                it(@"Should fill bytes truncated", ^{
                    [[theValue(bytesTruncated) should] equal:theValue(virtualMachineVersionBytesTruncated)];
                });
            });
            context(@"Environment", ^{
                beforeEach(^{
                    [environmentTruncator enableTruncationWithResult:truncatedDictionary
                                                     bytesTruncated:dictionaryBytesTruncated];
                    virtualMachineInfo = [factory virtualMachineInfoForErrorDetails:errorDetails
                                                                     bytesTruncated:&bytesTruncated];
                });
                it(@"Should have correct environment", ^{
                    [[virtualMachineInfo.environment should] equal:truncatedDictionary];
                });
                it(@"Should fill bytes truncated", ^{
                    [[theValue(bytesTruncated) should] equal:theValue(dictionaryBytesTruncated)];
                });
            });
            context(@"Several truncations", ^{
                beforeEach(^{
                    [shortStringTruncator enableTruncationWithResult:truncatedPlatform
                                                         forArgument:platform
                                                      bytesTruncated:platformBytesTruncated];
                    [shortStringTruncator enableTruncationWithResult:truncatedVirtualMachineVersion
                                                         forArgument:virtualMachineVersion
                                                      bytesTruncated:virtualMachineVersionBytesTruncated];
                    [environmentTruncator enableTruncationWithResult:truncatedDictionary
                                                      bytesTruncated:dictionaryBytesTruncated];
                    virtualMachineInfo = [factory virtualMachineInfoForErrorDetails:errorDetails
                                                                     bytesTruncated:&bytesTruncated];
                });
                it(@"Should fill bytes truncated", ^{
                    [[theValue(bytesTruncated) should] equal:theValue(dictionaryBytesTruncated
                        + platformBytesTruncated + virtualMachineVersionBytesTruncated)];
                });
            });

        });

    });

});

SPEC_END
