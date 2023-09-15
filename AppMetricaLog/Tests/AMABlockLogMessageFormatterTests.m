
#import <XCTest/XCTest.h>
#import "AMABlockLogMessageFormatter.h"
#import "AMALogMessage.h"

@interface AMABlockLogMessageFormatterTests : XCTestCase

@property (nonatomic, strong) AMALogMessage *message;

@end

@implementation AMABlockLogMessageFormatterTests

- (void)setUp
{
    [super setUp];
    self.message = [[AMALogMessage alloc] initWithContent:@"test content"
                                                    level:AMALogLevelInfo
                                                  channel:nil
                                                     file:nil
                                                 function:nil
                                                     line:0
                                                backtrace:nil
                                                timestamp:[NSDate date]];
}

- (void)testFormatter
{
    AMABlockLogMessageFormatter *formatter =
            [[AMABlockLogMessageFormatter alloc] initWithFormatterBlock:^NSString *(AMALogMessage *message) {
                return message.content;
            }];
    NSString *string = [formatter messageToString:self.message];
    XCTAssertEqualObjects(string, @"test content");
}

- (void)testConformance
{
    AMABlockLogMessageFormatter *formatter =
        [[AMABlockLogMessageFormatter alloc] init];
    
    XCTAssertTrue([formatter conformsToProtocol:@protocol(AMALogMessageFormatting)],
                  @"Should conform to AMALogMessageFormatting");
}

@end
