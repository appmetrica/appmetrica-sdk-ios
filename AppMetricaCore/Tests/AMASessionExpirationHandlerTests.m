#import <AppMetricaKiwi/AppMetricaKiwi.h>

#import "AMADate.h"
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaInMemoryConfiguration.h"
#import "AMAReporterConfiguration.h"
#import "AMASession.h"
#import "AMASessionExpirationHandler.h"
#import "AMAMetricaConfigurationTestUtilities.h"

SPEC_BEGIN(AMASessionExpirationHandlerTests)

describe(@"AMASessionExpirationHandler", ^{
    NSString *const apiKey = @"test-api-key";

    let(reporterConfigMock, ^{
        AMAReporterConfiguration *config = [AMAReporterConfiguration mock];
        [config stub:@selector(sessionTimeout) andReturn:theValue(1800)]; // 30 minutes
        return config;
    });
    
    let(config, ^{
        [AMAMetricaConfigurationTestUtilities stubConfiguration];
        AMAMetricaConfiguration *config = [AMAMetricaConfiguration sharedInstance];
        [config stub:@selector(configurationForApiKey:) andReturn:reporterConfigMock withArguments:apiKey];
        return config;
    });
    afterEach(^{
        [AMAMetricaConfigurationTestUtilities destubConfiguration];
        [AMAMetricaConfiguration.sharedInstance clearStubs];
    });
    
    let(sessionHandler, ^{ return [[AMASessionExpirationHandler alloc] initWithConfiguration:config APIKey:apiKey]; });

    context(@"When session is nil", ^{
        it(@"should return AMASessionExpirationTypeInvalid", ^{
            AMASessionExpirationType result = [sessionHandler expirationTypeForSession:nil withDate:[NSDate date]];
            [[theValue(result) should] equal:@(AMASessionExpirationTypeInvalid)];
        });
    });
    
    context(@"When session started in future", ^{
        it(@"should return AMASessionExpirationTypePastDate", ^{
            AMASession *session = [AMASession new];
            session.startDate = [AMADate new];
            session.startDate.deviceDate = [NSDate dateWithTimeIntervalSinceNow:3600]; // 1 hour in the future

            AMASessionExpirationType result = [sessionHandler expirationTypeForSession:session withDate:[NSDate date]];
            [[theValue(result) should] equal:@(AMASessionExpirationTypePastDate)];
        });
    });

    context(@"When session exceeds max duration", ^{
        it(@"should return AMASessionExpirationTypeDurationLimit", ^{
            AMASession *session = [AMASession new];
            session.startDate = [AMADate new];
            session.startDate.deviceDate = [NSDate dateWithTimeIntervalSinceNow:-3601]; // 1 hour and 1 second in the past
            
            config.inMemory.sessionMaxDuration = 3600; // 1 hour

            AMASessionExpirationType result = [sessionHandler expirationTypeForSession:session withDate:[NSDate date]];
            [[theValue(result) should] equal:@(AMASessionExpirationTypeDurationLimit)];
        });
    });
    
    context(@"When session exceeds timeout", ^{
        it(@"should return AMASessionExpirationTypeTimeout", ^{
            AMASession *session = [AMASession new];
            session.startDate.deviceDate = [NSDate dateWithTimeIntervalSinceNow:-7201]; // 2 hours and 1 second in the past
            session.pauseTime = [NSDate dateWithTimeIntervalSinceNow:-3601]; // 1 hour and 1 second in the past

            AMAReporterConfiguration *reporterConfigMock = [AMAReporterConfiguration nullMock];
            [reporterConfigMock stub:@selector(sessionTimeout) andReturn:theValue(3600)]; // 1 hour

            AMASessionExpirationType result = [sessionHandler expirationTypeForSession:session withDate:[NSDate date]];
            [[theValue(result) should] equal:@(AMASessionExpirationTypeTimeout)];
        });
    });

    
    context(@"When session does not meet any expiration criteria", ^{
        it(@"should return AMASessionExpirationTypeNone", ^{
            AMASession *session = [AMASession new];
            session.startDate = [AMADate new];
            session.startDate.deviceDate = [NSDate dateWithTimeIntervalSinceNow:-1800]; // 30 minutes in the past
            session.pauseTime = [NSDate dateWithTimeIntervalSinceNow:-900]; // 15 minutes in the past
            
            config.inMemory.sessionMaxDuration = 3600; // 1 hour
            // sessionTimeout is 30 minutes
            
            AMASessionExpirationType result = [sessionHandler expirationTypeForSession:session withDate:[NSDate date]];
            [[theValue(result) should] equal:@(AMASessionExpirationTypeNone)];
        });
    });

    context(@"When session is of type background and exceeds timeout", ^{
        it(@"should return AMASessionExpirationTypeDurationLimit", ^{
            AMASession *session = [AMASession new];
            session.startDate = [AMADate new];
            session.startDate.deviceDate = [NSDate dateWithTimeIntervalSinceNow:-7201]; // 2 hours and 1 second in the past
            session.pauseTime = [NSDate dateWithTimeIntervalSinceNow:-3601]; // 1 hour and 1 second in the past
            session.type = AMASessionTypeBackground;
            
            config.inMemory.sessionMaxDuration = 7200; // 2 hours
            config.inMemory.backgroundSessionTimeout = 3600; // 1 hour

            AMASessionExpirationType result = [sessionHandler expirationTypeForSession:session withDate:[NSDate date]];
            [[theValue(result) should] equal:@(AMASessionExpirationTypeDurationLimit)];
        });
    });
    
    context(@"When session exceeds maxDuration and timeout at the same time", ^{
        it(@"should return AMASessionExpirationTypeDurationLimit", ^{
            AMASession *session = [AMASession new];
            session.startDate = [AMADate new];
            session.startDate.deviceDate = [NSDate dateWithTimeIntervalSinceNow:-7201]; // 2 hours and 1 second in the past
            session.pauseTime = [NSDate dateWithTimeIntervalSinceNow:-3601]; // 1 hour and 1 second in the past

            config.inMemory.sessionMaxDuration = 3600; // 1 hour
            [reporterConfigMock stub:@selector(sessionTimeout) andReturn:theValue(3600)]; // 1 hour

            AMASessionExpirationType result = [sessionHandler expirationTypeForSession:session withDate:[NSDate date]];
            [[theValue(result) should] equal:@(AMASessionExpirationTypeDurationLimit)];
        });
    });


    context(@"When session is active and within session timeout", ^{
        it(@"should return AMASessionExpirationTypeNone", ^{
            AMASession *session = [AMASession new];
            session.startDate = [AMADate new];
            session.startDate.deviceDate = [NSDate dateWithTimeIntervalSinceNow:-1799]; // 29 minutes and 59 seconds in the past
            session.pauseTime = [NSDate dateWithTimeIntervalSinceNow:-899]; // 14 minutes and 59 seconds in the past

            AMASessionExpirationType result = [sessionHandler expirationTypeForSession:session withDate:[NSDate date]];
            [[theValue(result) should] equal:@(AMASessionExpirationTypeNone)];
        });
    });

    context(@"When session is background type and within background session timeout", ^{
        it(@"should return AMASessionExpirationTypeNone", ^{
            AMASession *session = [AMASession new];
            session.startDate = [AMADate new];
            session.startDate.deviceDate = [NSDate dateWithTimeIntervalSinceNow:-3599]; // 59 minutes and 59 seconds in the past
            session.pauseTime = [NSDate dateWithTimeIntervalSinceNow:-3599]; // 59 minutes and 59 seconds in the past
            session.type = AMASessionTypeBackground;

            AMASessionExpirationType result = [sessionHandler expirationTypeForSession:session withDate:[NSDate date]];
            [[theValue(result) should] equal:@(AMASessionExpirationTypeNone)];
        });
    });

    context(@"When session has not been paused", ^{
        it(@"should return AMASessionExpirationTypeNone", ^{
            AMASession *session = [AMASession new];
            session.startDate = [AMADate new];
            session.startDate.deviceDate = [NSDate dateWithTimeIntervalSinceNow:-1799]; // 29 minutes and 59 seconds in the past
            session.pauseTime = nil;

            AMASessionExpirationType result = [sessionHandler expirationTypeForSession:session withDate:[NSDate date]];
            [[theValue(result) should] equal:@(AMASessionExpirationTypeNone)];
        });
    });

    context(@"When session is in the future and has not been paused", ^{
        it(@"should return AMASessionExpirationTypePastDate", ^{
            AMASession *session = [AMASession new];
            session.startDate = [AMADate new];
            session.startDate.deviceDate = [NSDate dateWithTimeIntervalSinceNow:1800]; // 30 minutes in the future
            session.pauseTime = nil;

            AMASessionExpirationType result = [sessionHandler expirationTypeForSession:session withDate:[NSDate date]];
            [[theValue(result) should] equal:@(AMASessionExpirationTypePastDate)];
        });
    });
    
    context(@"When session is exactly at session timeout", ^{
        it(@"should return AMASessionExpirationTypeNone", ^{
            AMASession *session = [AMASession new];
            session.startDate = [AMADate new];
            session.startDate.deviceDate = [NSDate dateWithTimeIntervalSinceNow:-1800]; // Exactly 30 minutes in the past
            session.pauseTime = [NSDate dateWithTimeIntervalSinceNow:-900]; // 15 minutes in the past

            AMASessionExpirationType result = [sessionHandler expirationTypeForSession:session withDate:[NSDate date]];
            [[theValue(result) should] equal:@(AMASessionExpirationTypeNone)];
        });
    });

    context(@"When session has just started", ^{
        it(@"should return AMASessionExpirationTypeNone", ^{
            AMASession *session = [AMASession new];
            session.startDate = [AMADate new];
            session.startDate.deviceDate = [NSDate date]; // Now

            AMASessionExpirationType result = [sessionHandler expirationTypeForSession:session withDate:[NSDate date]];
            [[theValue(result) should] equal:@(AMASessionExpirationTypeNone)];
        });
    });

    context(@"When session started and paused at the same time", ^{
        it(@"should return AMASessionExpirationTypeNone", ^{
            AMASession *session = [AMASession new];
            session.startDate = [AMADate new];
            session.startDate.deviceDate = [NSDate date]; // Now
            session.pauseTime = session.startDate.deviceDate;

            AMASessionExpirationType result = [sessionHandler expirationTypeForSession:session withDate:[NSDate date]];
            [[theValue(result) should] equal:@(AMASessionExpirationTypeNone)];
        });
    });

    context(@"When session started in the past and paused in the future", ^{
        it(@"should return AMASessionExpirationTypeNone", ^{
            AMASession *session = [AMASession new];
            session.startDate = [AMADate new];
            session.startDate.deviceDate = [NSDate dateWithTimeIntervalSinceNow:-1800]; // 30 minutes in the past
            session.pauseTime = [NSDate dateWithTimeIntervalSinceNow:1800]; // 30 minutes in the future

            AMASessionExpirationType result = [sessionHandler expirationTypeForSession:session withDate:[NSDate date]];
            [[theValue(result) should] equal:@(AMASessionExpirationTypeNone)];
        });
    });
    
    context(@"When session's last event is beyond the session timeout", ^{
        it(@"should return AMASessionExpirationTypeTimeout", ^{
            AMASession *session = [AMASession new];
            session.startDate = [AMADate new];
            session.startDate.deviceDate = [NSDate dateWithTimeIntervalSinceNow:-3601]; // 1 hour and 1 second in the past
            session.pauseTime = [NSDate dateWithTimeIntervalSinceNow:-1801]; // 30 minutes and 1 second in the past
            session.lastEventTime = [NSDate dateWithTimeIntervalSinceNow:-900]; // 15 minutes in the past

            AMASessionExpirationType result = [sessionHandler expirationTypeForSession:session withDate:[NSDate date]];
            [[theValue(result) should] equal:@(AMASessionExpirationTypeTimeout)];
        });
    });
});

SPEC_END

