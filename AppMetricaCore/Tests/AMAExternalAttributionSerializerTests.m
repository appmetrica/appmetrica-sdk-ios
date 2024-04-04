#import <XCTest/XCTest.h>

#import "AMAExternalAttributionSerializer.h"
#import "ClientExternalAttribution.pb-c.h"

@interface AMAExternalAttributionSerializerTests : XCTestCase

@property (nonatomic, strong) AMAExternalAttributionSerializer *serializer;
@property (nonatomic, strong) NSDictionary *validData;
@property (nonatomic, strong) NSDictionary *expectedAttributionTypes;

@end

@implementation AMAExternalAttributionSerializerTests

- (void)setUp
{
    [super setUp];
    self.serializer = [[AMAExternalAttributionSerializer alloc] init];
    self.validData = @{@"key": @"value"};
    self.expectedAttributionTypes = @{
        kAMAAttributionSourceAppsflyer: @(AMA__CLIENT_EXTERNAL_ATTRIBUTION__ATTRIBUTION_TYPE__APPSFLYER),
        kAMAAttributionSourceAdjust: @(AMA__CLIENT_EXTERNAL_ATTRIBUTION__ATTRIBUTION_TYPE__ADJUST),
        kAMAAttributionSourceKochava: @(AMA__CLIENT_EXTERNAL_ATTRIBUTION__ATTRIBUTION_TYPE__KOCHAVA),
        kAMAAttributionSourceTenjin: @(AMA__CLIENT_EXTERNAL_ATTRIBUTION__ATTRIBUTION_TYPE__TENJIN),
        kAMAAttributionSourceAirbridge: @(AMA__CLIENT_EXTERNAL_ATTRIBUTION__ATTRIBUTION_TYPE__AIRBRIDGE),
        @"UnknownSDK": @(AMA__CLIENT_EXTERNAL_ATTRIBUTION__ATTRIBUTION_TYPE__UNKNOWN)
    };
}

- (void)testSerializationSuccessForValidData
{
    NSError *error = nil;
    NSData *serializedData = [self.serializer serializeExternalAttribution:self.validData
                                                                    source:kAMAAttributionSourceAppsflyer
                                                                     error:&error];
    XCTAssertNotNil(serializedData, @"Serialization should succeed with valid data.");
    XCTAssertNil(error, @"No error should be present when serialization succeeds with valid data.");
}

- (void)testAttributionSourceSerialization
{
    for (NSString *source in self.expectedAttributionTypes.allKeys) {
        NSError *error = nil;
        NSData *serializedData = [self.serializer serializeExternalAttribution:self.validData
                                                                        source:source
                                                                         error:&error];
        XCTAssertNotNil(serializedData, @"Serialized data should not be nil for source %@.", source);
        XCTAssertNil(error, @"Error should be nil for source %@.", source);
        
        Ama__ClientExternalAttribution *message = ama__client_external_attribution__unpack(NULL,
                                                                                           serializedData.length,
                                                                                           serializedData.bytes);
        XCTAssertTrue(message->has_attribution_type, @"Attribution type should be present.");
        NSNumber *expectedType = self.expectedAttributionTypes[source];
        XCTAssertEqual(message->attribution_type, expectedType.intValue,
                       @"Attribution type for source %@ does not match expected value.", source);
        ama__client_external_attribution__free_unpacked(message, NULL);
    }
}

- (void)testDataIntegrityInSerialization
{
    NSString *source = kAMAAttributionSourceAppsflyer;
    NSError *error = nil;
    NSData *serializedData = [self.serializer serializeExternalAttribution:self.validData
                                                                    source:source
                                                                     error:&error];
    
    Ama__ClientExternalAttribution *message = ama__client_external_attribution__unpack(NULL,
                                                                                       serializedData.length,
                                                                                       serializedData.bytes);
    XCTAssertNotEqual(message, NULL, @"Deserialized message should not be nil.");
    
    if (message->has_value) {
        NSData *jsonData = [NSData dataWithBytes:message->value.data length:message->value.len];
        NSError *jsonError = nil;
        NSDictionary *deserializedData = [NSJSONSerialization JSONObjectWithData:jsonData options:0
                                                                           error:&jsonError];
        XCTAssertNil(jsonError, @"JSON deserialization error should be nil.");
        XCTAssertEqualObjects(deserializedData, self.validData,
                              @"The deserialized JSON should match the original data.");
    }
    else {
        XCTFail(@"Serialized message should contain data.");
    }
    
    ama__client_external_attribution__free_unpacked(message, NULL);
}

#ifdef DEBUG
- (void)testErrorHandlingForInvalidJSON
{
    NSDictionary *invalidData = @{@"invalid": [NSDate date]};
    XCTAssertThrowsSpecificNamed([self.serializer serializeExternalAttribution:invalidData
                                                                        source:kAMAAttributionSourceAppsflyer
                                                                         error:nil],
                                 NSException,
                                 NSInternalInconsistencyException,
                                 @"Attempting to serialize invalid JSON should trigger an assertion failure.");
}
#else
- (void)testErrorHandlingForInvalidJSON
{
    NSDictionary *invalidData = @{@"invalid": [NSDate date]};
    NSError *error = nil;
    NSData *serializedData = [self.serializer serializeExternalAttribution:invalidData
                                                                    source:kAMAAttributionSourceAppsflyer
                                                                     error:&error];
    XCTAssertNil(serializedData, @"Serialized data should be nil for invalid input.");
    XCTAssertNotNil(error, @"Error should be populated for invalid data input.");
}
#endif

@end
