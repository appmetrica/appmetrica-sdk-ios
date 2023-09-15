
#import <XCTest/XCTest.h>
#import "AMADateLogMessageFormatter.h"
#import "AMALogMessage.h"

@interface AMADateLogMessageFormatterTests : XCTestCase

@end

@implementation AMADateLogMessageFormatterTests

- (void)setUp
{
    [super setUp];
}

- (void)testFormatter
{
    AMADateLogMessageFormatter *formatter =
        [[AMADateLogMessageFormatter alloc] init];
    
    AMALogMessage *__block message = nil;
    NSDate *timestamp = nil;
    NSString *result = nil;
    void(^buildMessage)(NSDate *) = ^(NSDate *date) {
        message = [[AMALogMessage alloc] initWithContent:@"test content"
                                                   level:AMALogLevelInfo
                                                 channel:nil
                                                    file:nil
                                                function:nil
                                                    line:0
                                               backtrace:nil
                                               timestamp:date];
    };
    
    timestamp = [NSDate dateWithTimeIntervalSince1970:31415926535];
    buildMessage(timestamp);
    result = [formatter messageToString:message];
    XCTAssertEqualObjects(result, @"09:15:35:000");
    
    timestamp = [NSDate dateWithTimeIntervalSince1970:1694768291];
    buildMessage(timestamp);
    result = [formatter messageToString:message];
    XCTAssertEqualObjects(result, @"11:58:11:000");
}

- (void)testConformance
{
    AMADateLogMessageFormatter *formatter =
        [[AMADateLogMessageFormatter alloc] init];
    
    XCTAssertTrue([formatter conformsToProtocol:@protocol(AMALogMessageFormatting)],
                  @"Should conform to AMALogMessageFormatting");
}

@end
