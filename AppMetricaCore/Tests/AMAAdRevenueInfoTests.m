
#import <Kiwi/Kiwi.h>
#import "AMAAdRevenueInfo.h"

SPEC_BEGIN(AMAAdRevenueInfoTests)

describe(@"AMAAdRevenueInfo", ^{

    NSDecimalNumber *price = [[NSDecimalNumber alloc] initWithString:@"345.21"];
    NSString *const currency = @"EUR";
    AMAAdType type = AMAAdTypeBanner;
    NSString *const adNetwork = @"some network";
    NSString *const adUnitID = @"666-999";
    NSString *const adUnitName = @"some unit name";
    NSString *const adPlacementID = @"555-777";
    NSString *const adPlacementName = @"some placement name";
    NSString *const precision = @"very precise";
    NSDictionary *payload = @{ @"key1" : @"value1", @"key2" : @"value2" };

    context(@"Immutable", ^{
        context(@"Minimal", ^{
            AMAAdRevenueInfo *__block adRevenue = nil;
            beforeEach(^{
                adRevenue = [[AMAAdRevenueInfo alloc] initWithAdRevenue:price currency:currency];
            });
            it(@"Should copy itself", ^{
                [[[adRevenue copy] should] equal:adRevenue];
            });
            context(@"Mutable copy", ^{
                AMAMutableAdRevenueInfo *__block mutable = nil;
                beforeEach(^{
                    mutable = [adRevenue mutableCopy];
                });
                it(@"Should copy price", ^{
                    [[mutable.adRevenue should] equal:price];
                });
                it(@"Should copy currency", ^{
                    [[mutable.currency should] equal:currency];
                });
                it(@"Should copy unknown type", ^{
                    [[theValue(mutable.adType) should] equal:theValue(AMAAdTypeUnknown)];
                });
                it(@"Should copy nil ad network", ^{
                    [[mutable.adNetwork should] beNil];
                });
                it(@"Should copy nil ad unit id", ^{
                    [[mutable.adUnitID should] beNil];
                });
                it(@"Should copy ad nil unit name", ^{
                    [[mutable.adUnitName should] beNil];
                });
                it(@"Should copy nil ad placement id", ^{
                    [[mutable.adPlacementID should] beNil];
                });
                it(@"Should copy nil ad placement name", ^{
                    [[mutable.adPlacementName should] beNil];
                });
                it(@"Should copy nil precision", ^{
                    [[mutable.precision should] beNil];
                });
                it(@"Should copy nil payload", ^{
                    [[mutable.payload should] beNil];
                });
            });

        });
        context(@"Filled", ^{
            AMAAdRevenueInfo *__block adRevenue;
            beforeEach(^{
                AMAMutableAdRevenueInfo *mutable = [[AMAMutableAdRevenueInfo alloc] initWithAdRevenue:price
                                                                                             currency:currency];
                mutable.adType = type;
                mutable.adNetwork = adNetwork;
                mutable.adUnitID = adUnitID;
                mutable.adUnitName = adUnitName;
                mutable.adPlacementID = adPlacementID;
                mutable.adPlacementName = adPlacementName;
                mutable.precision = precision;
                mutable.payload = payload;
                adRevenue = [mutable copy];
            });
            it(@"Should copy itself", ^{
                [[[adRevenue copy] should] equal:adRevenue];
            });
            context(@"Mutable copy", ^{
                AMAMutableAdRevenueInfo *__block mutable = nil;
                beforeEach(^{
                    mutable = [adRevenue mutableCopy];
                });
                it(@"Should copy price", ^{
                    [[mutable.adRevenue should] equal:price];
                });
                it(@"Should copy currency", ^{
                    [[mutable.currency should] equal:currency];
                });
                it(@"Should copy type", ^{
                    [[theValue(mutable.adType) should] equal:theValue(type)];
                });
                it(@"Should copy ad network", ^{
                    [[mutable.adNetwork should] equal:adNetwork];
                });
                it(@"Should copy ad unit id", ^{
                    [[mutable.adUnitID should] equal:adUnitID];
                });
                it(@"Should copy ad unit name", ^{
                    [[mutable.adUnitName should] equal:adUnitName];
                });
                it(@"Should copy ad placement id", ^{
                    [[mutable.adPlacementID should] equal:adPlacementID];
                });
                it(@"Should copy ad placement name", ^{
                    [[mutable.adPlacementName should] equal:adPlacementName];
                });
                it(@"Should copy precision", ^{
                    [[mutable.precision should] equal:precision];
                });
                it(@"Should copy payload", ^{
                    [[mutable.payload should] equal:payload];
                });
            });
        });
    });
    context(@"Mutable", ^{
        context(@"Minimal", ^{
            AMAAdRevenueInfo *__block immutable = nil;
            AMAMutableAdRevenueInfo *mutable = [[AMAMutableAdRevenueInfo alloc] initWithAdRevenue:price
                                                                                         currency:currency];
            context(@"Immutable copy", ^{
                beforeEach(^{
                    immutable = [mutable copy];
                });
                it(@"Should copy price", ^{
                    [[immutable.adRevenue should] equal:price];
                });
                it(@"Should copy currency", ^{
                    [[immutable.currency should] equal:currency];
                });
                it(@"Should copy unknown type", ^{
                    [[theValue(immutable.adType) should] equal:theValue(AMAAdTypeUnknown)];
                });
                it(@"Should copy nil ad network", ^{
                    [[immutable.adNetwork should] beNil];
                });
                it(@"Should copy nil ad unit id", ^{
                    [[immutable.adUnitID should] beNil];
                });
                it(@"Should copy ad nil unit name", ^{
                    [[immutable.adUnitName should] beNil];
                });
                it(@"Should copy nil ad placement id", ^{
                    [[immutable.adPlacementID should] beNil];
                });
                it(@"Should copy nil ad placement name", ^{
                    [[immutable.adPlacementName should] beNil];
                });
                it(@"Should copy nil precision", ^{
                    [[immutable.precision should] beNil];
                });
                it(@"Should copy nil payload", ^{
                    [[immutable.payload should] beNil];
                });
            });

        });
        context(@"Filled", ^{
            AMAAdRevenueInfo *__block immutable = nil;
            AMAMutableAdRevenueInfo *mutable = [[AMAMutableAdRevenueInfo alloc] initWithAdRevenue:price
                                                                                         currency:currency];
            beforeEach(^{
                mutable.adType = type;
                mutable.adNetwork = adNetwork;
                mutable.adUnitID = adUnitID;
                mutable.adUnitName = adUnitName;
                mutable.adPlacementID = adPlacementID;
                mutable.adPlacementName = adPlacementName;
                mutable.precision = precision;
                mutable.payload = payload;
            });
            context(@"Immutable copy", ^{
                beforeEach(^{
                    immutable = [mutable copy];
                });
                it(@"Should copy price", ^{
                    [[immutable.adRevenue should] equal:price];
                });
                it(@"Should copy currency", ^{
                    [[immutable.currency should] equal:currency];
                });
                it(@"Should copy type", ^{
                    [[theValue(immutable.adType) should] equal:theValue(type)];
                });
                it(@"Should copy ad network", ^{
                    [[immutable.adNetwork should] equal:adNetwork];
                });
                it(@"Should copy ad unit id", ^{
                    [[immutable.adUnitID should] equal:adUnitID];
                });
                it(@"Should copy ad unit name", ^{
                    [[immutable.adUnitName should] equal:adUnitName];
                });
                it(@"Should copy ad placement id", ^{
                    [[immutable.adPlacementID should] equal:adPlacementID];
                });
                it(@"Should copy ad placement name", ^{
                    [[immutable.adPlacementName should] equal:adPlacementName];
                });
                it(@"Should copy precision", ^{
                    [[immutable.precision should] equal:precision];
                });
                it(@"Should copy payload", ^{
                    [[immutable.payload should] equal:payload];
                });
            });
        });

    });
});

SPEC_END
