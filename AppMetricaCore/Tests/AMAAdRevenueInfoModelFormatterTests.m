
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAAppMetrica.h"
#import "AMAAdRevenueInfoModelFormatter.h"
#import "AMAAdRevenueInfoModel.h"
#import "AMAAdRevenueInfoMutableModel.h"
#import "AMAAdRevenueInfoProcessingLogger.h"

SPEC_BEGIN(AMAAdRevenueInfoModelFormatterTests)

describe(@"AMAAdRevenueInfoModelFormatter", ^{

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
    NSUInteger const bytesTruncated = 0;

    NSUInteger const expectedBytesTruncatedMultiplier = 8;
    NSUInteger const maxLength = 100;
    NSUInteger const payloadMaxLength = 30 * 1024;

    AMAAdRevenueInfoMutableModel *__block adRevenueInfoModel = nil;
    AMATestTruncator *__block stringTruncator = nil;
    AMATestTruncator *__block payloadTruncator = nil;
    AMAAdRevenueInfoProcessingLogger *__block logger = nil;
    AMAAdRevenueInfoModelFormatter *__block formatter = nil;

    beforeEach(^{
        adRevenueInfoModel = [[AMAAdRevenueInfoMutableModel alloc] initWithAmount:amount
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
                                                                  isAutocollected:NO
        ];
        stringTruncator = [[AMATestTruncator alloc] init];
        payloadTruncator = [[AMATestTruncator alloc] init];
        logger = [AMAAdRevenueInfoProcessingLogger nullMock];
        formatter = [[AMAAdRevenueInfoModelFormatter alloc] initWithStringTruncator:stringTruncator
                                                                   payloadTruncator:payloadTruncator
                                                                             logger:logger];
    });

    context(@"Decimal amount", ^{
        it(@"Should return model with valid value", ^{
            [[[formatter formattedAdRevenueModel:adRevenueInfoModel].amount should] equal:amount];
        });
        it(@"Should return model with zero bytesTruncated", ^{
            [[theValue([formatter formattedAdRevenueModel:adRevenueInfoModel].bytesTruncated) should] beZero];
        });
    });

    context(@"Currency", ^{
        beforeEach(^{
            adRevenueInfoModel.currency = currency;
        });
        it(@"Should return model with valid value", ^{
            [[[formatter formattedAdRevenueModel:adRevenueInfoModel].currency should] equal:currency];
        });
        it(@"Should return model with zero bytesTruncated", ^{
            [[theValue([formatter formattedAdRevenueModel:adRevenueInfoModel].bytesTruncated) should] beZero];
        });
        context(@"Large", ^{
            NSString *const truncatedCurrency = @"BYN_USD";
            NSUInteger const bytesTruncated = 2;
            beforeEach(^{
                [stringTruncator enableTruncationWithResult:truncatedCurrency
                                             bytesTruncated:bytesTruncated];
                [payloadTruncator enableTruncationWithResult:payloadString
                                              bytesTruncated:bytesTruncated];
            });
            it(@"Should call truncator", ^{
                [[stringTruncator should] receive:@selector(truncatedString:onTruncation:)
                                    withArguments:currency, kw_any()];
                [formatter formattedAdRevenueModel:adRevenueInfoModel];
            });
            it(@"Should return model with truncated value", ^{
                [[[formatter formattedAdRevenueModel:adRevenueInfoModel].currency should] equal:truncatedCurrency];
            });
            it(@"Should log truncation", ^{
                [[logger should] receive:@selector(logTruncationOfType:value:maxLength:)
                           withArguments:@"currency", currency, theValue(maxLength)];
                [formatter formattedAdRevenueModel:adRevenueInfoModel];
            });
            it(@"Should return model with valid bytesTruncated", ^{
                [[theValue([formatter formattedAdRevenueModel:adRevenueInfoModel].bytesTruncated) should]
                 equal:theValue(expectedBytesTruncatedMultiplier * bytesTruncated)];
            });
        });
    });

    context(@"Currency", ^{
        beforeEach(^{
            adRevenueInfoModel.currency = currency;
        });
        it(@"Should return model with valid value", ^{
            [[[formatter formattedAdRevenueModel:adRevenueInfoModel].currency should] equal:currency];
        });
        it(@"Should return model with zero bytesTruncated", ^{
            [[theValue([formatter formattedAdRevenueModel:adRevenueInfoModel].bytesTruncated) should] beZero];
        });
        context(@"Large", ^{
            NSString *const truncatedCurrency = @"BYN_USD";
            NSUInteger const bytesTruncated = 2;
            beforeEach(^{
                [stringTruncator enableTruncationWithResult:truncatedCurrency
                                             bytesTruncated:bytesTruncated];
                [payloadTruncator enableTruncationWithResult:payloadString
                                              bytesTruncated:bytesTruncated];
            });
            it(@"Should call truncator", ^{
                [[stringTruncator should] receive:@selector(truncatedString:onTruncation:)
                                    withArguments:currency, kw_any()];
                [formatter formattedAdRevenueModel:adRevenueInfoModel];
            });
            it(@"Should return model with truncated value", ^{
                [[[formatter formattedAdRevenueModel:adRevenueInfoModel].currency should] equal:truncatedCurrency];
            });
            it(@"Should log truncation", ^{
                [[logger should] receive:@selector(logTruncationOfType:value:maxLength:)
                           withArguments:@"currency", currency, theValue(maxLength)];
                [formatter formattedAdRevenueModel:adRevenueInfoModel];
            });
            it(@"Should return model with valid bytesTruncated", ^{
                [[theValue([formatter formattedAdRevenueModel:adRevenueInfoModel].bytesTruncated) should]
                 equal:theValue(expectedBytesTruncatedMultiplier * bytesTruncated)];
            });
        });
    });

    context(@"AdType", ^{
        it(@"Should return model with valid value", ^{
            [[theValue([formatter formattedAdRevenueModel:adRevenueInfoModel].adType) should]
             equal:theValue(adType)];
        });
    });
    context(@"AdNetwork", ^{
        beforeEach(^{
            adRevenueInfoModel.adNetwork = adNetwork;
        });

        it(@"Should return model with valid value", ^{
            [[theValue([formatter formattedAdRevenueModel:adRevenueInfoModel].adNetwork) should]
             equal:theValue(adNetwork)];
        });
        it(@"Should return model with zero bytesTruncated", ^{
            [[theValue([formatter formattedAdRevenueModel:adRevenueInfoModel].bytesTruncated) should] beZero];
        });
        context(@"Large", ^{
            NSString *const truncatedAdNetwork = @"AD";
            NSUInteger const bytesTruncated = 2;
            beforeEach(^{
                [stringTruncator enableTruncationWithResult:truncatedAdNetwork
                                             bytesTruncated:bytesTruncated];
                [payloadTruncator enableTruncationWithResult:payloadString
                                              bytesTruncated:bytesTruncated];
            });
            it(@"Should call truncator", ^{
                [[stringTruncator should] receive:@selector(truncatedString:onTruncation:)
                                    withArguments:adNetwork, kw_any()];
                [formatter formattedAdRevenueModel:adRevenueInfoModel];
            });
            it(@"Should return model with truncated value", ^{
                [[[formatter formattedAdRevenueModel:adRevenueInfoModel].adNetwork should] equal:truncatedAdNetwork];
            });
            it(@"Should log truncation", ^{
                [[logger should] receive:@selector(logTruncationOfType:value:maxLength:)
                           withArguments:@"network", adNetwork, theValue(maxLength)];
                [formatter formattedAdRevenueModel:adRevenueInfoModel];
            });
            it(@"Should return model with valid bytesTruncated", ^{
                [[theValue([formatter formattedAdRevenueModel:adRevenueInfoModel].bytesTruncated) should]
                 equal:theValue(expectedBytesTruncatedMultiplier * bytesTruncated)];
            });
        });
    });

    context(@"AdUnitID", ^{
        beforeEach(^{
            adRevenueInfoModel.adUnitID = adUnitID;
        });
        context(@"Normal", ^{
            it(@"Should return model with valid value", ^{
                [[[formatter formattedAdRevenueModel:adRevenueInfoModel].adUnitID should]
                 equal:adUnitID];
            });
            it(@"Should return model with zero bytesTruncated", ^{
                [[theValue([formatter formattedAdRevenueModel:adRevenueInfoModel].bytesTruncated) should] beZero];
            });
        });
        context(@"Large", ^{
            NSString *const truncatedUnitID = @"AD_UNIT";
            NSUInteger const bytesTruncated = 42;
            beforeEach(^{
                [stringTruncator enableTruncationWithResult:truncatedUnitID
                                             bytesTruncated:bytesTruncated];
                [payloadTruncator enableTruncationWithResult:payloadString
                                              bytesTruncated:bytesTruncated];
            });
            it(@"Should call truncator", ^{
                [[stringTruncator should] receive:@selector(truncatedString:onTruncation:)
                                    withArguments:adUnitID, kw_any()];
                [formatter formattedAdRevenueModel:adRevenueInfoModel];
            });
            it(@"Should return model with truncated value", ^{
                [[[formatter formattedAdRevenueModel:adRevenueInfoModel].adUnitID should] equal:truncatedUnitID];
            });
            it(@"Should log truncation", ^{
                [[logger should] receive:@selector(logTruncationOfType:value:maxLength:)
                           withArguments:@"unitID", adUnitID, theValue(maxLength)];
                [formatter formattedAdRevenueModel:adRevenueInfoModel];
            });
            it(@"Should return model with valid bytesTruncated", ^{
                [[theValue([formatter formattedAdRevenueModel:adRevenueInfoModel].bytesTruncated) should]
                 equal:theValue(expectedBytesTruncatedMultiplier * bytesTruncated)];
            });
        });
    });

    context(@"AdPlacementID", ^{
        beforeEach(^{
            adRevenueInfoModel.adPlacementID = adPlacementID;
        });
        context(@"Normal", ^{
            it(@"Should return model with valid value", ^{
                [[[formatter formattedAdRevenueModel:adRevenueInfoModel].adPlacementID should] equal:adPlacementID];
            });
            it(@"Should return model with zero bytesTruncated", ^{
                [[theValue([formatter formattedAdRevenueModel:adRevenueInfoModel].bytesTruncated) should] beZero];
            });
        });
        context(@"Large", ^{
            NSString *const truncatedPlacementID = @"AD_PLACEMENT";
            NSUInteger const bytesTruncated = 42;
            beforeEach(^{
                [stringTruncator enableTruncationWithResult:truncatedPlacementID
                                             bytesTruncated:bytesTruncated];
                [payloadTruncator enableTruncationWithResult:payloadString
                                              bytesTruncated:bytesTruncated];
            });
            it(@"Should call truncator", ^{
                [[stringTruncator should] receive:@selector(truncatedString:onTruncation:)
                                    withArguments:adPlacementID, kw_any()];
                [formatter formattedAdRevenueModel:adRevenueInfoModel];
            });
            it(@"Should return model with truncated value", ^{
                [[[formatter formattedAdRevenueModel:adRevenueInfoModel].adUnitID should] equal:truncatedPlacementID];
            });
            it(@"Should log truncation", ^{
                [[logger should] receive:@selector(logTruncationOfType:value:maxLength:)
                           withArguments:@"placementID", adPlacementID, theValue(maxLength)];
                [formatter formattedAdRevenueModel:adRevenueInfoModel];
            });
            it(@"Should return model with valid bytesTruncated", ^{
                [[theValue([formatter formattedAdRevenueModel:adRevenueInfoModel].bytesTruncated) should]
                 equal:theValue(expectedBytesTruncatedMultiplier * bytesTruncated)];
            });
        });
    });

    context(@"Precision", ^{
        beforeEach(^{
            adRevenueInfoModel.precision = precision;
        });
        context(@"Normal", ^{
            it(@"Should return model with valid value", ^{
                [[[formatter formattedAdRevenueModel:adRevenueInfoModel].precision should] equal:precision];
            });
            it(@"Should return model with zero bytesTruncated", ^{
                [[theValue([formatter formattedAdRevenueModel:adRevenueInfoModel].bytesTruncated) should] beZero];
            });
        });
        context(@"Large", ^{
            NSString *const truncatedPrecision = @"AD";
            NSUInteger const bytesTruncated = 42;
            beforeEach(^{
                [stringTruncator enableTruncationWithResult:truncatedPrecision
                                             bytesTruncated:bytesTruncated];
                [payloadTruncator enableTruncationWithResult:payloadString
                                              bytesTruncated:bytesTruncated];
            });
            it(@"Should call truncator", ^{
                [[stringTruncator should] receive:@selector(truncatedString:onTruncation:)
                                    withArguments:precision, kw_any()];
                [formatter formattedAdRevenueModel:adRevenueInfoModel];
            });
            it(@"Should return model with truncated value", ^{
                [[[formatter formattedAdRevenueModel:adRevenueInfoModel].precision should] equal:truncatedPrecision];
            });
            it(@"Should log truncation", ^{
                [[logger should] receive:@selector(logTruncationOfType:value:maxLength:)
                           withArguments:@"precision", precision, theValue(maxLength)];
                [formatter formattedAdRevenueModel:adRevenueInfoModel];
            });
            it(@"Should return model with valid bytesTruncated", ^{
                [[theValue([formatter formattedAdRevenueModel:adRevenueInfoModel].bytesTruncated) should]
                 equal:theValue(expectedBytesTruncatedMultiplier * bytesTruncated)];
            });
        });
    });

    context(@"AdPlacementName", ^{
        beforeEach(^{
            adRevenueInfoModel.adPlacementName = adPlacementName;
        });
        context(@"Normal", ^{
            it(@"Should return model with valid value", ^{
                [[[formatter formattedAdRevenueModel:adRevenueInfoModel].adPlacementName should] equal:adPlacementName];
            });
            it(@"Should return model with zero bytesTruncated", ^{
                [[theValue([formatter formattedAdRevenueModel:adRevenueInfoModel].bytesTruncated) should] beZero];
            });
        });
        context(@"Large", ^{
            NSString *const truncatedPlacementName = @"AD_PLACEMENT";
            NSUInteger const bytesTruncated = 42;
            beforeEach(^{
                [stringTruncator enableTruncationWithResult:truncatedPlacementName
                                             bytesTruncated:bytesTruncated];
                [payloadTruncator enableTruncationWithResult:payloadString
                                              bytesTruncated:bytesTruncated];
            });
            it(@"Should call truncator", ^{
                [[stringTruncator should] receive:@selector(truncatedString:onTruncation:)
                                    withArguments:adPlacementName, kw_any()];
                [formatter formattedAdRevenueModel:adRevenueInfoModel];
            });
            it(@"Should return model with truncated value", ^{
                [[[formatter formattedAdRevenueModel:adRevenueInfoModel].precision should]
                 equal:truncatedPlacementName];
            });
            it(@"Should log truncation", ^{
                [[logger should] receive:@selector(logTruncationOfType:value:maxLength:)
                           withArguments:@"placement name", adPlacementName, theValue(maxLength)];
                [formatter formattedAdRevenueModel:adRevenueInfoModel];
            });
            it(@"Should return model with valid bytesTruncated", ^{
                [[theValue([formatter formattedAdRevenueModel:adRevenueInfoModel].bytesTruncated) should]
                 equal:theValue(expectedBytesTruncatedMultiplier * bytesTruncated)];
            });
        });
    });

    context(@"AdUnitName", ^{
        beforeEach(^{
            adRevenueInfoModel.adUnitName = adUnitName;
        });
        context(@"Normal", ^{
            it(@"Should return model with valid value", ^{
                [[[formatter formattedAdRevenueModel:adRevenueInfoModel].adUnitName should] equal:adUnitName];
            });
            it(@"Should return model with zero bytesTruncated", ^{
                [[theValue([formatter formattedAdRevenueModel:adRevenueInfoModel].bytesTruncated) should] beZero];
            });
        });
        context(@"Large", ^{
            NSString *const truncatedUnitName = @"AD_UNIT";
            NSUInteger const bytesTruncated = 42;
            beforeEach(^{
                [stringTruncator enableTruncationWithResult:truncatedUnitName
                                             bytesTruncated:bytesTruncated];
                [payloadTruncator enableTruncationWithResult:payloadString
                                              bytesTruncated:bytesTruncated];
            });
            it(@"Should call truncator", ^{
                [[stringTruncator should] receive:@selector(truncatedString:onTruncation:)
                                    withArguments:adUnitName, kw_any()];
                [formatter formattedAdRevenueModel:adRevenueInfoModel];
            });
            it(@"Should return model with truncated value", ^{
                [[[formatter formattedAdRevenueModel:adRevenueInfoModel].precision should]
                 equal:truncatedUnitName];
            });
            it(@"Should log truncation", ^{
                [[logger should] receive:@selector(logTruncationOfType:value:maxLength:)
                           withArguments:@"unit name", adUnitName, theValue(maxLength)];
                [formatter formattedAdRevenueModel:adRevenueInfoModel];
            });
            it(@"Should return model with valid bytesTruncated", ^{
                [[theValue([formatter formattedAdRevenueModel:adRevenueInfoModel].bytesTruncated) should]
                 equal:theValue(expectedBytesTruncatedMultiplier * bytesTruncated)];
            });
        });
    });

    context(@"Payload", ^{
        beforeEach(^{
            adRevenueInfoModel.payloadString = payloadString;
        });
        context(@"Normal", ^{
            it(@"Should return model with valid value", ^{
                [[[formatter formattedAdRevenueModel:adRevenueInfoModel].payloadString should] equal:payloadString];
            });
            it(@"Should return model with zero bytesTruncated", ^{
                [[theValue([formatter formattedAdRevenueModel:adRevenueInfoModel].bytesTruncated) should] beZero];
            });
        });
        context(@"Large", ^{
            NSString *const truncatedPayloadString = @"{\"foo\":\"ba";
            NSUInteger const bytesTruncated = 42;
            beforeEach(^{
                [payloadTruncator enableTruncationWithResult:truncatedPayloadString
                                              bytesTruncated:bytesTruncated];
            });
            it(@"Should call truncator", ^{
                [[payloadTruncator should] receive:@selector(truncatedString:onTruncation:)
                                     withArguments:payloadString, kw_any()];
                [formatter formattedAdRevenueModel:adRevenueInfoModel];
            });
            it(@"Should return model with truncated value", ^{
                [[[formatter formattedAdRevenueModel:adRevenueInfoModel].payloadString should] equal:truncatedPayloadString];
            });
            it(@"Should log truncation", ^{
                [[logger should] receive:@selector(logTruncationOfPayloadString:maxLength:)
                           withArguments:payloadString, theValue(payloadMaxLength)];
                [formatter formattedAdRevenueModel:adRevenueInfoModel];
            });
            it(@"Should return model with valid bytesTruncated", ^{
                [[theValue([formatter formattedAdRevenueModel:adRevenueInfoModel].bytesTruncated) should]
                 equal:theValue(bytesTruncated)];
            });
        });
    });

    context(@"Bytes truncating", ^{
        NSUInteger expectedBytesCount = 1 + 2 + 3 + 4 + 5 + 6 + 7;
        NSString *const maxSizeString = @"1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890";
        AMALengthStringTruncator *const stringTruncator = [[AMALengthStringTruncator alloc] initWithMaxLength:maxLength];

        beforeEach(^{
            formatter = [[AMAAdRevenueInfoModelFormatter alloc] initWithStringTruncator:stringTruncator
                                                                       payloadTruncator:payloadTruncator
                                                                                 logger:logger];
            adRevenueInfoModel.adNetwork = [maxSizeString stringByAppendingString:@"X"];
            adRevenueInfoModel.adUnitID = [maxSizeString stringByAppendingString:@"XX"];
            adRevenueInfoModel.adUnitName = [maxSizeString stringByAppendingString:@"XXX"];
            adRevenueInfoModel.adPlacementID = [maxSizeString stringByAppendingString:@"XXXX"];
            adRevenueInfoModel.adPlacementName = [maxSizeString stringByAppendingString:@"XXXXX"];
            adRevenueInfoModel.precision = [maxSizeString stringByAppendingString:@"XXXXXX"];
            adRevenueInfoModel.currency = [maxSizeString stringByAppendingString:@"XXXXXXX"];
        });

        it(@"Should return model with zero bytesTruncated", ^{
            [[theValue([formatter formattedAdRevenueModel:adRevenueInfoModel].bytesTruncated) should]
             equal:theValue(expectedBytesCount)];
        });
    });
});

SPEC_END
