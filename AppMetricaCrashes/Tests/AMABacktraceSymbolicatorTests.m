
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMABacktraceSymbolicator.h"
#import "AMABacktrace.h"
#import "AMABacktraceFrame.h"
#import "AMABinaryImage.h"
#import "AMAKSCrashImports.h"

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
        
        ksbic_init();
    });

    context(@"Real backtrace", ^{
        beforeEach(^{
            backtrace = [symbolicator backtraceForInstructionAddresses:fooB() binaryImages:&binaryImages];
        });
        it(@"Should have at least 3 frames", ^{
            [[backtrace.frames should] haveCountOfAtLeast:3];
        });
        context(@"Top frame", ^{
            AMABacktraceFrame * __block frame = nil;
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
            AMABacktraceFrame * __block frame = nil;
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
            AMABacktraceFrame * __block frame = nil;
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
        it(@"Should resolve binary images via shared images fallback", ^{
            [[binaryImages should] haveCountOfAtLeast:1];
        });
        context(@"Top frame", ^{
            AMABacktraceFrame * __block frame = nil;
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

    context(@"Repeated addresses in one backtrace", ^{
        it(@"Should keep consistent binary images for recycled frames", ^{
            NSArray *seed = fooB();
            NSMutableArray *addresses = [NSMutableArray arrayWithCapacity:50];
            // Recycle only the top frames from our test binary (not XCTest frames deeper in the stack).
            NSUInteger recycleCount = MIN((NSUInteger)3, seed.count);
            for (NSUInteger i = 0; i < 50; i++) {
                [addresses addObject:seed[i % recycleCount]];
            }
            backtrace = [symbolicator backtraceForInstructionAddresses:addresses binaryImages:&binaryImages];
            [[backtrace.frames should] haveCountOf:50];
            [[binaryImages should] haveCountOfAtLeast:1];
            [[backtrace.frames.firstObject.objectName should] equal:@"AppMetricaCrashesTests"];
            [[backtrace.frames.lastObject.objectName should] equal:@"AppMetricaCrashesTests"];
        });

        it(@"Should resolve two distinct images for A→A→B→A without mixing cache entries", ^{
            // Return addresses so dladdr maps into two real images (test binary + Foundation).
            NSNumber *addressA = @((uintptr_t)&fooA + 4);
            NSNumber *addressB = @((uintptr_t)&NSLog + 4);
            NSArray *addresses = @[ addressA, addressA, addressB, addressA ];

            backtrace = [symbolicator backtraceForInstructionAddresses:addresses binaryImages:&binaryImages];

            [[backtrace.frames should] haveCountOf:4];
            [[binaryImages should] haveCountOf:2];

            NSNumber *objectA = backtrace.frames[0].objectAddress;
            NSNumber *objectB = backtrace.frames[2].objectAddress;
            [[objectA shouldNot] beNil];
            [[objectB shouldNot] beNil];
            [[objectA shouldNot] equal:objectB];
            [[backtrace.frames[1].objectAddress should] equal:objectA];
            [[backtrace.frames[3].objectAddress should] equal:objectA];

            AMABinaryImage *imageA = nil;
            AMABinaryImage *imageB = nil;
            for (AMABinaryImage *image in binaryImages) {
                if (image.address == objectA.unsignedIntegerValue) {
                    imageA = image;
                }
                else if (image.address == objectB.unsignedIntegerValue) {
                    imageB = image;
                }
            }
            [[imageA shouldNot] beNil];
            [[imageB shouldNot] beNil];
            [[imageA.UUID shouldNot] beNil];
            [[imageB.UUID shouldNot] beNil];
            [[theValue([imageA.UUID isEqualToString:imageB.UUID]) should] beNo];
            [[imageA.name.lastPathComponent should] equal:@"AppMetricaCrashesTests"];
        });
    });

    context(@"Unmapped address", ^{
        it(@"Should keep objectAddress @0 when no binary image is found", ^{
            // Low unmapped address: dladdr fails and sharedImages scan finds nothing.
            NSArray *addresses = @[ @0x1000ULL ];
            backtrace = [symbolicator backtraceForInstructionAddresses:addresses binaryImages:&binaryImages];
            [[backtrace.frames should] haveCountOf:1];
            [[backtrace.frames.firstObject.objectAddress should] equal:@0];
            [[backtrace.frames.firstObject.objectName should] beNil];
            [[binaryImages should] beEmpty];
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
            AMABacktraceFrame * __block frame = nil;
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
