#import <XCTest/XCTest.h>

#import <AppMetricaCore/AppMetricaCore.h>

#import "AMAExternalAttributionConfiguration.h"

@interface AMAExternalAttributionConfigurationTests : XCTestCase
@end

@implementation AMAExternalAttributionConfigurationTests

#pragma mark - Initialization

- (NSDate *)testDate
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = 2022;
    components.month = 1;
    components.day = 1;
    components.hour = 12;
    components.minute = 0;
    components.second = 0;
    components.nanosecond = 500000000;
    return  [calendar dateFromComponents:components];
}

- (void)testConfigurationShouldNotBeNil
{
    NSString *const contentsHash = @"testHash";
    AMAExternalAttributionConfiguration *config = [[AMAExternalAttributionConfiguration alloc] initWithSource:kAMAAttributionSourceAdjust
                                                                                                    timestamp:self.testDate
                                                                                                 contentsHash:contentsHash];
    
    XCTAssertNotNil(config, @"Configuration should not be nil");
}

- (void)testConfigurationShouldHaveCorrectSource
{
    NSString *const contentsHash = @"testHash";
    AMAExternalAttributionConfiguration *config = [[AMAExternalAttributionConfiguration alloc] initWithSource:kAMAAttributionSourceAdjust
                                                                                                    timestamp:self.testDate
                                                                                                 contentsHash:contentsHash];
    
    XCTAssertEqualObjects(config.source, kAMAAttributionSourceAdjust, @"Should have the correct source");
}

- (void)testConfigurationShouldHaveCorrectContentsHash
{
    NSString *const contentsHash = @"testHash";
    AMAExternalAttributionConfiguration *config = [[AMAExternalAttributionConfiguration alloc] initWithSource:kAMAAttributionSourceAdjust
                                                                                                    timestamp:self.testDate
                                                                                                 contentsHash:contentsHash];
    
    XCTAssertEqualObjects(config.contentsHash, contentsHash, @"Should have the correct contents hash");
}

- (void)testConfigurationShouldHaveNormalizedTimestamp
{
    NSString *const contentsHash = @"testHash";
    AMAExternalAttributionConfiguration *config = [[AMAExternalAttributionConfiguration alloc] initWithSource:kAMAAttributionSourceAdjust
                                                                                                    timestamp:self.testDate
                                                                                                 contentsHash:contentsHash];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *storedComponents = [calendar components:(NSCalendarUnitYear |
                                                               NSCalendarUnitMonth |
                                                               NSCalendarUnitDay |
                                                               NSCalendarUnitHour |
                                                               NSCalendarUnitMinute |
                                                               NSCalendarUnitSecond |
                                                               NSCalendarUnitNanosecond)
                                                     fromDate:config.timestamp];
    
    XCTAssertEqual(storedComponents.year, 2022);
    XCTAssertEqual(storedComponents.month, 1);
    XCTAssertEqual(storedComponents.day, 1);
    XCTAssertEqual(storedComponents.hour, 12);
    XCTAssertEqual(storedComponents.minute, 0);
    XCTAssertEqual(storedComponents.second, 0);
    XCTAssertEqual(storedComponents.nanosecond, 0);
}

- (void)testCustomSource
{
    NSString *const expectedSource = @"my_custom_sdk";
    AMAExternalAttributionConfiguration *config = [[AMAExternalAttributionConfiguration alloc] initWithSource:expectedSource
                                                                                                   timestamp:[NSDate date]
                                                                                                contentsHash:@"HASH"];
    
    XCTAssertNotNil(config, @"Configuration should not be nil");
    XCTAssertEqualObjects(config.source, expectedSource, @"Should have the correct source");
}

#pragma mark - JSON Serialization

- (void)testJSONSerializationAndDeserialization
{
    AMAExternalAttributionConfiguration *config = [[AMAExternalAttributionConfiguration alloc] initWithSource:kAMAAttributionSourceAdjust
                                                                                                   timestamp:[NSDate date]
                                                                                                contentsHash:@"HASH"];
    AMAExternalAttributionConfiguration *deserializedConfig = [[AMAExternalAttributionConfiguration alloc] initWithJSON:config.JSON];
    
    XCTAssertEqualObjects(config, deserializedConfig, @"Configuration should be equal on serialization and deserialization");
}

