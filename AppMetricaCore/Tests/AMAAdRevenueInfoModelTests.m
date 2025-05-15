
#import <Kiwi/Kiwi.h>
#import "AMAAdRevenueInfoModel.h"

SPEC_BEGIN(AMAAdRevenueInfoModelTests)

describe(@"AMAAdRevenueInfoModel", ^{

    NSDecimalNumber *const amount = [NSDecimalNumber decimalNumberWithString:@"23.34"];
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
    BOOL const isAutocollected = YES;

    AMAAdRevenueInfoModel *__block model = nil;

    beforeEach(^{
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
                                               bytesTruncated:bytesTruncated
                                              isAutocollected:isAutocollected];
    });

    it(@"Should store amount", ^{
        [[model.amount should] equal:amount];
    });
    it(@"Should store currency", ^{
        [[model.currency should] equal:currency];
    });
    it(@"Should store adType", ^{
        [[theValue(model.adType) should] equal:theValue(adType)];
    });
    it(@"Should store adNetwork", ^{
        [[model.adNetwork should] equal:adNetwork];
    });
    it(@"Should store adUnitID", ^{
        [[model.adUnitID should] equal:adUnitID];
    });
    it(@"Should store adUnitName", ^{
        [[model.adUnitName should] equal:adUnitName];
    });
    it(@"Should store adPlacementID", ^{
        [[model.adPlacementID should] equal:adPlacementID];
    });
    it(@"Should store adPlacementName", ^{
        [[model.adPlacementName should] equal:adPlacementName];
    });
    it(@"Should store precision", ^{
        [[model.precision should] equal:precision];
    });
    it(@"Should store payloadString", ^{
        [[model.payloadString should] equal:payloadString];
    });
    it(@"Should store bytesTruncated", ^{
        [[theValue(model.bytesTruncated) should] equal:theValue(bytesTruncated)];
    });
    it(@"Should store isAutocollected", ^{
        [[theValue(model.isAutocollected) should] equal:theValue(isAutocollected)];
    });
    
});

SPEC_END
