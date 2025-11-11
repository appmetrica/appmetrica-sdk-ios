
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMARevenueInfoProcessingLogger.h"
#import "AMALogSpy.h"

SPEC_BEGIN(AMARevenueInfoProcessingLoggerTests)

describe(@"AMARevenueInfoProcessingLogger", ^{

    AMALogSpy *__block log = nil;
    AMARevenueInfoProcessingLogger *__block logger = nil;

    beforeEach(^{
        log = [[AMALogSpy alloc] init];
        [AMALogFacade stub:@selector(sharedLog) andReturn:log];
        logger = [[AMARevenueInfoProcessingLogger alloc] init];
    });

    AMALogMessageSpy *(^messageWithText)(NSString *) = ^(NSString *text) {
        return [AMALogMessageSpy messageWithText:text channel:@"AppMetricaCore" level:AMALogLevelWarning];
    };

    context(@"Truncation", ^{
        it(@"Should log product ID", ^{
            [logger logTruncationOfType:@"product ID" value:@"PRODUCT_ID" maxLength:23];

            NSString *expectedText = @"Revenue product ID 'PRODUCT_ID' was truncated. Max length is '23'.";
            [[log.messages should] equal:@[messageWithText(expectedText)]];
        });
        it(@"Should log transaction ID", ^{
            [logger logTruncationOfType:@"transaction ID" value:@"TRANSACTION_ID" maxLength:42];

            NSString *expectedText = @"Revenue transaction ID 'TRANSACTION_ID' was truncated. Max length is '42'.";
            [[log.messages should] equal:@[messageWithText(expectedText)]];
        });
        it(@"Should log receipt data", ^{
            [logger logTruncationOfReceiptDataWithLength:108 maxSize:42];

            NSString *expectedText = @"Revenue receipt data was truncated. Data size is '108'. Max size is '42'.";
            [[log.messages should] equal:@[messageWithText(expectedText)]];
        });
        it(@"Should log payload string", ^{
            [logger logTruncationOfPayloadString:@"PAYLOAD" maxLength:32];

            NSString *expectedText = @"Revenue payload was truncated. JSON-serialized string: 'PAYLOAD'. "
                                      "Max length is '32'.";
            [[log.messages should] equal:@[messageWithText(expectedText)]];
        });
    });
    context(@"Rejection", ^{
        it(@"Should log zero quantity", ^{
            [logger logZeroQuantity];
            [[log.messages should] equal:@[messageWithText(@"Revenue event was rejected: quantity can't be zero.")]];
        });
        it(@"Should log invalid currency", ^{
            [logger logInvalidCurrency:@"CURRENCY"];
            NSString *expectedText = @"Revenue event was rejected: currency 'CURRENCY' doesn't correspond ISO 4217.";
            [[log.messages should] equal:@[messageWithText(expectedText)]];
        });
    });
    context(@"Warnings", ^{
        context(@"Should log missing transaction ID", ^{
            [logger logTransactionIDIsMissing];
            NSString *expectedText = @"In-App Purchase won't be validated: transaction ID is missing. "
                                      "See AMARevenueInfo.h for more information.";
            [[log.messages should] equal:@[messageWithText(expectedText)]];
        });
        context(@"Should log missing receipt data", ^{
            [logger logReceiptDataIsMissing];
            NSString *expectedText = @"In-App Purchase won't be validated: receipt data is missing. "
                                      "See AMARevenueInfo.h for more information.";
            [[log.messages should] equal:@[messageWithText(expectedText)]];
        });
    });

});

SPEC_END
