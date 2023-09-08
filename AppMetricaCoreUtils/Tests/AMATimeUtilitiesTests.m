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

@end
