#import <XCTest/XCTest.h>
#import "AMABacktraceSymbolicator.h"
#import "AMABacktrace.h"
#import "AMABacktraceFrame.h"
#import "AMABinaryImage.h"
#import "AMAKSCrashImports.h"

/// XCTest `measure` harness for local before/after of small symbolicator tweaks.
/// Not a CI gate: compare Performance Report / average duration between runs on the same device.
@interface AMABacktraceSymbolicatorPerformanceTests : XCTestCase
@end

@implementation AMABacktraceSymbolicatorPerformanceTests

static const NSUInteger kMaxFrames = 200;
static const NSUInteger kLongFrames = 100;
static const NSUInteger kBurstStackCount = 40;
static const NSUInteger kContendedWorkers = 8;

static bool AMAFailingDLAddr(const uintptr_t address, Dl_info *const info)
{
    (void)address;
    (void)info;
    return false;
}

#pragma mark - Fixtures

- (NSArray<NSNumber *> *)realCallStackAddresses
{
    return NSThread.callStackReturnAddresses;
}

/// Pads/truncates a real stack to `count` by cycling frames (many hits in the same images).
- (NSArray<NSNumber *> *)addressesByRepeatingStack:(NSArray<NSNumber *> *)seed
                                           toCount:(NSUInteger)count
{
    XCTAssertGreaterThan(seed.count, 0U);

    NSMutableArray<NSNumber *> *result = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++) {
        [result addObject:seed[i % seed.count]];
    }
    return [result copy];
}

- (NSArray<NSNumber *> *)addressesByRepeatingRealStackToCount:(NSUInteger)count
{
    return [self addressesByRepeatingStack:[self realCallStackAddresses] toCount:count];
}

/// Addresses for the failing-`dladdr` path: real frames so `sharedImages` still resolves images
/// (linear scan per frame — the expensive fallback).
- (NSArray<NSNumber *> *)addressesForFailingDladdrPathToCount:(NSUInteger)count
{
    return [self addressesByRepeatingRealStackToCount:count];
}

/// Alternates real frames with unmapped addresses → mix of dladdr hits and full misses.
- (NSArray<NSNumber *> *)addressesMixedRealAndUnmappedToCount:(NSUInteger)count
{
    NSArray<NSNumber *> *seed = [self realCallStackAddresses];
    XCTAssertGreaterThan(seed.count, 0U);

    NSMutableArray<NSNumber *> *result = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++) {
        if ((i % 2) == 0) {
            [result addObject:seed[i % seed.count]];
        }
        else {
            [result addObject:@(0x1000ULL + (i * 0x40ULL))];
        }
    }
    return [result copy];
}

/// Per-worker stacks: rotate the seed so workers cannot silently swap identical results.
- (NSArray<NSArray<NSNumber *> *> *)distinctWorkerStacksWithFrameCount:(NSUInteger)frameCount
                                                           workerCount:(NSUInteger)workerCount
{
    NSArray<NSNumber *> *seed = [self realCallStackAddresses];
    XCTAssertGreaterThan(seed.count, 1U);

    NSMutableArray<NSArray<NSNumber *> *> *stacks = [NSMutableArray arrayWithCapacity:workerCount];
    for (NSUInteger worker = 0; worker < workerCount; worker++) {
        NSMutableArray<NSNumber *> *rotated = [NSMutableArray arrayWithCapacity:seed.count];
        for (NSUInteger i = 0; i < seed.count; i++) {
            [rotated addObject:seed[(i + worker) % seed.count]];
        }
        [stacks addObject:[self addressesByRepeatingStack:rotated toCount:frameCount]];
    }
    return [stacks copy];
}

- (AMABacktrace *)symbolicate:(AMABacktraceSymbolicator *)symbolicator
                    addresses:(NSArray<NSNumber *> *)addresses
                 binaryImages:(NSSet<AMABinaryImage *> * __autoreleasing *)binaryImages
{
    return [symbolicator backtraceForInstructionAddresses:addresses binaryImages:binaryImages];
}

- (AMABacktrace *)symbolicate:(AMABacktraceSymbolicator *)symbolicator
                    addresses:(NSArray<NSNumber *> *)addresses
{
    NSSet *binaryImages = nil;
    return [self symbolicate:symbolicator addresses:addresses binaryImages:&binaryImages];
}

