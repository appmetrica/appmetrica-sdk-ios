
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAAppMetricaPreloadInfo+JSONSerializable.h"

@interface AMAAppMetricaPreloadInfo () <AMAJSONSerializable>

@property (nonatomic, copy, readwrite) NSString *trackingID;
@property (atomic, strong, readwrite) NSDictionary *additionalInfo;

@end

SPEC_BEGIN(AMAAppMetricaPreloadInfoTests)

describe(@"AMAAppMetricaPreloadInfo", ^{
    
    __block AMAAppMetricaPreloadInfo *preloadInfo = nil;
    __block NSString *trackingID = @"test-tracking-id";
    
    beforeEach(^{
        preloadInfo = [[AMAAppMetricaPreloadInfo alloc] initWithTrackingIdentifier:trackingID];
    });
    
    context(@"JSON Serialization", ^{
        it(@"should correctly serialize to JSON", ^{
            [preloadInfo setAdditionalInfo:@"info1" forKey:@"key1"];
            [preloadInfo setAdditionalInfo:@"info2" forKey:@"key2"];
            
            NSDictionary *json = [preloadInfo JSON];
            
            [[json[kAMATrackingID] should] equal:trackingID];
            [[json[kAMAAdditionalInfo][@"key1"] should] equal:@"info1"];
            [[json[kAMAAdditionalInfo][@"key2"] should] equal:@"info2"];
        });
        
        it(@"should return JSON with only trackingID if additionalInfo is nil", ^{
            NSDictionary *json = [preloadInfo JSON];
            
            [[json[kAMATrackingID] should] equal:trackingID];
            [[json[kAMAAdditionalInfo] should] beNil];
        });
    });
    
    context(@"JSON Deserialization", ^{
        it(@"should correctly initialize from valid JSON", ^{
            NSDictionary *json = @{
                kAMATrackingID: trackingID,
                kAMAAdditionalInfo: @{
                    @"key1": @"info1",
                    @"key2": @"info2"
                }
            };
            
            AMAAppMetricaPreloadInfo *deserializedInfo = [[AMAAppMetricaPreloadInfo alloc] initWithJSON:json];
            
            [[deserializedInfo.trackingID should] equal:trackingID];
            [[deserializedInfo.additionalInfo[@"key1"] should] equal:@"info1"];
            [[deserializedInfo.additionalInfo[@"key2"] should] equal:@"info2"];
        });
        
        it(@"should return nil for invalid JSON", ^{
            // Invalid JSON without tracking ID
            NSDictionary *invalidJson = @{
                kAMAAdditionalInfo: @{
                    @"key1": @"info1"
                }
            };
            
            AMAAppMetricaPreloadInfo *deserializedInfo = [[AMAAppMetricaPreloadInfo alloc] initWithJSON:invalidJson];
            [[deserializedInfo should] beNil];
        });
        
        it(@"should return nil for nil JSON", ^{
            AMAAppMetricaPreloadInfo *deserializedInfo = [[AMAAppMetricaPreloadInfo alloc] initWithJSON:nil];
            [[deserializedInfo should] beNil];
        });
        
        it(@"should handle JSON with no additionalInfo", ^{
            NSDictionary *json = @{ kAMATrackingID: trackingID };
            
            AMAAppMetricaPreloadInfo *deserializedInfo = [[AMAAppMetricaPreloadInfo alloc] initWithJSON:json];
            [[deserializedInfo.trackingID should] equal:trackingID];
            [[deserializedInfo.additionalInfo should] beNil];
        });
    });
    
});

SPEC_END
