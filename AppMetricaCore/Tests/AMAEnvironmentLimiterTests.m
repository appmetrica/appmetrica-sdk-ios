
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAEnvironmentLimiter.h"

SPEC_BEGIN(AMAEnvironmentLimiterTests)

describe(@"AMAEnvironmentLimiter", ^{

    NSUInteger const countLimit = 2;
    NSUInteger const totalLengthLimit = 25;
    NSString *const key = @"KEY";
    NSString *const value = @"VALUE";

    NSDictionary *__block environment = nil;
    AMATestTruncator *__block keyTruncator = nil;
    AMATestTruncator *__block valueTruncator = nil;
    AMAEnvironmentLimiter *__block limiter = nil;

    beforeEach(^{
        environment = [NSDictionary dictionary];
        keyTruncator = [[AMATestTruncator alloc] init];
        valueTruncator = [[AMATestTruncator alloc] init];
        limiter = [[AMAEnvironmentLimiter alloc] initWithCountLimit:countLimit
                                                   totalLengthLimit:totalLengthLimit
                                                       keyTruncator:keyTruncator
                                                     valueTruncator:valueTruncator];
    });

    context(@"Within limits", ^{
        it(@"Should add key", ^{
            NSDictionary *newEnvironment = [limiter limitEnvironment:environment afterAddingValue:value forKey:key];
            [[newEnvironment should] haveValueForKey:key];
        });
        it(@"Should add value", ^{
            NSDictionary *newEnvironment = [limiter limitEnvironment:environment afterAddingValue:value forKey:key];
            [[newEnvironment should] haveValue:value forKey:key];
        });
        context(@"Empty environment", ^{
            beforeEach(^{
                environment = nil;
            });
            it(@"Should add key", ^{
                NSDictionary *newEnvironment = [limiter limitEnvironment:environment afterAddingValue:value forKey:key];
                [[newEnvironment should] haveValueForKey:key];
            });
            it(@"Should add value", ^{
                NSDictionary *newEnvironment = [limiter limitEnvironment:environment afterAddingValue:value forKey:key];
                [[newEnvironment should] haveValue:value forKey:key];
            });
        });
    });
    context(@"Key", ^{
        context(@"Nil", ^{
            it(@"Should not change environment", ^{
                NSString *nilKey = nil;
                NSDictionary *newEnvironment = [limiter limitEnvironment:environment
                                                        afterAddingValue:value
                                                                  forKey:nilKey];
                [[newEnvironment should] equal:environment];
            });
        });
        context(@"Long", ^{
            NSString *const truncatedKey = @"TRUNCATED_KEY";
            beforeEach(^{
                [keyTruncator enableTruncationWithResult:truncatedKey bytesTruncated:3];
            });
            it(@"Should truncate key", ^{
                NSDictionary *newEnvironment = [limiter limitEnvironment:environment afterAddingValue:value forKey:key];
                [[newEnvironment should] haveValueForKey:truncatedKey];
            });
            it(@"Should add value", ^{
                NSDictionary *newEnvironment = [limiter limitEnvironment:environment afterAddingValue:value forKey:key];
                [[newEnvironment should] haveValue:value forKey:truncatedKey];
            });
        });
    });
    context(@"Value", ^{
        context(@"Nil", ^{
            it(@"Should not change environment", ^{
                NSString *nilValue = nil;
                NSDictionary *newEnvironment = [limiter limitEnvironment:environment
                                                        afterAddingValue:nilValue
                                                                  forKey:key];
                [[newEnvironment should] equal:environment];
            });
        });
        context(@"Long", ^{
            NSString *const truncatedValue = @"TRUNCATED_VALUE";
            beforeEach(^{
                [valueTruncator enableTruncationWithResult:truncatedValue bytesTruncated:3];
            });
            it(@"Should add key", ^{
                NSDictionary *newEnvironment = [limiter limitEnvironment:environment afterAddingValue:value forKey:key];
                [[newEnvironment should] haveValueForKey:key];
            });
            it(@"Should truncate value", ^{
                NSDictionary *newEnvironment = [limiter limitEnvironment:environment afterAddingValue:value forKey:key];
                [[newEnvironment should] haveValue:truncatedValue forKey:key];
            });
        });
    });
    context(@"Count limit", ^{
        context(@"New key", ^{
            beforeEach(^{
                environment = @{ @"OTHER_KEY": @"OTHER_VALUE", @"a": @"b" };
            });
            it(@"Should not change environment", ^{
                NSDictionary *newEnvironment = [limiter limitEnvironment:environment afterAddingValue:value forKey:key];
                [[newEnvironment should] equal:environment];
            });
        });
        context(@"Existing key", ^{
            beforeEach(^{
                environment = @{ key: @"OTHER_VALUE", @"a": @"b" };
            });
            it(@"Should update value", ^{
                NSDictionary *newEnvironment = [limiter limitEnvironment:environment afterAddingValue:value forKey:key];
                [[newEnvironment should] haveValue:value forKey:key];
            });
        });
    });
    context(@"Total length limit", ^{
        NSString *const longKey = @"THIS KEY LENGTH IS EQUAL 27";
        NSString *const longValue = @"THIS VALUE LENGTH IS EQUAL 29";
        context(@"Empty environment", ^{
            beforeEach(^{
                environment = nil;
            });
            it(@"Should add small pair", ^{
                NSDictionary *newEnvironment = [limiter limitEnvironment:environment afterAddingValue:value forKey:key];
                [[newEnvironment should] haveValue:value forKey:key];
            });
            it(@"Should not add long pair", ^{
                NSDictionary *newEnvironment = [limiter limitEnvironment:environment
                                                        afterAddingValue:longValue
                                                                  forKey:longKey];
                [[newEnvironment should] beNil];
            });
        });
        context(@"Existing key", ^{
            beforeEach(^{
                environment = @{ key: @"OTHER_VALUE" };
            });
            it(@"Should update with small value", ^{
                NSDictionary *newEnvironment = [limiter limitEnvironment:environment afterAddingValue:value forKey:key];
                [[newEnvironment should] haveValue:value forKey:key];
            });
            it(@"Should not update with long value", ^{
                NSDictionary *newEnvironment = [limiter limitEnvironment:environment
                                                        afterAddingValue:longValue
                                                                  forKey:key];
                [[newEnvironment should] equal:environment];
            });
        });
        context(@"New key", ^{
            beforeEach(^{
                environment = @{ @"OTHER_KEY": @"OTHER_VALUE" };
            });
            it(@"Should update environment with really small pair", ^{
                NSString *smallKey = @"a";
                NSString *smallValue = @"b";
                NSDictionary *newEnvironment = [limiter limitEnvironment:environment
                                                        afterAddingValue:smallValue
                                                                  forKey:smallKey];
                [[newEnvironment should] haveValue:smallValue forKey:smallKey];
            });
            it(@"Should not update with normal pair", ^{
                NSDictionary *newEnvironment = [limiter limitEnvironment:environment afterAddingValue:value forKey:key];
                [[newEnvironment should] equal:environment];
            });
        });
    });

});

SPEC_END
