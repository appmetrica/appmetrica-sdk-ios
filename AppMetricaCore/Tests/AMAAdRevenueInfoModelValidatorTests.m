
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMACore.h"
#import "AMAAdRevenueInfoModelValidator.h"
#import "AMAAdRevenueInfoProcessingLogger.h"
#import "AMAAdRevenueInfoModel.h"
#import "AMAAdRevenueInfoMutableModel.h"
#import "AMAAppMetrica.h"

SPEC_BEGIN(AMAAdRevenueInfoModelValidatorTests)

describe(@"AMAAdRevenueInfoModelValidator", ^{

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

    AMAAdRevenueInfoMutableModel *__block model = nil;
    AMAAdRevenueInfoProcessingLogger *__block logger = nil;
    AMAAdRevenueInfoModelValidator *__block validator = nil;

    beforeEach(^{
        logger = [AMAAdRevenueInfoProcessingLogger nullMock];
        validator = [[AMAAdRevenueInfoModelValidator alloc] initWithLogger:logger];
    });

    context(@"Full", ^{
        beforeEach(^{
            model = [[AMAAdRevenueInfoMutableModel alloc] initWithAmount:amount
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
                                                         isAutocollected:isAutocollected
            ];
        });
        it(@"Should return YES", ^{
            [[theValue([validator validateAdRevenueInfoModel:model error:nil]) should] beYes];
        });
        it(@"Should not fill error", ^{
            NSError *error = nil;
            [validator validateAdRevenueInfoModel:model error:&error];
            [[error should] beNil];
        });
    });
    context(@"Minimal", ^{
        beforeEach(^{
            model = [[AMAAdRevenueInfoMutableModel alloc] initWithAmount:amount currency:currency];
        });
        it(@"Should return YES", ^{
            [[theValue([validator validateAdRevenueInfoModel:model error:nil]) should] beYes];
        });
        it(@"Should not fill error", ^{
            NSError *error = nil;
            [validator validateAdRevenueInfoModel:model error:&error];
            [[error should] beNil];
        });
    });
    context(@"Invalid currency", ^{
        NSString *__block invalidCurrency = nil;
        NSString *(^expectedErrorDescription)(void) = ^{
            return [NSString stringWithFormat:@"Invalid currency code '%@'. Expected ISO 4217 format.", invalidCurrency];
        };
        context(@"Wrong size", ^{
            beforeEach(^{
                invalidCurrency = @"RU";
                model.currency = invalidCurrency;
            });
            it(@"Should return NO", ^{
                [[theValue([validator validateAdRevenueInfoModel:model error:nil]) should] beNo];
            });
            it(@"Should fill error", ^{
                NSString *description = expectedErrorDescription();
                NSError *expectedError = [NSError errorWithDomain:kAMAAppMetricaErrorDomain
                                                             code:AMAAppMetricaEventErrorCodeInvalidAdRevenueInfo
                                                         userInfo:@{ NSLocalizedDescriptionKey: description}];
                NSError *error = nil;
                [validator validateAdRevenueInfoModel:model error:&error];
                [[error should] equal:expectedError];
            });
            it(@"Should log", ^{
                [[logger should] receive:@selector(logInvalidCurrency:) withArguments:invalidCurrency];
                [validator validateAdRevenueInfoModel:model error:nil];
            });
        });
        context(@"Wrong case", ^{
            beforeEach(^{
                invalidCurrency = @"byn";
                model.currency = invalidCurrency;
            });
            it(@"Should return NO", ^{
                [[theValue([validator validateAdRevenueInfoModel:model error:nil]) should] beNo];
            });
            it(@"Should fill error", ^{
                NSString *description = expectedErrorDescription();
                NSError *expectedError = [NSError errorWithDomain:kAMAAppMetricaErrorDomain
                                                             code:AMAAppMetricaEventErrorCodeInvalidAdRevenueInfo
                                                         userInfo:@{ NSLocalizedDescriptionKey: description}];
                NSError *error = nil;
                [validator validateAdRevenueInfoModel:model error:&error];
                [[error should] equal:expectedError];
            });
            it(@"Should log", ^{
                [[logger should] receive:@selector(logInvalidCurrency:) withArguments:invalidCurrency];
                [validator validateAdRevenueInfoModel:model error:nil];
            });
        });
        context(@"Wrong symbols", ^{
            beforeEach(^{
                invalidCurrency = @"KE0";
                model.currency = invalidCurrency;
            });
            it(@"Should return NO", ^{
                [[theValue([validator validateAdRevenueInfoModel:model error:nil]) should] beNo];
            });
            it(@"Should fill error", ^{
                NSString *description = expectedErrorDescription();
                NSError *expectedError = [NSError errorWithDomain:kAMAAppMetricaErrorDomain
                                                             code:AMAAppMetricaEventErrorCodeInvalidAdRevenueInfo
                                                         userInfo:@{ NSLocalizedDescriptionKey: description}];
                NSError *error = nil;
                [validator validateAdRevenueInfoModel:model error:&error];
                [[error should] equal:expectedError];
            });
            it(@"Should log", ^{
                [[logger should] receive:@selector(logInvalidCurrency:) withArguments:invalidCurrency];
                [validator validateAdRevenueInfoModel:model error:nil];
            });
        });
    });

});

SPEC_END
