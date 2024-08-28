
#import <Kiwi/Kiwi.h>
#import "AMACore.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAAdRevenueInfoConverter.h"
#import "AMAAdRevenueInfoModel.h"
#import "AMAAdRevenueInfo.h"
#import "AMAAppMetrica.h"

SPEC_BEGIN(AMAAdRevenueInfoConverterTests)

describe(@"AMAAdRevenueInfoConverter", ^{

    NSDecimalNumber *amount = [[NSDecimalNumber alloc] initWithString:@"19.01"];
    NSString *const currency = @"USD";
    AMAAdType const adType = AMAAdTypeNative;
    NSString *const adNetwork = @"network";
    NSString *const adUnitID = @"666-999";
    NSString *const adUnitName = @"ad unit name";
    NSString *const adPlacementID = @"555-777";
    NSString *const adPlacementName = @"ad placement name";
    NSString *const precision = @"precision";
    NSDictionary *const payload = @{ @"foo": @"bar" };
    NSString *const expectedPayloadString = @"{\"foo\":\"bar\"}";

    NSError *__block error = nil;

    AMAMutableAdRevenueInfo *__block adRevenueInfo = nil;
    AMAAdRevenueInfoModel *__block converted = nil;

    beforeEach(^{
        adRevenueInfo = [[AMAMutableAdRevenueInfo alloc] initWithAdRevenue:amount
                                                                  currency:currency];
        adRevenueInfo.adType = adType;
        adRevenueInfo.adNetwork = adNetwork;
        adRevenueInfo.adUnitID = adUnitID;
        adRevenueInfo.adUnitName = adUnitName;
        adRevenueInfo.adPlacementID = adPlacementID;
        adRevenueInfo.adPlacementName = adPlacementName;
        adRevenueInfo.precision = precision;
        adRevenueInfo.payload = payload;

        converted = [AMAAdRevenueInfoConverter convertAdRevenueInfo:adRevenueInfo error:&error];
    });

    context(@"All fields", ^{
        it(@"Should convert amount decimal", ^{
            [[converted.amount should] equal:adRevenueInfo.adRevenue];
        });
        it(@"Should convert currency", ^{
            [[converted.currency should] equal:adRevenueInfo.currency];
        });
        it(@"Should convert adNetwork", ^{
            [[converted.adNetwork should] equal:adRevenueInfo.adNetwork];
        });
        it(@"Should convert unit ID", ^{
            [[converted.adUnitID should] equal:adRevenueInfo.adUnitID];
        });
        it(@"Should convert unit name", ^{
            [[converted.adUnitName should] equal:adRevenueInfo.adUnitName];
        });
        it(@"Should convert placement ID", ^{
            [[converted.adPlacementID should] equal:adRevenueInfo.adPlacementID];
        });
        it(@"Should convert placement name", ^{
            [[converted.adPlacementName should] equal:adRevenueInfo.adPlacementName];
        });
        it(@"Should convert precision", ^{
            [[converted.precision should] equal:adRevenueInfo.precision];
        });
        it(@"Should convert payload", ^{
            [[converted.payloadString should] equal:expectedPayloadString];
        });
        it(@"Bytes truncated should be zero", ^{
            [[theValue(converted.bytesTruncated) should] beZero];
        });
        it(@"Should not fill error", ^{
            [[error should] beNil];
        });
    });

    context(@"Payload", ^{
        NSDictionary *const payload = @{ @"key": @"value" };
        NSString *const expectedPayloadString = @"{\"key\":\"value\"}";
        beforeEach(^{
            adRevenueInfo.payload = payload;
        });
        context(@"Valid payload", ^{
            it(@"Should return model with valid value", ^{
                [[[AMAAdRevenueInfoConverter convertAdRevenueInfo:adRevenueInfo error:nil].payloadString should]
                 equal:expectedPayloadString];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [AMAAdRevenueInfoConverter convertAdRevenueInfo:adRevenueInfo error:&error];
                [[error should] beNil];
            });
        });
        context(@"Non-JSON", ^{
            NSDictionary *const payload = @{ @[ @"foo", @"bar" ]: @"bar" };
            beforeEach(^{
                [AMATestUtilities stubAssertions];
                adRevenueInfo.payload = payload;
            });
            it(@"Should fill error", ^{
                NSString *desription =
                @"Passed dictionary is not a valid serializable JSON object: {\n    \"Wrong JSON object\" ="
                "     {\n                (\n            foo,\n            bar\n        ) = bar;\n    };\n}";
                NSError *expectedError = [NSError errorWithDomain:kAMAAppMetricaInternalErrorDomain
                                                             code:AMAAppMetricaInternalEventJsonSerializationError
                                                         userInfo:@{ NSLocalizedDescriptionKey: desription }];
                NSError *error = nil;
                AMAAdRevenueInfoModel *result = [AMAAdRevenueInfoConverter convertAdRevenueInfo:adRevenueInfo error:&error];
                [[result.payloadString should] beNil];
                [[error should] equal:expectedError];
            });
        });
    });
});

SPEC_END
