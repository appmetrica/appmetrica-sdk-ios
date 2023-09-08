
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAAppMetricaConfiguration.h"
#import "AMAAppMetricaConfiguration+Extended.h"

static NSString *const kAMAValidAppVersion = @"v1.32";
static NSString *const kAMAValidAppBuildNumber = @"3417";

SPEC_BEGIN(AMAAppMetricaConfigurationTests)

describe(@"AMAAppMetricaConfiguration", ^{

    NSString *apiKey = @"550e8400-e29b-41d4-a716-446655440000";

    context(@"Defaults", ^{
        it(@"Should have enabled revenue auto tracking", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
            [[theValue(config.revenueAutoTrackingEnabled) should] beYes];
        });
        it(@"Should have enabled app open tracking", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
            [[theValue(config.appOpenTrackingEnabled) should] beYes];
        });
    });

    context(@"Handling Invalid Values", ^{

        __block AMATestAssertionHandler *handler = nil;
        beforeAll(^{
            handler = [AMATestAssertionHandler new];
            [handler beginAssertIgnoring];
        });
        afterAll(^{
            [handler endAssertIgnoring];
        });

        it(@"Should not be created with non number string as APIKey", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:@"Not a number"];
            [[config should] beNil];
        });

        it(@"Should not be created with empty string as APIKey", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:@""];
            [[config should] beNil];
        });

        it(@"Should not be created with nil string as APIKey", ^{
            NSString *nilString = nil;
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:nilString];
            [[config should] beNil];
        });

        it(@"Should ignore attempt to set empty appVersion", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
            config.appVersion = @"";
            [[config.appVersion should] beNil];
        });

        it(@"Should ignore attempt to set nil as appVersion", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
            config.appVersion = kAMAValidAppVersion;
            config.appVersion = nil;
            [[config.appVersion should] equal:kAMAValidAppVersion];
        });

        it(@"Should set valid appBuildNumber", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
            config.appBuildNumber = kAMAValidAppBuildNumber;
            [[config.appBuildNumber should] equal:kAMAValidAppBuildNumber];
        });

        it(@"Should ignore attempt to set empty appBuildNumber", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
            config.appBuildNumber = @"";
            [[config.appBuildNumber should] beNil];
        });

        it(@"Should ignore attempt to set nil as appBuildNumber", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];

            config.appBuildNumber = kAMAValidAppBuildNumber;
            config.appBuildNumber = nil;

            [[config.appBuildNumber should] equal:kAMAValidAppBuildNumber];
        });

        it(@"Should ignore attempt to set negative appBuildNumber", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
            config.appBuildNumber = @"-154";
            [[config.appBuildNumber should] beNil];
        });

        it(@"Should ignore attempt to set non integer appBuildNumber", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
            config.appBuildNumber = @"10.5";
            [[config.appBuildNumber should] beNil];
        });

        it(@"Should ignore attempt to set non integer string with an integer in the beginning appBuildNumber", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
            config.appBuildNumber = @"10 some other stuff";
            [[config.appBuildNumber should] beNil];
        });

        it(@"Should ignore attempt to set non number appBuildNumber", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
            config.appBuildNumber = @"Not a number";
            [[config.appBuildNumber should] beNil];
        });
    });
});

SPEC_END