- (void)testConfigurationCreationFromJSON
{
    NSDictionary *const jsonDictionary = @{
        @"source": kAMAAttributionSourceAdjust,
        @"timestamp": @(1609459200), // Example Unix timestamp for January 1, 2021, 00:00:00 GMT
        @"contentsHash": @"exampleHash"
    };
    
    AMAExternalAttributionConfiguration *configFromJSON = [[AMAExternalAttributionConfiguration alloc] initWithJSON:jsonDictionary];
    
    XCTAssertNotNil(configFromJSON, @"Configuration created from JSON should not be nil");
    XCTAssertEqualObjects(configFromJSON.source, kAMAAttributionSourceAdjust);
    XCTAssertEqualObjects(configFromJSON.timestamp, [NSDate dateWithTimeIntervalSince1970:1609459200]);
    XCTAssertEqualObjects(configFromJSON.contentsHash, @"exampleHash");
}

- (void)testSerializationBackToOriginalJSON
{
    NSDictionary *const jsonDictionary = @{
        @"source": kAMAAttributionSourceAdjust,
        @"timestamp": @(1609459200), // Example Unix timestamp for January 1, 2021, 00:00:00 GMT
        @"contentsHash": @"exampleHash"
    };
    
    AMAExternalAttributionConfiguration *configFromJSON = [[AMAExternalAttributionConfiguration alloc] initWithJSON:jsonDictionary];
    NSDictionary *serializedJSON = [configFromJSON JSON];
    
    XCTAssertEqualObjects(serializedJSON, jsonDictionary, @"Serialized JSON should equal the original JSON dictionary");
}

#pragma mark - Invalid JSON

- (void)testConfigurationWithMissingSource
{
    NSDictionary *missingSourceJSON = @{
        @"timestamp": @(1609459200),
        @"contentsHash": @"missingSourceHash"
    };
    
    AMAExternalAttributionConfiguration *configMissingSource = [[AMAExternalAttributionConfiguration alloc] initWithJSON:missingSourceJSON];
    XCTAssertNil(configMissingSource, @"Configuration should be nil when 'source' is missing");
}

- (void)testConfigurationWithMissingTimestamp
{
    NSDictionary *missingTimestampJSON = @{
        @"source": kAMAAttributionSourceAdjust,
        @"contentsHash": @"missingTimestampHash"
    };
    
    AMAExternalAttributionConfiguration *configMissingTimestamp = [[AMAExternalAttributionConfiguration alloc] initWithJSON:missingTimestampJSON];
    XCTAssertNil(configMissingTimestamp, @"Configuration should be nil when 'timestamp' is missing");
}

- (void)testConfigurationWithMissingContentsHash
{
    NSDictionary *missingContentsHashJSON = @{
        @"source": kAMAAttributionSourceAdjust,
        @"timestamp": @(1609459200)
    };
    
    AMAExternalAttributionConfiguration *configMissingContentsHash = [[AMAExternalAttributionConfiguration alloc] initWithJSON:missingContentsHashJSON];
    XCTAssertNil(configMissingContentsHash, @"Configuration should be nil when 'contentsHash' is missing");
}

- (void)testConfigurationWithInvalidTimestampFormat
{
    NSDictionary *invalidTimestampJSON = @{
        @"source": kAMAAttributionSourceAdjust,
        @"timestamp": @"not-a-real-date",
        @"contentsHash": @"invalidTimestampHash"
    };
    
    AMAExternalAttributionConfiguration *configInvalidTimestamp = [[AMAExternalAttributionConfiguration alloc] initWithJSON:invalidTimestampJSON];
    XCTAssertNil(configInvalidTimestamp, @"Configuration should be nil when 'timestamp' format is invalid");
}

- (void)testConfigurationInitializationWithIncorrectDataTypes 
{
    NSDictionary *invalidTypeJSON = @{
        @"source": @12345,
        @"timestamp": @{@"year": @2020},
        @"contentsHash": @"hashValue"
    };
    
    AMAExternalAttributionConfiguration *config = [[AMAExternalAttributionConfiguration alloc] initWithJSON:invalidTypeJSON];
    XCTAssertNil(config, @"Configuration should be nil when initialized with incorrect data types in JSON");
}

- (void)testConfigurationWithEmptyJSON
{
    AMAExternalAttributionConfiguration *configFromEmptyJSON = [[AMAExternalAttributionConfiguration alloc] initWithJSON:@{}];
    XCTAssertNil(configFromEmptyJSON, @"Configuration should be nil when initialized with an empty JSON dictionary");
}

- (void)testConfigurationWithNullJSON
{
    AMAExternalAttributionConfiguration *configFromNullJSON = [[AMAExternalAttributionConfiguration alloc] initWithJSON:nil];
    XCTAssertNil(configFromNullJSON, @"Configuration should be nil when initialized with nil JSON");
}

@end
