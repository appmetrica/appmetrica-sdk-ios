
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAAttributeNameProvider.h"

SPEC_BEGIN(AMAAttributeNameProviderTests)

describe(@"AMAAttributeNameProvider", ^{

    it(@"Should return name", ^{
        [[[AMAAttributeNameProvider name] should] equal:@"appmetrica_name"];
    });
    it(@"Should return gender", ^{
        [[[AMAAttributeNameProvider gender] should] equal:@"appmetrica_gender"];
    });
    it(@"Should return birthDate", ^{
        [[[AMAAttributeNameProvider birthDate] should] equal:@"appmetrica_birth_date"];
    });
    it(@"Should return notificationsEnabled", ^{
        [[[AMAAttributeNameProvider notificationsEnabled] should] equal:@"appmetrica_notifications_enabled"];
    });
    context(@"Custom attributes", ^{
        NSString *const customName = @"MY_ATTRIBUTE";
        it(@"Should return name", ^{
            [[[AMAAttributeNameProvider customStringWithName:customName] should] equal:customName];
        });
        it(@"Should return name", ^{
            [[[AMAAttributeNameProvider customNumberWithName:customName] should] equal:customName];
        });
        it(@"Should return name", ^{
            [[[AMAAttributeNameProvider customCounterWithName:customName] should] equal:customName];
        });
        it(@"Should return name", ^{
            [[[AMAAttributeNameProvider customBoolWithName:customName] should] equal:customName];
        });
    });

});

SPEC_END
