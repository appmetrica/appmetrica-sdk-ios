
#import <Kiwi/Kiwi.h>
#import "AMAMetricaParametersScanner.h"

static NSString *const kAMAValidAPIKey = @"21784";
static uint32_t const kAMAValidAPIKeyUInt = 21784;

static NSString *const kAMAValidAppBuildNumber = @"3417";

SPEC_BEGIN(AMAMetricaParametersScannerSpec)

describe(@"AMAMetricaParametersScanner", ^{
    context(@"Should scan APIKey", ^{

        it(@"Should recognize valid appBuildNumber", ^{
            uint32_t uintAPIKey;
            BOOL success = [AMAMetricaParametersScanner scanAPIKey:&uintAPIKey inString:kAMAValidAPIKey];

            [[theValue(success) should] equal:theValue(YES)];
            [[theValue(uintAPIKey) should] equal:theValue(kAMAValidAPIKeyUInt)];
        });

        it(@"Should not treat zero as APIKey", ^{
            uint32_t uintAPIKey;
            BOOL success = [AMAMetricaParametersScanner scanAPIKey:&uintAPIKey inString:@"0"];

            [[theValue(success) should] equal:theValue(NO)];
        });

        it(@"Should not treat non number string as APIKey", ^{
            uint32_t uintAPIKey;
            BOOL success = [AMAMetricaParametersScanner scanAPIKey:&uintAPIKey inString:@"Not a number"];

            [[theValue(success) should] equal:theValue(NO)];
        });

        it(@"Should not treat empty string as APIKey", ^{
            uint32_t uintAPIKey;
            BOOL success = [AMAMetricaParametersScanner scanAPIKey:&uintAPIKey inString:@""];

            [[theValue(success) should] equal:theValue(NO)];
        });

        it(@"Should not treat nil string as APIKey", ^{
            uint32_t uintAPIKey;
            BOOL success = [AMAMetricaParametersScanner scanAPIKey:&uintAPIKey inString:nil];

            [[theValue(success) should] equal:theValue(NO)];
        });

        it(@"Should not treat negative numbers as APIKey", ^{
            uint32_t uintAPIKey;
            BOOL success = [AMAMetricaParametersScanner scanAPIKey:&uintAPIKey inString:@"-154"];

            [[theValue(success) should] equal:theValue(NO)];
        });

        it(@"Should not treat non integers as APIKey", ^{
            uint32_t uintAPIKey;
            BOOL success = [AMAMetricaParametersScanner scanAPIKey:&uintAPIKey inString:@"10.5"];

            [[theValue(success) should] equal:theValue(NO)];
        });

        it(@"Should not treat as APIKey non integer string with an integer in the beginning", ^{
            uint32_t uintAPIKey;
            BOOL success = [AMAMetricaParametersScanner scanAPIKey:&uintAPIKey inString:@"10 some other stuff"];
            
            [[theValue(success) should] equal:theValue(NO)];
        });
    });

    context(@"Should scan AppBuildNumber", ^{

        it(@"Should recognize valid AppBuildNumber", ^{
            uint32_t uintAppBuildNmber;
            BOOL success = [AMAMetricaParametersScanner scanAppBuildNumber:&uintAppBuildNmber inString:kAMAValidAPIKey];

            [[theValue(success) should] equal:theValue(YES)];
            [[theValue(uintAppBuildNmber) should] equal:theValue(kAMAValidAPIKeyUInt)];
        });

        it(@"Should treat zero as AppBuildNumber", ^{
            uint32_t uintAppBuildNmber;
            BOOL success = [AMAMetricaParametersScanner scanAppBuildNumber:&uintAppBuildNmber inString:@"0"];

            [[theValue(success) should] equal:theValue(YES)];
        });

        it(@"Should not treat non number string as AppBuildNumber", ^{
            uint32_t uintAppBuildNmber;
            BOOL success = [AMAMetricaParametersScanner scanAppBuildNumber:&uintAppBuildNmber inString:@"Not a number"];

            [[theValue(success) should] equal:theValue(NO)];
        });

        it(@"Should not treat empty string as AppBuildNumber", ^{
            uint32_t uintAppBuildNmber;
            BOOL success = [AMAMetricaParametersScanner scanAppBuildNumber:&uintAppBuildNmber inString:@""];

            [[theValue(success) should] equal:theValue(NO)];
        });

        it(@"Should not treat nil string as AppBuildNumber", ^{
            uint32_t uintAppBuildNmber;
            BOOL success = [AMAMetricaParametersScanner scanAppBuildNumber:&uintAppBuildNmber inString:nil];

            [[theValue(success) should] equal:theValue(NO)];
        });

        it(@"Should not treat negative numbers as AppBuildNumber", ^{
            uint32_t uintAppBuildNmber;
            BOOL success = [AMAMetricaParametersScanner scanAppBuildNumber:&uintAppBuildNmber inString:@"-154"];

            [[theValue(success) should] equal:theValue(NO)];
        });

        it(@"Should not treat non integers as AppBuildNumber", ^{
            uint32_t uintAppBuildNmber;
            BOOL success = [AMAMetricaParametersScanner scanAppBuildNumber:&uintAppBuildNmber inString:@"10.5"];

            [[theValue(success) should] equal:theValue(NO)];
        });

        it(@"Should not treat as AppBuildNumber non integer string with an integer in the beginning", ^{
            uint32_t uintAppBuildNmber;
            BOOL success = [AMAMetricaParametersScanner scanAppBuildNumber:&uintAppBuildNmber inString:@"10 some other stuff"];
            
            [[theValue(success) should] equal:theValue(NO)];
        });
    });
});

SPEC_END