- (void)assertSymbolicated:(AMABacktrace *)backtrace
              binaryImages:(NSSet<AMABinaryImage *> *)binaryImages
            expectedFrames:(NSUInteger)expectedFrames
{
    XCTAssertNotNil(backtrace);
    XCTAssertEqual(backtrace.frames.count, expectedFrames);
    XCTAssertGreaterThan(binaryImages.count, 0U);
    for (AMABacktraceFrame *frame in backtrace.frames) {
        XCTAssertNotNil(frame.instructionAddress);
        XCTAssertNotNil(frame.objectAddress);
    }
}

- (void)setUp
{
    [super setUp];
    ksbic_init();
}

#pragma mark - Cases

/// Baseline: short real stack (contrast for the heavy cases below).
- (void)testMeasure_shortRealStack
{
    NSArray<NSNumber *> *addresses = [self realCallStackAddresses];
    AMABacktraceSymbolicator *symbolicator = [[AMABacktraceSymbolicator alloc] init];
    NSSet<AMABinaryImage *> *binaryImages = nil;
    AMABacktrace *warm = [self symbolicate:symbolicator addresses:addresses binaryImages:&binaryImages];
    [self assertSymbolicated:warm binaryImages:binaryImages expectedFrames:addresses.count];

    [self measureBlock:^{
        NSSet<AMABinaryImage *> *images = nil;
        AMABacktrace *backtrace = [self symbolicate:symbolicator addresses:addresses binaryImages:&images];
        XCTAssertEqual(backtrace.frames.count, addresses.count);
        XCTAssertGreaterThan(images.count, 0U);
    }];
}

/// Long stack, frames recycled from one capture → repeated binary images (local per-backtrace cache).
- (void)testMeasure_longStack_repeatedImages_200
{
    NSArray<NSNumber *> *addresses = [self addressesByRepeatingRealStackToCount:kMaxFrames];
    AMABacktraceSymbolicator *symbolicator = [[AMABacktraceSymbolicator alloc] init];
    NSSet<AMABinaryImage *> *binaryImages = nil;
    AMABacktrace *warm = [self symbolicate:symbolicator addresses:addresses binaryImages:&binaryImages];
    [self assertSymbolicated:warm binaryImages:binaryImages expectedFrames:kMaxFrames];

    [self measureBlock:^{
        NSSet<AMABinaryImage *> *images = nil;
        AMABacktrace *backtrace = [self symbolicate:symbolicator addresses:addresses binaryImages:&images];
        XCTAssertEqual(backtrace.frames.count, kMaxFrames);
        XCTAssertGreaterThan(images.count, 0U);
    }];
}

/// Same shape at production max depth, fresh symbolicator each iteration (cold image cache).
- (void)testMeasure_longStack_repeatedImages_200_coldSymbolicator
{
    NSArray<NSNumber *> *addresses = [self addressesByRepeatingRealStackToCount:kMaxFrames];
    NSSet<AMABinaryImage *> *binaryImages = nil;
    AMABacktrace *warm = [self symbolicate:[[AMABacktraceSymbolicator alloc] init]
                                 addresses:addresses
                              binaryImages:&binaryImages];
    [self assertSymbolicated:warm binaryImages:binaryImages expectedFrames:kMaxFrames];

    [self measureBlock:^{
        AMABacktraceSymbolicator *symbolicator = [[AMABacktraceSymbolicator alloc] init];
        NSSet<AMABinaryImage *> *images = nil;
        AMABacktrace *backtrace = [self symbolicate:symbolicator addresses:addresses binaryImages:&images];
        XCTAssertEqual(backtrace.frames.count, kMaxFrames);
        XCTAssertGreaterThan(images.count, 0U);
    }];
}

/// Half real / half unmapped → mix of dladdr hits and misses.
- (void)testMeasure_longStack_mixedDladdrAndUnmapped_200
{
    NSArray<NSNumber *> *addresses = [self addressesMixedRealAndUnmappedToCount:kMaxFrames];
    AMABacktraceSymbolicator *symbolicator = [[AMABacktraceSymbolicator alloc] init];
    NSSet<AMABinaryImage *> *binaryImages = nil;
    AMABacktrace *warm = [self symbolicate:symbolicator addresses:addresses binaryImages:&binaryImages];
    [self assertSymbolicated:warm binaryImages:binaryImages expectedFrames:kMaxFrames];

    [self measureBlock:^{
        NSSet<AMABinaryImage *> *images = nil;
        AMABacktrace *backtrace = [self symbolicate:symbolicator addresses:addresses binaryImages:&images];
        XCTAssertEqual(backtrace.frames.count, kMaxFrames);
        XCTAssertGreaterThan(images.count, 0U);
    }];
}

