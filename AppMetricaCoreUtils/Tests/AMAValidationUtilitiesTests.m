#import <XCTest/XCTest.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

@interface AMAValidationUtilitiesTests : XCTestCase

@end

@implementation AMAValidationUtilitiesTests

- (void)testValidateISO4217Currency
{
    XCTAssertFalse([AMAValidationUtilities validateISO4217Currency:@"US"], @"Should return false if currency length is invalid");

    XCTAssertFalse([AMAValidationUtilities validateISO4217Currency:@"usd"], @"Should return false if currency contains lowercase letters");
    
    XCTAssertTrue([AMAValidationUtilities validateISO4217Currency:@"USD"], @"Should return true for valid currency");
}

- (void)testValidateJSONDictionary
{
    __auto_type validator = ^BOOL(NSString *obj) {
        return YES;
    };
    
    BOOL isValid = [AMAValidationUtilities validateJSONDictionary:@{@1 : @""}
                                                       valueClass:NSString.class
                                          valueStructureValidator:validator];
    XCTAssertFalse(isValid, @"Should return false if key is not string");
    
    
    isValid = [AMAValidationUtilities validateJSONDictionary:@{@"key" : @{}}
                                                       valueClass:NSString.class
                                          valueStructureValidator:nil];
    XCTAssertFalse(isValid, @"Should return false if value is kind of incorrect type");
    
    isValid = [AMAValidationUtilities validateJSONDictionary:@{@"foo": @[@"bar"]}
                                                  valueClass:NSArray.class
                                     valueStructureValidator:validator];
    XCTAssertTrue(isValid, @"Should return true for valid dictionary");
    
    
    isValid = [AMAValidationUtilities validateJSONDictionary:@{@"key1" : @9,
                                                               @"key2" : @"value"}
                                                       valueClass:NSString.class
                                          valueStructureValidator:validator];
    XCTAssertFalse(isValid, @"Should return false if dictionary contains incorrect values");
    
    
    isValid = [AMAValidationUtilities validateJSONDictionary:@{}
                                                       valueClass:NSString.class
                                          valueStructureValidator:validator];
    XCTAssertTrue(isValid, @"Should return true for empty dictionary");
    
    
    validator = ^BOOL(NSString *obj) {
        return [obj isEqual:@"value2"];
    };
    isValid = [AMAValidationUtilities validateJSONDictionary:@{@"key1" : @"value1",
                                                               @"key2" : @"value2"}
                                                       valueClass:NSString.class
                                          valueStructureValidator:validator];
    XCTAssertFalse(isValid, @"Should return false if validator failed");
}

- (void)testValidateJSONArray
{
    BOOL isValid = [AMAValidationUtilities validateJSONArray:@[]
                                                  valueClass:NSString.class];
    XCTAssertTrue(isValid, @"Should return true for empty array");
    
    isValid = [AMAValidationUtilities validateJSONArray:@[@3, @"foo"]
                                             valueClass:NSString.class];
    XCTAssertFalse(isValid, @"Should return false if value is kind of incorrect type");
    
    isValid = [AMAValidationUtilities validateJSONArray:@[@3, @99]
                                             valueClass:NSNumber.class];
    XCTAssertTrue(isValid, @"Should return true for valid array");
}

@end
