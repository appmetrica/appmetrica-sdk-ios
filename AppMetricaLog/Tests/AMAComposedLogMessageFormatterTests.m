
#import <XCTest/XCTest.h>
#import "AMAComposedLogMessageFormatter.h"
#import "AMABlockLogMessageFormatter.h"
#import "AMALogMessage.h"

@interface AMAComposedLogMessageFormatterTests : XCTestCase

@property (nonatomic, strong) AMALogMessage *message;

@end

@implementation AMAComposedLogMessageFormatterTests

- (void)setUp
{
    [super setUp];
    self.message = [[AMALogMessage alloc] initWithContent:@"test content"
                                                    level:AMALogLevelInfo
                                                  channel:@"TestChannel"
                                                     file:@"test file"
                                                 function:@"test function"
                                                     line:10
                                                backtrace:@"backtrace"
                                                timestamp:[NSDate date]];
}

- (void)testEmptyFormatter
{
    AMAComposedLogMessageFormatter *formatter = [AMAComposedLogMessageFormatter new];
    NSString *string = [formatter messageToString:self.message];
    XCTAssertEqualObjects(string, @"");
}

- (void)testSingleFormatter
{
    AMABlockLogMessageFormatter *contentFormatter =
            [[AMABlockLogMessageFormatter alloc] initWithFormatterBlock:^NSString *(AMALogMessage *message) {
                return message.content;
            }];
    AMAComposedLogMessageFormatter *formatter =
            [[AMAComposedLogMessageFormatter alloc] initWithFormatters:@[contentFormatter]];
    NSString *string = [formatter messageToString:self.message];
    XCTAssertEqualObjects(string, @"test content");
}

- (void)testComposedFormatter
{
    AMABlockLogMessageFormatter *contentFormatter =
            [[AMABlockLogMessageFormatter alloc] initWithFormatterBlock:^NSString *(AMALogMessage *message) {
                return message.content;
            }];
    AMABlockLogMessageFormatter *fileFormatter =
            [[AMABlockLogMessageFormatter alloc] initWithFormatterBlock:^NSString *(AMALogMessage *message) {
                return message.file;
            }];
    AMAComposedLogMessageFormatter *formatter =
            [[AMAComposedLogMessageFormatter alloc] initWithFormatters:@[fileFormatter, contentFormatter]];
    NSString *string = [formatter messageToString:self.message];
    XCTAssertEqualObjects(string, @"test file test content");
}

- (void)testConformance
{
    AMAComposedLogMessageFormatter *formatter =
        [[AMAComposedLogMessageFormatter alloc] init];
    
    XCTAssertTrue([formatter conformsToProtocol:@protocol(AMALogMessageFormatting)],
                  @"Should conform to AMALogMessageFormatting");
}

@end