/// All frames go through failing dladdr → sharedImages linear scan per frame.
- (void)testMeasure_longStack_allFailingDladdr_200
{
    NSArray<NSNumber *> *addresses = [self addressesForFailingDladdrPathToCount:kMaxFrames];
    AMABacktraceSymbolicator *symbolicator =
        [[AMABacktraceSymbolicator alloc] initWithDLAddrFunction:AMAFailingDLAddr];
    NSSet<AMABinaryImage *> *binaryImages = nil;
    AMABacktrace *warm = [self symbolicate:symbolicator addresses:addresses binaryImages:&binaryImages];
    [self assertSymbolicated:warm binaryImages:binaryImages expectedFrames:kMaxFrames];

    [self measureBlock:^{
        NSSet<AMABinaryImage *> *images = nil;
        AMABacktrace *backtrace = [self symbolicate:symbolicator addresses:addresses binaryImages:&images];
        XCTAssertEqual(backtrace.frames.count, kMaxFrames);
        XCTAssertGreaterThan(images.count, 0U);
    }];
}

/// Many sequential symbolizations (error-flood shape on one thread).
- (void)testMeasure_burst_40stacks_of_100_repeatedImages
{
    NSArray<NSNumber *> *addresses = [self addressesByRepeatingRealStackToCount:kLongFrames];
    AMABacktraceSymbolicator *symbolicator = [[AMABacktraceSymbolicator alloc] init];
    NSSet<AMABinaryImage *> *binaryImages = nil;
    AMABacktrace *warm = [self symbolicate:symbolicator addresses:addresses binaryImages:&binaryImages];
    [self assertSymbolicated:warm binaryImages:binaryImages expectedFrames:kLongFrames];

    [self measureBlock:^{
        for (NSUInteger i = 0; i < kBurstStackCount; i++) {
            NSSet<AMABinaryImage *> *images = nil;
            AMABacktrace *backtrace = [self symbolicate:symbolicator addresses:addresses binaryImages:&images];
            XCTAssertEqual(backtrace.frames.count, kLongFrames);
            XCTAssertGreaterThan(images.count, 0U);
        }
    }];
}

/// Same burst on the failing-dladdr path.
- (void)testMeasure_burst_40stacks_of_100_failingDladdr
{
    NSArray<NSNumber *> *addresses = [self addressesForFailingDladdrPathToCount:kLongFrames];
    AMABacktraceSymbolicator *symbolicator =
        [[AMABacktraceSymbolicator alloc] initWithDLAddrFunction:AMAFailingDLAddr];
    NSSet<AMABinaryImage *> *binaryImages = nil;
    AMABacktrace *warm = [self symbolicate:symbolicator addresses:addresses binaryImages:&binaryImages];
    [self assertSymbolicated:warm binaryImages:binaryImages expectedFrames:kLongFrames];

    [self measureBlock:^{
        for (NSUInteger i = 0; i < kBurstStackCount; i++) {
            NSSet<AMABinaryImage *> *images = nil;
            AMABacktrace *backtrace = [self symbolicate:symbolicator addresses:addresses binaryImages:&images];
            XCTAssertEqual(backtrace.frames.count, kLongFrames);
            XCTAssertGreaterThan(images.count, 0U);
        }
    }];
}

