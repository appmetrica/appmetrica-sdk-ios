
#import <Kiwi/Kiwi.h>
#import "AMAAdRevenueInfoProcessingLogger.h"
#import "AMALogSpy.h"

SPEC_BEGIN(AMAAdRevenueInfoProcessingLoggerTests)

describe(@"AMARevenueInfoProcessingLogger", ^{

    AMALogSpy *__block log = nil;
    AMAAdRevenueInfoProcessingLogger *__block logger = nil;

    beforeEach(^{
        log = [[AMALogSpy alloc] init];
        [AMALogFacade stub:@selector(sharedLog) andReturn:log];
        logger = [[AMAAdRevenueInfoProcessingLogger alloc] init];
    });

    AMALogMessageSpy *(^messageWithText)(NSString *) = ^(NSString *text) {
        return [AMALogMessageSpy messageWithText:text channel:@"AppMetricaCore" level:AMALogLevelWarning];
    };

    context(@"Truncation", ^{
        it(@"Should log ad network", ^{
            [logger logTruncationOfType:@"network" value:@"AD_NETWORK" maxLength:13];

            NSString *expectedText = @"AdRevenue network 'AD_NETWORK' was truncated. Max length is '13'.";
            [[log.messages should] equal:@[messageWithText(expectedText)]];
        });
        it(@"Should log unit ID", ^{
            [logger logTruncationOfType:@"unitID" value:@"AD_UNIT_ID" maxLength:9];

            NSString *expectedText = @"AdRevenue unitID 'AD_UNIT_ID' was truncated. Max length is '9'.";
            [[log.messages should] equal:@[messageWithText(expectedText)]];
        });
        it(@"Should log unit name", ^{
            [logger logTruncationOfType:@"unit name" value:@"AD_UNIT_NAME" maxLength:2930];

            NSString *expectedText = @"AdRevenue unit name 'AD_UNIT_NAME' was truncated. Max length is '2930'.";
            [[log.messages should] equal:@[messageWithText(expectedText)]];
        });
        it(@"Should log placement ID", ^{
            [logger logTruncationOfType:@"placementID" value:@"AD_PLACEMENT_ID" maxLength:100];

            NSString *expectedText = @"AdRevenue placementID 'AD_PLACEMENT_ID' was truncated. Max length is '100'.";
            [[log.messages should] equal:@[messageWithText(expectedText)]];
        });
        it(@"Should log placement name", ^{
            [logger logTruncationOfType:@"placement name" value:@"AD_PLACEMENT_NAME" maxLength:100];

            NSString *expectedText = @"AdRevenue placement name 'AD_PLACEMENT_NAME' was truncated. Max length is '100'.";
            [[log.messages should] equal:@[messageWithText(expectedText)]];
        });
        it(@"Should log precision", ^{
            [logger logTruncationOfType:@"precision" value:@"AD_PRECISION" maxLength:100];

            NSString *expectedText = @"AdRevenue precision 'AD_PRECISION' was truncated. Max length is '100'.";
            [[log.messages should] equal:@[messageWithText(expectedText)]];
        });

        it(@"Should log payload string", ^{
            [logger logTruncationOfPayloadString:@"AD_PAYLOAD" maxLength:32];

            NSString *expectedText = @"AdRevenue payload was truncated. JSON-serialized string: 'AD_PAYLOAD'. "
            "Max length is '32'.";
            [[log.messages should] equal:@[messageWithText(expectedText)]];
        });
    });
    context(@"Rejection", ^{
        it(@"Should log invalid currency", ^{
            [logger logInvalidCurrency:@"CURRENCY"];
            NSString *expectedText = @"AdRevenue event was rejected: currency 'CURRENCY' doesn't correspond ISO 4217.";
            [[log.messages should] equal:@[messageWithText(expectedText)]];
        });
    });

});

SPEC_END
