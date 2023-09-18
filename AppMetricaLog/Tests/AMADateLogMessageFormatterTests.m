
#import <XCTest/XCTest.h>
#import "AMADateLogMessageFormatter.h"
#import "AMALogMessage.h"

@interface AMADateLogMessageFormatter ()
@property (nonatomic, strong) NSCalendar *calendar;
@end

@interface AMADateLogMessageFormatterTests : XCTestCase

@property (nonatomic, strong) AMADateLogMessageFormatter *formatter;

@end

@implementation AMADateLogMessageFormatterTests

- (void)setUp
{
    [super setUp];
    self.formatter = [[AMADateLogMessageFormatter alloc] init];
}

- (void)testFormatter
{
    self.formatter.calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    
    // Sat Jul 13 2965 06:15:35 GMT+0000
    [self assertLogMessageWithDate:[NSDate dateWithTimeIntervalSince1970:31415926535]
                         isEqualTo:@"06:15:35:000"];
    
    // Fri Sep 15 2023 11:58:11 GMT+0000
    [self assertLogMessageWithDate:[NSDate dateWithTimeIntervalSince1970:1694779091]
                         isEqualTo:@"11:58:11:000"];
}

- (void)testTimeZoneWithNextDay
{
    self.formatter.calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:12 * 3600];

    // Sat Jul 13 2965 06:15:35 GMT+0000
    [self assertLogMessageWithDate:[NSDate dateWithTimeIntervalSince1970:31415926535]
                         isEqualTo:@"18:15:35:000"];
    
    // Mon Sep 18 2023 16:01:23 GMT+0000
    [self assertLogMessageWithDate:[NSDate dateWithTimeIntervalSince1970:1695052883]
                         isEqualTo:@"04:01:23:000"];
}

- (void)testTimeZoneMinutes
{
    // 6.5 hours
    self.formatter.calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:6 * 3600 + 1800];

    
    // Sat Jul 13 2965 06:15:35 GMT+0000
    [self assertLogMessageWithDate:[NSDate dateWithTimeIntervalSince1970:31415926535]
                         isEqualTo:@"12:45:35:000"];

    // Mon Sep 18 2023 16:45:23 GMT+0000
    [self assertLogMessageWithDate:[NSDate dateWithTimeIntervalSince1970:1695055523]
                         isEqualTo:@"23:15:23:000"];
}

- (void)testConformance
{
    AMADateLogMessageFormatter *formatter =
        [[AMADateLogMessageFormatter alloc] init];
    
    XCTAssertTrue([formatter conformsToProtocol:@protocol(AMALogMessageFormatting)],
                  @"Should conform to AMALogMessageFormatting");
}

- (void)assertLogMessageWithDate:(NSDate*)date isEqualTo:(NSString*)text
{
    AMALogMessage *message = [[AMALogMessage alloc] initWithContent:@"test content"
                                                              level:AMALogLevelInfo
                                                            channel:nil
                                                               file:nil
                                                           function:nil
                                                               line:0
                                                          backtrace:nil
                                                          timestamp:date];
    NSString *result = [self.formatter messageToString:message];
    
    XCTAssertEqualObjects(result, text);
}

@end

