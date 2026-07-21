#import <XCTest/XCTest.h>
#import "Utilities/AMAModuleInvocationRecorder.h"

@interface AMAModuleInvocationRecorderTests : XCTestCase
@end

@implementation AMAModuleInvocationRecorderTests

- (void)testRecordsInvocationOrderAndResetsWithoutMutatingSnapshots
{
    AMAModuleInvocationRecorder *recorder = [AMAModuleInvocationRecorder new];

    [recorder recordInvocationFromClass:self.class selector:_cmd];
    [recorder recordInvocationWithName:@"custom.invocation"];
    NSArray<NSString *> *snapshot = recorder.invocations;
    NSString *expectedInvocation =
        @"AMAModuleInvocationRecorderTests.testRecordsInvocationOrderAndResetsWithoutMutatingSnapshots";

    XCTAssertEqualObjects(snapshot,
                          (@[
                              expectedInvocation,
                              @"custom.invocation",
                          ]));

    [recorder reset];

    XCTAssertEqualObjects(recorder.invocations, (@[]));
    XCTAssertEqualObjects(snapshot,
                          (@[
                              expectedInvocation,
                              @"custom.invocation",
                          ]));
}

@end
