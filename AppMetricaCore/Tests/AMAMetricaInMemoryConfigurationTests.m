
#import <Kiwi/Kiwi.h>
#import "AMAMetricaInMemoryConfiguration.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>

SPEC_BEGIN(AMAMetricaInMemoryConfigurationTests)

describe(@"AMAMetricaInMemoryConfiguration", ^{

    NSString *const appVersion = @"1.2.3";
    NSUInteger const appBuildNumber = 108;

    AMAMetricaInMemoryConfiguration *__block configuration = nil;

    beforeEach(^{
        [AMAPlatformDescription stub:@selector(appVersion) andReturn:appVersion];
        [AMAPlatformDescription stub:@selector(appBuildNumber) andReturn:[@(appBuildNumber) stringValue]];

        configuration = [[AMAMetricaInMemoryConfiguration alloc] init];
    });

    it(@"Should have valid batch size", ^{
        [[theValue(configuration.batchSize) should] equal:theValue(10000)];
    });
    it(@"Should have valid trim events percent", ^{
        [[theValue(configuration.trimEventsPercent) should] equal:0.1 withDelta:0.001];
    });
    it(@"Should have valid max protobuf message size", ^{
        [[theValue(configuration.maxProtobufMsgSize) should] equal:theValue(245 << 10)];
    });
    it(@"Should have valid max session duration", ^{
        [[theValue(configuration.sessionMaxDuration) should] equal:theValue(24 * 60 * 60)];
    });
    it(@"Should have valid background session timeout", ^{
        [[theValue(configuration.backgroundSessionTimeout) should] equal:theValue(60 * 60)];
    });
    it(@"Should have valid app version", ^{
        [[configuration.appVersion should] equal:appVersion];
    });
    it(@"Should have valid app build number", ^{
        [[theValue(configuration.appBuildNumber) should] equal:theValue(appBuildNumber)];
    });
    it(@"Should have valid session timestamp time update interval", ^{
        [[theValue(configuration.updateSessionStampInterval) should] equal:theValue(10)];
    });
    it(@"Should have not enabled activation as uppdate flag", ^{
        [[theValue(configuration.handleFirstActivationAsUpdate) should] beNo];
    });
    it(@"Should have not enabled activation as session start flag", ^{
        [[theValue(configuration.handleActivationAsSessionStart) should] beNo];
    });
    it(@"Should have enabled sessions auto tracking", ^{
        [[theValue(configuration.sessionsAutoTracking) should] beYes];
    });
    it(@"Should have lazy loaded app build UID", ^{
        AMABuildUID *buildUID = [AMABuildUID nullMock];
        [AMABuildUID stub:@selector(buildUID) andReturn:buildUID];
        [[configuration.appBuildUID should] equal:buildUID];
    });
    context(@"Started flag", ^{
        it(@"Should be NO", ^{
            [[theValue(configuration.appMetricaStarted) should] beNo];
        });
        it(@"Should be YES after marked", ^{
            [configuration markAppMetricaStarted];
            [[theValue(configuration.appMetricaStarted) should] beYes];
        });
    });
    context(@"Impl created flag", ^{
        it(@"Should be NO", ^{
            [[theValue(configuration.appMetricaImplCreated) should] beNo];
        });
        it(@"Should be YES after marked", ^{
            [configuration markAppMetricaImplCreated];
            [[theValue(configuration.appMetricaImplCreated) should] beYes];
        });
    });

    it(@"Should have valid default startup hosts", ^{
        [[kAMADefaultStartupHost should] equal:@"https://startup.mobile.yandex.net"];
    });
    it(@"Should have valid library api key", ^{
        [[kAMAMetricaLibraryApiKey should] equal:@"20799a27-fa80-4b36-b2db-0f8141f24180"];
    });

});

SPEC_END

