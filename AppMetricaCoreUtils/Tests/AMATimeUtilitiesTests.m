#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

@interface AMATimeUtilitiesTests : XCTestCase

@end

@implementation AMATimeUtilitiesTests

- (void)testIntervalWithNumber
{
    NSNumber *number = [NSNumber numberWithInt:14];
    
    XCTAssertEqual([AMATimeUtilities intervalWithNumber:number defaultInterval:1],
                   [AMANumberUtilities doubleWithNumber:number defaultValue:1],
                   @"Should return interval");
}

- (void)testTimestampForDate
{
    NSDate *date = [NSDate date];
    NSString *expected = [NSString stringWithFormat:@"%llu", (uint64_t)[date timeIntervalSince1970]];
    
    XCTAssertEqualObjects([AMATimeUtilities timestampForDate:date], expected, @"Should return string timestamp");
}

- (void)testTimeSinceFirstStartupUpdate
{
    NSDate *firstStartupUpdateDate = [NSDate dateWithTimeIntervalSince1970:42];
    NSDate *lastStartupUpdateDate = [NSDate date];
    NSNumber *lastServerTimeOffset = [NSNumber numberWithInt:21];
    
    NSTimeInterval result = [AMATimeUtilities timeSinceFirstStartupUpdate:firstStartupUpdateDate
                                                    lastStartupUpdateDate:lastStartupUpdateDate
                                                     lastServerTimeOffset:lastServerTimeOffset];
    
    NSTimeInterval expected = [[lastStartupUpdateDate dateByAddingTimeInterval:[lastServerTimeOffset doubleValue]]
                               timeIntervalSinceDate:firstStartupUpdateDate];
    
    XCTAssertEqual(result, expected, @"Should return correct timeSinceFirstStartupUpdate");
    
    
    lastStartupUpdateDate = [NSDate dateWithTimeIntervalSince1970:1];
    
    result = [AMATimeUtilities timeSinceFirstStartupUpdate:firstStartupUpdateDate
                                     lastStartupUpdateDate:lastStartupUpdateDate
                                      lastServerTimeOffset:lastServerTimeOffset];
    
    XCTAssertEqual(result, 0, @"Should return 0 if result is negative");
}

- (void)testUnixTimestampNumberFromDate
{
    NSDate *now = [NSDate date];
    NSNumber *timestampNumber = [AMATimeUtilities unixTimestampNumberFromDate:now];
    NSTimeInterval expectedTimestamp = [now timeIntervalSince1970];
    XCTAssertEqualWithAccuracy([timestampNumber doubleValue], expectedTimestamp,
                               0.001, @"The unix timestamp number from date should match the expected value.");
}

- (void)testDateFromUnixTimestampNumber
{
    NSNumber *timestampNumber = @(1609459200); // Example Unix timestamp for January 1, 2021, 00:00:00 GMT
    NSDate *expectedDate = [NSDate dateWithTimeIntervalSince1970:[timestampNumber doubleValue]];
    NSDate *resultDate = [AMATimeUtilities dateFromUnixTimestampNumber:timestampNumber];
    XCTAssertEqualWithAccuracy([resultDate timeIntervalSince1970], [expectedDate timeIntervalSince1970],
                               0.001, @"The date from unix timestamp number should match the expected date.");
}

@end
