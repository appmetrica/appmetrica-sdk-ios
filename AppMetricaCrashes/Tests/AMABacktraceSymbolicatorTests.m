
#import <Kiwi/Kiwi.h>
#import "AMABacktraceSymbolicator.h"
#import "AMABacktrace.h"
#import "AMABacktraceFrame.h"
#import "AMABinaryImage.h"

static NSArray *fooA()
{
    NSLog(@"Log to extend function size");
    return NSThread.callStackReturnAddresses;
}

static NSArray *fooB()
{
    NSLog(@"Log to prevent optimizations");
    return fooA();
}

static bool failingDLAddr(const uintptr_t address, Dl_info* const info)
{
    return false;
}

static bool dlAddrWithoutSymbol(const uintptr_t address, Dl_info* const info)
{
    bool result = dladdr((const void *)address, info);
    info->dli_saddr = 0;
    info->dli_sname = NULL;
    return result;
}

SPEC_BEGIN(AMABacktraceSymbolicatorTests)

describe(@"AMABacktraceSymbolicator", ^{

    NSSet *__block binaryImages = nil;
    AMABacktrace *__block backtrace = nil;
    AMABacktraceSymbolicator *__block symbolicator = nil;

    beforeEach(^{
        binaryImages = nil;
        symbolicator = [[AMABacktraceSymbolicator alloc] init];
    });

    context(@"Real backtrace", ^{
        beforeEach(^{
            backtrace = [symbolicator backtraceForInstructionAddresses:fooB() binaryImages:&binaryImages];
        });
        it(@"Should have at least 3 frames", ^{
            [[backtrace.frames should] haveCountOfAtLeast:3];
        });
        context(@"Top frame", ^{
            AMABacktraceFrame *__block frame = nil;
            beforeEach(^{
                frame = backtrace.frames.firstObject;
            });
            it(@"Should have valid instruction address", ^{
                unsigned long long value = frame.instructionAddress.unsignedLongLongValue;
                [[theValue(value) should] beInTheIntervalFrom:theValue((uintptr_t)&fooA + 1)
                                                           to:theValue((uintptr_t)&fooA + 100)];
            });
            it(@"Should have valid object name", ^{
                [[frame.objectName should] equal:@"AppMetricaCrashesTests"];
            });
            it(@"Should have valid object address", ^{
                unsigned long long value = frame.objectAddress.unsignedLongLongValue;
                [[theValue(value) should] beInTheIntervalFrom:theValue(1)
                                                           to:theValue((uintptr_t)&fooA - 1)];
            });
            it(@"Should have valid symbol name", ^{
                [[frame.symbolName should] equal:@"fooA"];
            });
            it(@"Should have valid symbol address", ^{
                [[frame.symbolAddress should] equal:@((uintptr_t)&fooA)];
            });
            it(@"Should not be stripped", ^{
                [[theValue(frame.stripped) should] beNo];
            });
            it(@"Should have no line of code", ^{
                [[frame.lineOfCode should] beNil];
            });
        });
        context(@"Second frame", ^{
            AMABacktraceFrame *__block frame = nil;
            beforeEach(^{
                frame = backtrace.frames[1];
            });
            it(@"Should have valid instruction address", ^{
                unsigned long long value = frame.instructionAddress.unsignedLongLongValue;
                [[theValue(value) should] beInTheIntervalFrom:theValue((uintptr_t)&fooB + 1)
                                                           to:theValue((uintptr_t)&fooB + 100)];
            });
            it(@"Should have valid object name", ^{
                [[frame.objectName should] equal:@"AppMetricaCrashesTests"];
            });
            it(@"Should have valid object address", ^{
                unsigned long long value = frame.objectAddress.unsignedLongLongValue;
                [[theValue(value) should] beInTheIntervalFrom:theValue(1)
                                                           to:theValue((uintptr_t)&fooB - 1)];
            });
            it(@"Should have valid symbol name", ^{
                [[frame.symbolName should] equal:@"fooB"];
            });
            it(@"Should have valid symbol address", ^{
                [[frame.symbolAddress should] equal:@((uintptr_t)&fooB)];
            });
            it(@"Should not be stripped", ^{
                [[theValue(frame.stripped) should] beNo];
            });
            it(@"Should have no line of code", ^{
                [[frame.lineOfCode should] beNil];
            });
        });
        context(@"Third frame", ^{
            AMABacktraceFrame *__block frame = nil;
            beforeEach(^{
                frame = backtrace.frames[2];
            });
            it(@"Should have valid instruction address", ^{
                unsigned long long value = frame.instructionAddress.unsignedLongLongValue;
                [[theValue(value) should] beGreaterThan:theValue(frame.symbolAddress.unsignedLongLongValue)];
            });
            it(@"Should have valid object name", ^{
                [[frame.objectName should] equal:@"AppMetricaCrashesTests"];
            });
            it(@"Should have valid object address", ^{
                unsigned long long value = frame.objectAddress.unsignedLongLongValue;
                [[theValue(value) should] beGreaterThan:theValue(1)];
            });
            it(@"Should have valid symbol name", ^{
                [[frame.symbolName should] containString:NSStringFromClass([self class])];
            });
            it(@"Should have valid symbol address", ^{
                unsigned long long value = frame.symbolAddress.unsignedLongLongValue;
                [[theValue(value) should] beGreaterThan:theValue(frame.objectAddress.unsignedLongLongValue)];
            });
            it(@"Should not be stripped", ^{
                [[theValue(frame.stripped) should] beNo];
            });
            it(@"Should have no line of code", ^{
                [[frame.lineOfCode should] beNil];
            });
        });
        context(@"Images", ^{
            it(@"Should have non-empty images set", ^{
                [[binaryImages shouldNot] beEmpty];
            });
            context(@"Tests image", ^{
                AMABinaryImage *__block image = nil;
                beforeEach(^{
                    NSArray<AMABinaryImage *> *allImages = binaryImages.allObjects;
                    NSUInteger instructionAddress = (NSUInteger)&fooA;
                    NSUInteger index =
                        [allImages indexOfObjectPassingTest:^BOOL(AMABinaryImage *obj, NSUInteger idx, BOOL *stop) {
                            return obj.address <= instructionAddress && instructionAddress < obj.address + obj.size;
                        }];
                    image = index != NSNotFound ? allImages[index] : nil;
                });
                it(@"Should not be nil", ^{
                    [[image shouldNot] beNil];
                });
                it(@"Should have UUID", ^{
                    [[image.UUID shouldNot] beNil];
                });
                it(@"Should have valid name", ^{
                    [[image.name.lastPathComponent should] equal:@"AppMetricaCrashesTests"];
                });
                it(@"Should have valid address", ^{
                    NSUInteger expectedValue = backtrace.frames.firstObject.objectAddress.unsignedIntegerValue;
                    [[theValue(image.address) should] equal:theValue(expectedValue)];
                });
            });
        });
    });

    context(@"Invalid backtrace", ^{
        it(@"Should return nil for empty backtrace", ^{
            backtrace = [symbolicator backtraceForInstructionAddresses:@[] binaryImages:&binaryImages];
            [[backtrace should] beNil];
        });
        context(@"Invalid objects in addresses", ^{
            NSArray *addresses = @[
                @"string",
                @[ @"array" ],
                @((uintptr_t)&fooA + 4), // We skip 4 bytes because arm64 has instruction size of 4 bytes
                @{ @"dictionary": @"obj" },
                [NSNull null],
            ];
            beforeEach(^{
                backtrace = [symbolicator backtraceForInstructionAddresses:addresses binaryImages:&binaryImages];
            });
            it(@"Should have one frame", ^{
                [[backtrace.frames should] haveCountOf:1];
            });
            it(@"Should have valid frame", ^{
                [[backtrace.frames.firstObject.symbolName should] equal:@"fooA"];
            });
        });
    });

    context(@"Failing dladdr", ^{
        beforeEach(^{
            symbolicator = [[AMABacktraceSymbolicator alloc] initWithDLAddrFunction:failingDLAddr];
            backtrace = [symbolicator backtraceForInstructionAddresses:fooB() binaryImages:&binaryImages];
        });

        it(@"Should have at least 3 frames", ^{
            [[backtrace.frames should] haveCountOfAtLeast:3];
        });
        context(@"Top frame", ^{
            AMABacktraceFrame *__block frame = nil;
            beforeEach(^{
                frame = backtrace.frames.firstObject;
            });
            it(@"Should have valid instruction address", ^{
                unsigned long long value = frame.instructionAddress.unsignedLongLongValue;
                [[theValue(value) should] beInTheIntervalFrom:theValue((uintptr_t)&fooA + 1)
                                                           to:theValue((uintptr_t)&fooA + 100)];
            });
            it(@"Should have valid object name", ^{
                [[frame.objectName should] equal:@"AppMetricaCrashesTests"];
            });
            it(@"Should have valid object address", ^{
                unsigned long long value = frame.objectAddress.unsignedLongLongValue;
                [[theValue(value) should] beInTheIntervalFrom:theValue(1)
                                                           to:theValue((uintptr_t)&fooA - 1)];
            });
            it(@"Should have no symbol name", ^{
                [[frame.symbolName should] beNil];
            });
            it(@"Should have no symbol address", ^{
                [[frame.symbolAddress should] beNil];
            });
            it(@"Should be stripped", ^{
                [[theValue(frame.stripped) should] beYes];
            });
            it(@"Should have no line of code", ^{
                [[frame.lineOfCode should] beNil];
            });
        });
    });

    context(@"dladdr without symbol", ^{
        beforeEach(^{
            symbolicator = [[AMABacktraceSymbolicator alloc] initWithDLAddrFunction:dlAddrWithoutSymbol];
            backtrace = [symbolicator backtraceForInstructionAddresses:fooB() binaryImages:&binaryImages];
        });

        it(@"Should have at least 3 frames", ^{
            [[backtrace.frames should] haveCountOfAtLeast:3];
        });
        context(@"Top frame", ^{
            AMABacktraceFrame *__block frame = nil;
            beforeEach(^{
                frame = backtrace.frames.firstObject;
            });
            it(@"Should have valid instruction address", ^{
                unsigned long long value = frame.instructionAddress.unsignedLongLongValue;
                [[theValue(value) should] beInTheIntervalFrom:theValue((uintptr_t)&fooA + 1)
                                                           to:theValue((uintptr_t)&fooA + 100)];
            });
            it(@"Should have valid object name", ^{
                [[frame.objectName should] equal:@"AppMetricaCrashesTests"];
            });
            it(@"Should have valid object address", ^{
                unsigned long long value = frame.objectAddress.unsignedLongLongValue;
                [[theValue(value) should] beInTheIntervalFrom:theValue(1)
                                                           to:theValue((uintptr_t)&fooA - 1)];
            });
            it(@"Should have no symbol name", ^{
                [[frame.symbolName should] beNil];
            });
            it(@"Should have no symbol address", ^{
                [[frame.symbolAddress should] beNil];
            });
            it(@"Should be stripped", ^{
                [[theValue(frame.stripped) should] beYes];
            });
            it(@"Should have no line of code", ^{
                [[frame.lineOfCode should] beNil];
            });
        });
    });

});

SPEC_END
