
#import <Kiwi/Kiwi.h>
#import "AMACore.h"
#import "AMAAdRevenueInfoModelSerializer.h"
#import "AdRevenue.pb-c.h"
#import "AMAAdRevenueInfoModel.h"
#import "AMAAdRevenueInfoMutableModel.h"
#import "AMAStringEventValue.h"
#import "AMABinaryEventValue.h"
#import "AMAECommerce.h"
#import "AMAECommerceSerializer.h"
#import <AppMetricaProtobufUtils/AppMetricaProtobufUtils.h>

SPEC_BEGIN(AMAAdRevenueInfoModelSerializerTests)

describe(@"AMAAdRevenueInfoModelSerializer", ^{

    AMAProtobufAllocator *__block allocator = nil;
    Ama__AdRevenue *__block adRevenue = NULL;
    AMAAdRevenueInfoModel *__block model = nil;
    AMAAdRevenueInfoModelSerializer *__block serializer = nil;
    NSString *const dataSource = @"manual";

    beforeEach(^{
        serializer = [[AMAAdRevenueInfoModelSerializer alloc] init];
    });

    beforeAll(^{
        allocator = [[AMAProtobufAllocator alloc] init];
    });

    __auto_type serializeAndDeserializeModel = ^(AMAAdRevenueInfoModel *model) {
        NSData *data = [serializer dataWithAdRevenueInfoModel:model];
        return ama__ad_revenue__unpack([allocator protobufCAllocator], data.length, data.bytes);
    };

    __auto_type stringForBinary = ^(ProtobufCBinaryData *binaryData) {
        NSData *data = [NSData dataWithBytes:binaryData->data length:binaryData->len];
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    };

    context(@"Empty model", ^{
        beforeAll(^{
            model = [[AMAAdRevenueInfoModel alloc] initWithAmount:nil
                                                         currency:nil
                                                           adType:AMAAdTypeUnknown
                                                        adNetwork:nil
                                                         adUnitID:nil
                                                       adUnitName:nil
                                                    adPlacementID:nil
                                                  adPlacementName:nil
                                                        precision:nil
                                                    payloadString:nil
                                                   bytesTruncated:0];
            adRevenue = serializeAndDeserializeModel(model);
        });
        it(@"Should fill data_source", ^{
            [[stringForBinary(&(adRevenue->data_source)) should] equal:dataSource];
        });
        it(@"Should not have decimal value", ^{
            [[thePointerValue(adRevenue->ad_revenue) should] equal:thePointerValue(NULL)];
        });

        it(@"Should not fill has_currency", ^{
            [[theValue(adRevenue->has_currency) should] beNo];
        });
        it(@"Should not fill currency", ^{
            [[stringForBinary(&(adRevenue->currency)) should] beEmpty];
        });

        it(@"Should not fill has_precision", ^{
            [[theValue(adRevenue->has_precision) should] beNo];
        });
        it(@"Should not fill precision", ^{
            [[stringForBinary(&(adRevenue->precision)) should] beEmpty];
        });

        it(@"Should not fill has_ad_network", ^{
            [[theValue(adRevenue->has_ad_network) should] beNo];
        });
        it(@"Should not fill ad_network", ^{
            [[stringForBinary(&(adRevenue->ad_network)) should] beEmpty];
        });

        it(@"Should not fill has_ad_unit_id", ^{
            [[theValue(adRevenue->has_ad_unit_id) should] beNo];
        });
        it(@"Should not fill ad_unit_id", ^{
            [[stringForBinary(&(adRevenue->ad_unit_id)) should] beEmpty];
        });

        it(@"Should not fill has_ad_unit_name", ^{
            [[theValue(adRevenue->has_ad_unit_name) should] beNo];
        });
        it(@"Should not fill ad_unit_name", ^{
            [[stringForBinary(&(adRevenue->ad_unit_name)) should] beEmpty];
        });

        it(@"Should fill has_ad_type", ^{
            [[theValue(adRevenue->has_ad_type) should] beYes];
        });
        it(@"Should fill ad_type", ^{
            [[theValue(adRevenue->ad_type) should] equal:theValue(AMA__AD_REVENUE__AD_TYPE__UNKNOWN)];
        });

        it(@"Should not fill has_ad_placement_id", ^{
            [[theValue(adRevenue->has_ad_placement_id) should] beNo];
        });
        it(@"Should not fill ad_placement_id", ^{
            [[stringForBinary(&(adRevenue->ad_placement_id)) should] beEmpty];
        });

        it(@"Should not fill has_ad_placement_name", ^{
            [[theValue(adRevenue->has_ad_placement_name) should] beNo];
        });
        it(@"Should not fill ad_placement_name", ^{
            [[stringForBinary(&(adRevenue->ad_placement_name)) should] beEmpty];
        });

        it(@"Should not fill has_payload", ^{
            [[theValue(adRevenue->has_payload) should] beNo];
        });
        it(@"Should not fill payload", ^{
            [[stringForBinary(&(adRevenue->payload)) should] beEmpty];
        });
    });

    context(@"Complete model", ^{
        NSDecimalNumber *const amount = [NSDecimalNumber decimalNumberWithString:@"23.34"
                                                                          locale:@{ NSLocaleDecimalSeparator: @"."}];
        NSString *const currency = @"BYN";
        AMAAdType const adType = AMAAdTypeBanner;
        NSString *const adNetwork = @"ad_network";
        NSString *const adUnitID = @"ad_unit_id";
        NSString *const adUnitName = @"ad_unit_name";
        NSString *const adPlacementID = @"ad_placement_id";
        NSString *const adPlacementName = @"ad_placement_name";
        NSString *const precision = @"precision";
        NSString *const payloadString = @"{\"key\":\"value\"}";
        NSUInteger const bytesTruncated = 121;

        beforeAll(^{
            model = [[AMAAdRevenueInfoModel alloc] initWithAmount:amount
                                                         currency:currency
                                                           adType:adType
                                                        adNetwork:adNetwork
                                                         adUnitID:adUnitID
                                                       adUnitName:adUnitName
                                                    adPlacementID:adPlacementID
                                                  adPlacementName:adPlacementName
                                                        precision:precision
                                                    payloadString:payloadString
                                                   bytesTruncated:bytesTruncated];
            adRevenue = serializeAndDeserializeModel(model);
        });
        it(@"Should fill data_source", ^{
            [[stringForBinary(&(adRevenue->data_source)) should] equal:dataSource];
        });
        context(@"Should have decimal value", ^{
            it(@"Should have mantissa", ^{
                [[theValue(adRevenue->ad_revenue->has_mantissa) should] beYes];
            });
            it(@"Should have exponent", ^{
                [[theValue(adRevenue->ad_revenue->has_exponent) should] beYes];
            });
            it(@"Should have valid decimal value", ^{
                Ama__AdRevenue__Decimal *decimal = adRevenue->ad_revenue;
                NSDecimalNumber *decimalNumber =
                [NSDecimalNumber decimalNumberWithMantissa:(unsigned long long)ABS(decimal->mantissa)
                                                  exponent:decimal->exponent
                                                isNegative:decimal->mantissa < 0];
                [[decimalNumber should] equal:amount];
            });
        });

        it(@"Should fill has_currency", ^{
            [[theValue(adRevenue->has_currency) should] beYes];
        });
        it(@"Should fill currency", ^{
            [[stringForBinary(&(adRevenue->currency)) should] equal:currency];
        });

        it(@"Should fill has_precision", ^{
            [[theValue(adRevenue->has_precision) should] beYes];
        });
        it(@"Should fill precision", ^{
            [[stringForBinary(&(adRevenue->precision)) should] equal:precision];
        });

        it(@"Should fill has_ad_network", ^{
            [[theValue(adRevenue->has_ad_network) should] beYes];
        });
        it(@"Should fill ad_network", ^{
            [[stringForBinary(&(adRevenue->ad_network)) should] equal:adNetwork];
        });

        it(@"Should fill has_ad_type", ^{
            [[theValue(adRevenue->has_ad_type) should] beYes];
        });
        it(@"Should fill ad_type", ^{
            [[theValue(adRevenue->ad_type) should] equal:theValue(AMA__AD_REVENUE__AD_TYPE__BANNER)];
        });

        it(@"Should fill has_ad_unit_id", ^{
            [[theValue(adRevenue->has_ad_unit_id) should] beYes];
        });
        it(@"Should fill ad_unit_id", ^{
            [[stringForBinary(&(adRevenue->ad_unit_id)) should] equal:adUnitID];
        });

        it(@"Should fill has_ad_unit_name", ^{
            [[theValue(adRevenue->has_ad_unit_name) should] beYes];
        });
        it(@"Should fill ad_unit_name", ^{
            [[stringForBinary(&(adRevenue->ad_unit_name)) should] equal:adUnitName];
        });

        it(@"Should fill has_ad_placement_id", ^{
            [[theValue(adRevenue->has_ad_placement_id) should] beYes];
        });
        it(@"Should fill has_ad_placement_id", ^{
            [[stringForBinary(&(adRevenue->ad_placement_id)) should] equal:adPlacementID];
        });

        it(@"Should fill has_ad_placement_name", ^{
            [[theValue(adRevenue->has_ad_placement_name) should] beYes];
        });
        it(@"Should fill ad_placement_name", ^{
            [[stringForBinary(&(adRevenue->ad_placement_name)) should] equal:adPlacementName];
        });
        it(@"Should fill has_payload", ^{
            [[theValue(adRevenue->has_payload) should] beYes];
        });
        it(@"Should fill payload", ^{
            [[stringForBinary(&(adRevenue->payload)) should] equal:payloadString];
        });
    });

});

SPEC_END
