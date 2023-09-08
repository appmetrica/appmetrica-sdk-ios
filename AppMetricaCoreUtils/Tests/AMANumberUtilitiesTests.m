#import <XCTest/XCTest.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

@interface AMANumberUtilitiesTests : XCTestCase

@end

@implementation AMANumberUtilitiesTests

- (void)testUnsignedIntegerForNumber
{
    NSNumber *const number = [NSNumber numberWithInt:-17];
    
    XCTAssertEqual([AMANumberUtilities unsignedIntegerForNumber:nil defaultValue:42], 42, @"Should return default value if number is nil");
    
    XCTAssertEqual([AMANumberUtilities unsignedIntegerForNumber:number defaultValue:42], [number unsignedIntegerValue], @"Should return unsigned int value");
}

- (void)testDoubleWithNumber
{
    NSNumber *const number = [NSNumber numberWithInt:18];
    
    XCTAssertEqual([AMANumberUtilities doubleWithNumber:nil defaultValue:42], 42, @"Should return default value if number is nil");
    
    XCTAssertEqual([AMANumberUtilities doubleWithNumber:number defaultValue:42], number.doubleValue, @"Should return double value");
}

- (void)testBoolForNumber
{
    NSNumber *const number = [NSNumber numberWithInt:19];
    
    XCTAssertEqual([AMANumberUtilities boolForNumber:nil defaultValue:NO], NO, @"Should return default value if number is nil");
    
    XCTAssertEqual([AMANumberUtilities boolForNumber:number defaultValue:YES], [number boolValue], @"Should return bool value");
}

@end