/// Parallel workers share one symbolicator → lock / cache contention.
- (void)testMeasure_contended_8workers_sharedSymbolicator_100
{
    NSArray<NSArray<NSNumber *> *> *workerStacks =
        [self distinctWorkerStacksWithFrameCount:kLongFrames workerCount:kContendedWorkers];
    AMABacktraceSymbolicator *symbolicator = [[AMABacktraceSymbolicator alloc] init];
    NSMutableArray<NSNumber *> *expectedTopAddresses =
        [NSMutableArray arrayWithCapacity:kContendedWorkers];
    for (NSArray<NSNumber *> *addresses in workerStacks) {
        NSSet<AMABinaryImage *> *binaryImages = nil;
        AMABacktrace *warm = [self symbolicate:symbolicator addresses:addresses binaryImages:&binaryImages];
        [self assertSymbolicated:warm binaryImages:binaryImages expectedFrames:kLongFrames];
        [expectedTopAddresses addObject:warm.frames.firstObject.instructionAddress];
    }

    [self measureBlock:^{
        dispatch_group_t group = dispatch_group_create();
        dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
        NSMutableArray *results = [NSMutableArray arrayWithCapacity:kContendedWorkers];
        NSMutableArray *imageSets = [NSMutableArray arrayWithCapacity:kContendedWorkers];
        for (NSUInteger i = 0; i < kContendedWorkers; i++) {
            [results addObject:[NSNull null]];
            [imageSets addObject:[NSNull null]];
        }
        NSObject *resultsLock = [[NSObject alloc] init];

        for (NSUInteger i = 0; i < kContendedWorkers; i++) {
            NSArray<NSNumber *> *addresses = workerStacks[i];
            dispatch_group_async(group, queue, ^{
                NSSet<AMABinaryImage *> *images = nil;
                AMABacktrace *backtrace = [self symbolicate:symbolicator
                                                  addresses:addresses
                                               binaryImages:&images];
                @synchronized (resultsLock) {
                    results[i] = backtrace ?: (id)[NSNull null];
                    imageSets[i] = images ?: [NSSet set];
                }
            });
        }
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

        for (NSUInteger i = 0; i < kContendedWorkers; i++) {
            AMABacktrace *backtrace = results[i];
            XCTAssertTrue([backtrace isKindOfClass:[AMABacktrace class]],
                          @"worker %lu returned nil/invalid backtrace", (unsigned long)i);
            XCTAssertEqual(backtrace.frames.count, kLongFrames,
                           @"worker %lu frame count", (unsigned long)i);
            XCTAssertGreaterThan([imageSets[i] count], 0U,
                                 @"worker %lu binaryImages", (unsigned long)i);
            XCTAssertEqualObjects(backtrace.frames.firstObject.instructionAddress,
                                  expectedTopAddresses[i],
                                  @"worker %lu mixed results with another stack", (unsigned long)i);
        }
    }];
}

/// Contended + failing dladdr (lock + expensive sharedImages).
- (void)testMeasure_contended_8workers_failingDladdr_100
{
    NSArray<NSArray<NSNumber *> *> *workerStacks =
        [self distinctWorkerStacksWithFrameCount:kLongFrames workerCount:kContendedWorkers];
    AMABacktraceSymbolicator *symbolicator =
        [[AMABacktraceSymbolicator alloc] initWithDLAddrFunction:AMAFailingDLAddr];
    NSMutableArray<NSNumber *> *expectedTopAddresses =
        [NSMutableArray arrayWithCapacity:kContendedWorkers];
    for (NSArray<NSNumber *> *addresses in workerStacks) {
        NSSet<AMABinaryImage *> *binaryImages = nil;
        AMABacktrace *warm = [self symbolicate:symbolicator addresses:addresses binaryImages:&binaryImages];
        [self assertSymbolicated:warm binaryImages:binaryImages expectedFrames:kLongFrames];
        [expectedTopAddresses addObject:warm.frames.firstObject.instructionAddress];
    }

    [self measureBlock:^{
        dispatch_group_t group = dispatch_group_create();
        dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
        NSMutableArray *results = [NSMutableArray arrayWithCapacity:kContendedWorkers];
        NSMutableArray *imageSets = [NSMutableArray arrayWithCapacity:kContendedWorkers];
        for (NSUInteger i = 0; i < kContendedWorkers; i++) {
            [results addObject:[NSNull null]];
            [imageSets addObject:[NSNull null]];
        }
        NSObject *resultsLock = [[NSObject alloc] init];

        for (NSUInteger i = 0; i < kContendedWorkers; i++) {
            NSArray<NSNumber *> *addresses = workerStacks[i];
            dispatch_group_async(group, queue, ^{
                NSSet<AMABinaryImage *> *images = nil;
                AMABacktrace *backtrace = [self symbolicate:symbolicator
                                                  addresses:addresses
                                               binaryImages:&images];
                @synchronized (resultsLock) {
                    results[i] = backtrace ?: (id)[NSNull null];
                    imageSets[i] = images ?: [NSSet set];
                }
            });
        }
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

        for (NSUInteger i = 0; i < kContendedWorkers; i++) {
            AMABacktrace *backtrace = results[i];
            XCTAssertTrue([backtrace isKindOfClass:[AMABacktrace class]],
                          @"worker %lu returned nil/invalid backtrace", (unsigned long)i);
            XCTAssertEqual(backtrace.frames.count, kLongFrames,
                           @"worker %lu frame count", (unsigned long)i);
            XCTAssertGreaterThan([imageSets[i] count], 0U,
                                 @"worker %lu binaryImages", (unsigned long)i);
            XCTAssertEqualObjects(backtrace.frames.firstObject.instructionAddress,
                                  expectedTopAddresses[i],
                                  @"worker %lu mixed results with another stack", (unsigned long)i);
        }
    }];
}

@end
