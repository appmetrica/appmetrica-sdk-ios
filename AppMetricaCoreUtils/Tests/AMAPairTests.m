
#import <Foundation/Foundation.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

SPEC_BEGIN(AMAPairTests)

describe(@"AMAPair", ^{

    AMAPair *__block pair;

    context(@"Nil fields", ^{
        beforeEach(^{
            pair = [[AMAPair alloc] initWithKey:nil value:nil];
        });
        it(@"Key should be nil", ^{
            [[pair.key should] beNil];
        });
        it(@"Value should be nil", ^{
            [[pair.value should] beNil];
        });
    });

    context(@"Non nil fields", ^{
        NSString *key = @"some key";
        NSString *value = @"some value";
        beforeEach(^{
            pair = [[AMAPair alloc] initWithKey:key value:value];
        });
        it(@"Key should be right", ^{
            [[pair.key should] equal:key];
        });
        it(@"Value should be right", ^{
            [[pair.value should] equal:value];
        });
    });
});

SPEC_END

