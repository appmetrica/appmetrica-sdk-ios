#import <XCTest/XCTest.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@interface AMAJSONSerializationTests : XCTestCase

@property (nonatomic, strong) NSString *json;
@property (nonatomic, strong) NSDictionary *dict;
@property (nonatomic, strong) NSArray *array;
@property (nonatomic, strong) NSString *arrayJson;

@end

@implementation AMAJSONSerializationTests

- (void)setUp
{
    self.json = @"{\"key\":\"value\",\"a\":\"b\"}";
    self.dict = @{@"key" : @"value", @"a" : @"b"};
    self.array = @[@{@"key" : @"value", @"a" : @"b"}];
    self.arrayJson = @"[{\"key\":\"value\",\"a\":\"b\"}]";
}

- (void)testStringWithJSONObject
{
    NSString *valid = [AMAJSONSerialization stringWithJSONObject:self.dict error:nil];
    
    XCTAssertEqualObjects(valid, self.json, @"Should serialize dictionary to string");
    
    NSString *invalid = [AMAJSONSerialization stringWithJSONObject:nil error:nil];
    
    XCTAssertNil(invalid, @"Should return nil if failed to deserialize data from json");
    
    AMATestAssertionHandler *handler = [AMATestAssertionHandler new];
    [handler beginAssertIgnoring];

    NSError *error = nil;
    NSString *invalidWithError = [AMAJSONSerialization stringWithJSONObject:@"abc" error:&error];

    XCTAssertNil(invalidWithError, @"Should return nil if failed to serialize");
    XCTAssertEqualObjects(error.domain, kAMAAppMetricaInternalErrorDomain, @"Should fill error domain");
    XCTAssertEqual(error.code, AMAAppMetricaInternalEventJsonSerializationError, @"Should fill error code");
    XCTAssertEqualObjects(error.localizedDescription,
                          @"Passed dictionary is not a valid serializable JSON object: {\n    \"Wrong JSON object\" = abc;\n}",
                          @"Should have correct description");

    [handler endAssertIgnoring];
}

- (void)testDataWithJSONObject
{
    NSData *expected = [NSJSONSerialization dataWithJSONObject:self.dict options:0 error:nil];

    NSData *valid = [AMAJSONSerialization dataWithJSONObject:self.dict error:nil];

    XCTAssertEqualObjects(valid, expected, @"Should serialize dictionary to data");

    NSData *invalidEmpty = [AMAJSONSerialization dataWithJSONObject:nil error:nil];

    XCTAssertNil(invalidEmpty, @"Should return nil if json object is nil");

    AMATestAssertionHandler *handler = [AMATestAssertionHandler new];
    [handler beginAssertIgnoring];
    
    NSError *error = nil;
    NSData *invalidWithError = [AMAJSONSerialization dataWithJSONObject:@"abc" error:&error];
    
    XCTAssertNil(invalidWithError, @"Should return nil if failed to serialize");
    XCTAssertEqualObjects(error.domain, kAMAAppMetricaInternalErrorDomain, @"Should fill error domain");
    XCTAssertEqual(error.code, AMAAppMetricaInternalEventJsonSerializationError, @"Should fill error code");
    XCTAssertEqualObjects(error.localizedDescription,
                          @"Passed dictionary is not a valid serializable JSON object: {\n    \"Wrong JSON object\" = abc;\n}",
                          @"Should have correct description");
    
    [handler endAssertIgnoring];
}

- (void)testDictionaryWithJSONString
{
    NSDictionary *valid = [AMAJSONSerialization dictionaryWithJSONString:self.json error:nil];
    
    XCTAssertEqualObjects(valid, self.dict, @"Should serialize json to dictionary");
    
    NSDictionary *invalidEmpty = [AMAJSONSerialization dictionaryWithJSONString:nil error:nil];
    
    XCTAssertNil(invalidEmpty, @"Should return nil if json is nil");
    
    NSDictionary *invalidJson = [AMAJSONSerialization dictionaryWithJSONString:@"{key: \"value}" error:nil];
    
    XCTAssertNil(invalidJson, @"Should return nil if json is invalud");
}

- (void)testArrayWithJSONString
{
    NSArray *valid = [AMAJSONSerialization arrayWithJSONString:self.arrayJson error:nil];
    
    XCTAssertEqualObjects(valid, self.array, @"Should serialize json string to array");
    
    NSArray *invalid = [AMAJSONSerialization arrayWithJSONString:nil error:nil];
    
    XCTAssertNil(invalid, @"Should return nil if json string is nil");
}

- (void)testDictionaryWithJSONData
{
    NSData *serialized = [NSJSONSerialization dataWithJSONObject:self.dict options:0 error:nil];
    
    NSDictionary *valid = [AMAJSONSerialization dictionaryWithJSONData:serialized error:nil];
    
    XCTAssertEqualObjects(valid, self.dict, @"Should serialize json data to dictionary");
    
    NSDictionary *invalidEmpty = [AMAJSONSerialization dictionaryWithJSONData:nil error:nil];
    
    XCTAssertNil(invalidEmpty, @"Should return nil if data is nil");
    
    
    NSData *invalidSerialized = [NSJSONSerialization dataWithJSONObject:@[] options:0 error:nil];
    NSError *error = nil;
    NSDictionary *invalidData = [AMAJSONSerialization dictionaryWithJSONData:invalidSerialized error:&error];
    
    XCTAssertNil(invalidData, @"Should return nil if data is invalid");
    XCTAssertEqualObjects(error.domain, kAMAAppMetricaInternalErrorDomain, @"Should fill error domain");
    XCTAssertEqual(error.code, AMAAppMetricaInternalEventErrorCodeUnexpectedDeserialization, @"Should fill error code");
    XCTAssertNotNil(error.userInfo[kAMAAppMetricaInternalErrorResultObjectKey], @"Should contain value in userInfo");
}

- (void)testArrayWithJSONData
{
    NSData *serialized = [NSJSONSerialization dataWithJSONObject:self.array options:0 error:nil];
    
    NSArray *valid = [AMAJSONSerialization arrayWithJSONData:serialized error:nil];
    
    XCTAssertEqualObjects(valid, self.array, @"Should serialize json data to array");
    
    NSArray *invalid = [AMAJSONSerialization arrayWithJSONData:nil error:nil];
    
    XCTAssertNil(invalid, @"Should return nil if data is nil");
    
    
    NSData *invalidSerialized = [NSJSONSerialization dataWithJSONObject:@{} options:0 error:nil];
    NSError *error = nil;
    NSArray *invalidData = [AMAJSONSerialization arrayWithJSONData:invalidSerialized error:&error];
    
    XCTAssertNil(invalidData, @"Should return nil if data is invalid");
    XCTAssertEqualObjects(error.domain, kAMAAppMetricaInternalErrorDomain, @"Should fill error domain");
    XCTAssertEqual(error.code, AMAAppMetricaInternalEventErrorCodeUnexpectedDeserialization, @"Should fill error code");
    XCTAssertNotNil(error.userInfo[kAMAAppMetricaInternalErrorResultObjectKey], @"Should contain value in userInfo");
}

@end
