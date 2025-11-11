
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaLog/AppMetricaLog.h>
#import "AMAUserProfileLogger.h"
#import "AMALogSpy.h"

SPEC_BEGIN(AMAUserProfileLoggerTests)

describe(@"AMAUserProfileLogger", ^{

    NSString *const string = @"STRING";
    NSString *const attributeName = @"ATTRIBUTE_NAME";

    AMALogSpy *__block logSpy = nil;

    beforeEach(^{
        logSpy = [[AMALogSpy alloc] init];
        [AMALogFacade stub:@selector(sharedLog) andReturn:logSpy];
    });

    AMALogMessageSpy *(^messageWithText)(NSString *) = ^(NSString *text) {
        return [AMALogMessageSpy messageWithText:text channel:@"AppMetricaCore" level:AMALogLevelWarning];
    };

    context(@"Attribute name is too long", ^{
        it(@"Should log with valid message", ^{
            [AMAUserProfileLogger logAttributeNameTooLong:attributeName];
            NSString *expectedMessage = @"Attribute update with name 'ATTRIBUTE_NAME' is ignored. Name is too long.";
            [[logSpy.messages should] equal:@[ messageWithText(expectedMessage) ]];
        });
    });
    context(@"Too many custom attributes", ^{
        it(@"Should log with valid message", ^{
            [AMAUserProfileLogger logTooManyCustomAttributesWithAttributeName:attributeName];
            NSString *expectedMessage = @"Attribute update with name 'ATTRIBUTE_NAME' is ignored. "
                                         "Too many custom attribute updates were given.";
            [[logSpy.messages should] equal:@[ messageWithText(expectedMessage) ]];
        });
    });
    context(@"Forbidden prefix", ^{
        it(@"Should log with valid message", ^{
            [AMAUserProfileLogger logForbiddenAttributeNamePrefixWithName:attributeName forbiddenPrefix:@"PREFIX"];
            NSString *expectedMessage = @"Attribute update with name 'ATTRIBUTE_NAME' is ignored. "
                                         "Prefix 'PREFIX' is reserved for predefined attributes.";
            [[logSpy.messages should] equal:@[ messageWithText(expectedMessage) ]];
        });
    });
    context(@"Attribute value truncation", ^{
        it(@"Should log with valid message", ^{
            [AMAUserProfileLogger logStringAttributeValueTruncation:string attributeName:attributeName];
            NSString *expectedMessage = @"Value of attribute 'ATTRIBUTE_NAME' was truncated: 'STRING'.";
            [[logSpy.messages should] equal:@[ messageWithText(expectedMessage) ]];
        });
    });
    context(@"Invalid date", ^{
        it(@"Should log with valid message", ^{
            [AMAUserProfileLogger logInvalidDateWithAttributeName:attributeName];
            NSString *expectedMessage = @"Attribute update with name 'ATTRIBUTE_NAME' is ignored. "
                                         "Invalid date was passed.";
            [[logSpy.messages should] equal:@[ messageWithText(expectedMessage) ]];
        });
    });
    context(@"Invalid gender", ^{
        it(@"Should log with valid message", ^{
            [AMAUserProfileLogger logInvalidGenderTypeWithAttributeName:attributeName];
            NSString *expectedMessage = @"Attribute update with name 'ATTRIBUTE_NAME' is ignored. "
                                         "Invalid gender type was passed.";
            [[logSpy.messages should] equal:@[ messageWithText(expectedMessage) ]];
        });
    });
    context(@"Profile ID is too long", ^{
        it(@"Should log with valid message", ^{
            [AMAUserProfileLogger logProfileIDTooLong:string];
            NSString *expectedMessage = @"Profile ID 'STRING' was truncated.";
            [[logSpy.messages should] equal:@[ messageWithText(expectedMessage) ]];
        });
    });

});

SPEC_END
