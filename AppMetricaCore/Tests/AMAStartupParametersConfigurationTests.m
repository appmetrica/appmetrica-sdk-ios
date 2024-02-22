
#import <Kiwi/Kiwi.h>
#import "AMACore.h"
#import "AMAStartupParametersConfiguration.h"
#import "AMAAttributionSerializer.h"
#import "AMAPair.h"
#import "AMAAttributionModelConfiguration.h"

SPEC_BEGIN(AMAStartupParametersConfigurationTests)

describe(@"AMAStartupParametersConfiguration", ^{

    NSObject<AMAKeyValueStoring> *__block storage = nil;
    AMAStartupParametersConfiguration *__block configuration = nil;

    beforeEach(^{
        storage = [KWMock nullMockForProtocol:@protocol(AMAKeyValueStoring)];
        configuration = [[AMAStartupParametersConfiguration alloc] initWithStorage:storage];
    });

    it(@"Should have valid all keys", ^{
        NSArray *expectedKeys = @[
            @"asa.token.reporting.end",
            @"asa.token.reporting.first",
            @"asa.token.reporting.interval",
            @"attribution.deeplink.conditions",
            @"extensions.reporting.enabled",
            @"extensions.reporting.interval",
            @"extensions.reporting.launch.delay",
            @"libs.dynamic.hook.enabled",
            @"initial.country",
            @"location.collecting.accuracy.accurate",
            @"location.collecting.accuracy.default",
            @"location.collecting.batch.records.count",
            @"location.collecting.distance.accurate",
            @"location.collecting.distance.default",
            @"location.collecting.enabled",
            @"location.collecting.flush.age.max",
            @"location.collecting.flush.records.count",
            @"location.collecting.hosts",
            @"location.collecting.store.records.max",
            @"location.collecting.update.automatic_pause",
            @"location.collecting.update.distance.min",
            @"location.collecting.update.interval.min",
            @"location.collecting.visits.enabled",
            @"permissions.collecting.enabled",
            @"permissions.collecting.force_send_interval",
            @"permissions.collecting.list",
            @"redirect.host",
            @"report.hosts",
            @"retry_policy.exponential_multiplier",
            @"retry_policy.max_interval_seconds",
            @"server.time.offset",
            @"startup.hosts",
            @"startup.permissions",
            @"stat.sending.disabled.reporting.interval",
            @"other.report.hosts",
            @"startup.update.interval",
            @"extended.parameters",
            @"apple_tracking.collecting.hosts",
            @"apple_tracking.collecting.resend_period",
            @"apple_tracking.collecting.retry_period",
        ];
        NSArray *keys = [AMAStartupParametersConfiguration allKeys];
        [[[NSSet setWithArray:keys] should] equal:[NSSet setWithArray:expectedKeys]];
    });

    context(@"Double values", ^{
        NSNumber *const value = @(23.42);
        beforeEach(^{
            [storage stub:@selector(doubleNumberForKey:error:) andReturn:value];
        });
        context(@"serverTimeOffset", ^{
            NSString *const key = @"server.time.offset";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(doubleNumberForKey:error:) withArguments:key, kw_any()];
                [configuration serverTimeOffset];
            });
            it(@"Should return valid value", ^{
                [[configuration.serverTimeOffset should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveDoubleNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.serverTimeOffset = value;
            });
        });
        context(@"statSendingDisabledReportingInterval", ^{
            NSString *const key = @"stat.sending.disabled.reporting.interval";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(doubleNumberForKey:error:) withArguments:key, kw_any()];
                [configuration statSendingDisabledReportingInterval];
            });
            it(@"Should return valid value", ^{
                [[configuration.statSendingDisabledReportingInterval should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveDoubleNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.statSendingDisabledReportingInterval = value;
            });
        });
        context(@"extensionsCollectingInterval", ^{
            NSString *const key = @"extensions.reporting.interval";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(doubleNumberForKey:error:) withArguments:key, kw_any()];
                [configuration extensionsCollectingInterval];
            });
            it(@"Should return valid value", ^{
                [[configuration.extensionsCollectingInterval should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveDoubleNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.extensionsCollectingInterval = value;
            });
        });
        context(@"extensionsCollectingLaunchDelay", ^{
            NSString *const key = @"extensions.reporting.launch.delay";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(doubleNumberForKey:error:) withArguments:key, kw_any()];
                [configuration extensionsCollectingLaunchDelay];
            });
            it(@"Should return valid value", ^{
                [[configuration.extensionsCollectingLaunchDelay should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveDoubleNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.extensionsCollectingLaunchDelay = value;
            });
        });
        context(@"locationMinUpdateInterval", ^{
            NSString *const key = @"location.collecting.update.interval.min";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(doubleNumberForKey:error:) withArguments:key, kw_any()];
                [configuration locationMinUpdateInterval];
            });
            it(@"Should return valid value", ^{
                [[configuration.locationMinUpdateInterval should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveDoubleNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.locationMinUpdateInterval = value;
            });
        });
        context(@"locationMinUpdateDistance", ^{
            NSString *const key = @"location.collecting.update.distance.min";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(doubleNumberForKey:error:) withArguments:key, kw_any()];
                [configuration locationMinUpdateDistance];
            });
            it(@"Should return valid value", ^{
                [[configuration.locationMinUpdateDistance should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveDoubleNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.locationMinUpdateDistance = value;
            });
        });
        context(@"locationMaxAgeToForceFlush", ^{
            NSString *const key = @"location.collecting.flush.age.max";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(doubleNumberForKey:error:) withArguments:key, kw_any()];
                [configuration locationMaxAgeToForceFlush];
            });
            it(@"Should return valid value", ^{
                [[configuration.locationMaxAgeToForceFlush should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveDoubleNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.locationMaxAgeToForceFlush = value;
            });
        });
        context(@"locationDefaultDesiredAccuracy", ^{
            NSString *const key = @"location.collecting.accuracy.default";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(doubleNumberForKey:error:) withArguments:key, kw_any()];
                [configuration locationDefaultDesiredAccuracy];
            });
            it(@"Should return valid value", ^{
                [[configuration.locationDefaultDesiredAccuracy should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveDoubleNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.locationDefaultDesiredAccuracy = value;
            });
        });
        context(@"locationAccurateDesiredAccuracy", ^{
            NSString *const key = @"location.collecting.accuracy.accurate";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(doubleNumberForKey:error:) withArguments:key, kw_any()];
                [configuration locationAccurateDesiredAccuracy];
            });
            it(@"Should return valid value", ^{
                [[configuration.locationAccurateDesiredAccuracy should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveDoubleNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.locationAccurateDesiredAccuracy = value;
            });
        });
        context(@"locationDefaultDistanceFilter", ^{
            NSString *const key = @"location.collecting.distance.default";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(doubleNumberForKey:error:) withArguments:key, kw_any()];
                [configuration locationDefaultDistanceFilter];
            });
            it(@"Should return valid value", ^{
                [[configuration.locationDefaultDistanceFilter should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveDoubleNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.locationDefaultDistanceFilter = value;
            });
        });
        context(@"locationAccurateDistanceFilter", ^{
            NSString *const key = @"location.collecting.distance.accurate";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(doubleNumberForKey:error:) withArguments:key, kw_any()];
                [configuration locationAccurateDistanceFilter];
            });
            it(@"Should return valid value", ^{
                [[configuration.locationAccurateDistanceFilter should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveDoubleNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.locationAccurateDistanceFilter = value;
            });
        });
        context(@"ASATokenFirstDelay", ^{
            NSString *const key = @"asa.token.reporting.first";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(doubleNumberForKey:error:) withArguments:key, kw_any()];
                [configuration ASATokenFirstDelay];
            });
            it(@"Should return valid value", ^{
                [[configuration.ASATokenFirstDelay should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveDoubleNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.ASATokenFirstDelay = value;
            });
        });
        context(@"ASATokenReportingInterval", ^{
            NSString *const key = @"asa.token.reporting.interval";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(doubleNumberForKey:error:) withArguments:key, kw_any()];
                [configuration ASATokenReportingInterval];
            });
            it(@"Should return valid value", ^{
                [[configuration.ASATokenReportingInterval should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveDoubleNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.ASATokenReportingInterval = value;
            });
        });
        context(@"ASATokenEndReportingInterval", ^{
            NSString *const key = @"asa.token.reporting.end";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(doubleNumberForKey:error:) withArguments:key, kw_any()];
                [configuration ASATokenEndReportingInterval];
            });
            it(@"Should return valid value", ^{
                [[configuration.ASATokenEndReportingInterval should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveDoubleNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.ASATokenEndReportingInterval = value;
            });
        });
        context(@"startupUpdateInterval", ^{
            NSString *const key = @"startup.update.interval";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(doubleNumberForKey:error:) withArguments:key, kw_any()];
                [configuration startupUpdateInterval];
            });
            it(@"Should return valid value", ^{
                [[configuration.startupUpdateInterval should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveDoubleNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.startupUpdateInterval = value;
            });
        });
    });

    context(@"Long long values", ^{
        NSNumber *const value = @23;
        beforeEach(^{
            [storage stub:@selector(longLongNumberForKey:error:) andReturn:value];
        });

        context(@"retryPolicyMaxIntervalSeconds", ^{
            NSString *const key = @"retry_policy.max_interval_seconds";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(longLongNumberForKey:error:) withArguments:key, kw_any()];
                [configuration retryPolicyMaxIntervalSeconds];
            });
            it(@"Should return valid value", ^{
                [[configuration.retryPolicyMaxIntervalSeconds should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveLongLongNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.retryPolicyMaxIntervalSeconds = value;
            });
        });
        context(@"retryPolicyExponentialMultiplier", ^{
            NSString *const key = @"retry_policy.exponential_multiplier";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(longLongNumberForKey:error:) withArguments:key, kw_any()];
                [configuration retryPolicyExponentialMultiplier];
            });
            it(@"Should return valid value", ^{
                [[configuration.retryPolicyExponentialMultiplier should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveLongLongNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.retryPolicyExponentialMultiplier = value;
            });
        });
        context(@"locationRecordsCountToForceFlush", ^{
            NSString *const key = @"location.collecting.flush.records.count";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(longLongNumberForKey:error:) withArguments:key, kw_any()];
                [configuration locationRecordsCountToForceFlush];
            });
            it(@"Should return valid value", ^{
                [[configuration.locationRecordsCountToForceFlush should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveLongLongNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.locationRecordsCountToForceFlush = value;
            });
        });
        context(@"locationMaxRecordsCountInBatch", ^{
            NSString *const key = @"location.collecting.batch.records.count";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(longLongNumberForKey:error:) withArguments:key, kw_any()];
                [configuration locationMaxRecordsCountInBatch];
            });
            it(@"Should return valid value", ^{
                [[configuration.locationMaxRecordsCountInBatch should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveLongLongNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.locationMaxRecordsCountInBatch = value;
            });
        });
        context(@"locationMaxRecordsToStoreLocally", ^{
            NSString *const key = @"location.collecting.store.records.max";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(longLongNumberForKey:error:) withArguments:key, kw_any()];
                [configuration locationMaxRecordsToStoreLocally];
            });
            it(@"Should return valid value", ^{
                [[configuration.locationMaxRecordsToStoreLocally should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveLongLongNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.locationMaxRecordsToStoreLocally = value;
            });
        });
        context(@"permissionsCollectingForceSendInterval", ^{
            NSString *const key = @"permissions.collecting.force_send_interval";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(longLongNumberForKey:error:) withArguments:key, kw_any()];
                [configuration permissionsCollectingForceSendInterval];
            });
            it(@"Should return valid value", ^{
                [[configuration.permissionsCollectingForceSendInterval should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveLongLongNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.permissionsCollectingForceSendInterval = value;
            });
        });
        context(@"applePrivacyResendPeriod", ^{
            NSString *const key = @"apple_tracking.collecting.resend_period";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(longLongNumberForKey:error:) withArguments:key, kw_any()];
                [configuration applePrivacyResendPeriod];
            });
            it(@"Should return valid value", ^{
                [[configuration.applePrivacyResendPeriod should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveLongLongNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.applePrivacyResendPeriod = value;
            });
        });
    });

    context(@"Bool values", ^{
        NSNumber *const value = @YES;
        beforeEach(^{
            [storage stub:@selector(boolNumberForKey:error:) andReturn:value];
        });
        context(@"extensionsCollectingEnabled", ^{
            NSString *const key = @"extensions.reporting.enabled";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(boolNumberForKey:error:) withArguments:key, kw_any()];
                [configuration extensionsCollectingEnabled];
            });
            it(@"Should return valid value", ^{
                [[theValue(configuration.extensionsCollectingEnabled) should] beYes];
            });
            it(@"Should return NO by default", ^{
                [storage stub:@selector(boolNumberForKey:error:) andReturn:nil];
                [[theValue(configuration.extensionsCollectingEnabled) should] beNo];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveBoolNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.extensionsCollectingEnabled = value.boolValue;
            });
        });
        context(@"locationCollectingEnabled", ^{
            NSString *const key = @"location.collecting.enabled";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(boolNumberForKey:error:) withArguments:key, kw_any()];
                [configuration locationCollectingEnabled];
            });
            it(@"Should return valid value", ^{
                [[theValue(configuration.locationCollectingEnabled) should] beYes];
            });
            it(@"Should return NO by default", ^{
                [storage stub:@selector(boolNumberForKey:error:) andReturn:nil];
                [[theValue(configuration.locationCollectingEnabled) should] beNo];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveBoolNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.locationCollectingEnabled = value.boolValue;
            });
        });
        context(@"locationVisitsCollectingEnabled", ^{
            NSString *const key = @"location.collecting.visits.enabled";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(boolNumberForKey:error:) withArguments:key, kw_any()];
                [configuration locationVisitsCollectingEnabled];
            });
            it(@"Should return valid value", ^{
                [[theValue(configuration.locationVisitsCollectingEnabled) should] beYes];
            });
            it(@"Should return NO by default", ^{
                [storage stub:@selector(boolNumberForKey:error:) andReturn:nil];
                [[theValue(configuration.locationVisitsCollectingEnabled) should] beNo];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveBoolNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.locationVisitsCollectingEnabled = value.boolValue;
            });
        });
        context(@"locationPausesLocationUpdatesAutomatically", ^{
            NSString *const key = @"location.collecting.update.automatic_pause";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(boolNumberForKey:error:) withArguments:key, kw_any()];
                [configuration locationPausesLocationUpdatesAutomatically];
            });
            it(@"Should return valid value", ^{
                [[configuration.locationPausesLocationUpdatesAutomatically should] beYes];
            });
            it(@"Should return nil if there is no value", ^{
                [storage stub:@selector(boolNumberForKey:error:) andReturn:nil];
                [[configuration.locationPausesLocationUpdatesAutomatically should] beNil];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveBoolNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.locationPausesLocationUpdatesAutomatically = value;
            });
        });
        context(@"permissionsCollectingEnabled", ^{
            NSString *const key = @"permissions.collecting.enabled";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(boolNumberForKey:error:) withArguments:key, kw_any()];
                [configuration permissionsCollectingEnabled];
            });
            it(@"Should return valid value", ^{
                [[theValue(configuration.permissionsCollectingEnabled) should] beYes];
            });
            it(@"Should return NO by default", ^{
                [storage stub:@selector(boolNumberForKey:error:) andReturn:nil];
                [[theValue(configuration.permissionsCollectingEnabled) should] beNo];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveBoolNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.permissionsCollectingEnabled = value.boolValue;
            });
        });
    });

    context(@"String values", ^{
        NSString *const value = @"VALUE";
        beforeEach(^{
            [storage stub:@selector(stringForKey:error:) andReturn:value];
        });

        context(@"initialCountry", ^{
            NSString *const key = @"initial.country";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(stringForKey:error:) withArguments:key, kw_any()];
                [configuration initialCountry];
            });
            it(@"Should return valid value", ^{
                [[configuration.initialCountry should] equal:value];
            });
            it(@"Should save valid value first time", ^{
                [storage stub:@selector(stringForKey:error:) andReturn:nil];
                [[storage should] receive:@selector(saveString:forKey:error:) withArguments:value, key, kw_any()];
                configuration.initialCountry = value;
            });
            it(@"Should not update existing value", ^{
                [[storage shouldNot] receive:@selector(saveString:forKey:error:)];
                configuration.initialCountry = value;
            });
        });
        context(@"permissionsString", ^{
            NSString *const key = @"startup.permissions";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(stringForKey:error:) withArguments:key, kw_any()];
                [configuration permissionsString];
            });
            it(@"Should return valid value", ^{
                [[configuration.permissionsString should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveString:forKey:error:) withArguments:value, key, kw_any()];
                configuration.permissionsString = value;
            });
        });
        
        context(@"redirectHost", ^{
            NSString *const key = @"redirect.host";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(stringForKey:error:) withArguments:key, kw_any()];
                [configuration redirectHost];
            });
            it(@"Should return valid value", ^{
                [[configuration.redirectHost should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveString:forKey:error:) withArguments:value, key, kw_any()];
                configuration.redirectHost = value;
            });
        });
    });

    context(@"Array values", ^{
        NSArray *const value = @[ @"foo", @"bar" ];
        NSArray *const nonStringsValue = @[ @1, @2 ];
        beforeEach(^{
            [storage stub:@selector(jsonArrayForKey:error:) andReturn:value];
        });

        context(@"permissionsCollectingList", ^{
            NSString *const key = @"permissions.collecting.list";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(jsonArrayForKey:error:) withArguments:key, kw_any()];
                [configuration permissionsCollectingList];
            });
            it(@"Should return valid value", ^{
                [[configuration.permissionsCollectingList should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveJSONArray:forKey:error:) withArguments:value, key, kw_any()];
                configuration.permissionsCollectingList = value;
            });
            context(@"Non-strings", ^{
                beforeEach(^{
                    [storage stub:@selector(jsonArrayForKey:error:) andReturn:nonStringsValue];
                });
                it(@"Should return nil", ^{
                    [[configuration.permissionsCollectingList should] beNil];
                });
            });
        });

        context(@"startupHosts", ^{
            NSString *const key = @"startup.hosts";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(jsonArrayForKey:error:) withArguments:key, kw_any()];
                [configuration startupHosts];
            });
            it(@"Should return valid value", ^{
                [[configuration.startupHosts should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveJSONArray:forKey:error:) withArguments:value, key, kw_any()];
                configuration.startupHosts = value;
            });
            context(@"Non-strings", ^{
                beforeEach(^{
                    [storage stub:@selector(jsonArrayForKey:error:) andReturn:nonStringsValue];
                });
                it(@"Should return nil", ^{
                    [[configuration.startupHosts should] beNil];
                });
            });
        });
        context(@"reportHosts", ^{
            NSString *const key = @"report.hosts";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(jsonArrayForKey:error:) withArguments:key, kw_any()];
                [configuration reportHosts];
            });
            it(@"Should return valid value", ^{
                [[configuration.reportHosts should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveJSONArray:forKey:error:) withArguments:value, key, kw_any()];
                configuration.reportHosts = value;
            });
            context(@"Non-strings", ^{
                beforeEach(^{
                    [storage stub:@selector(jsonArrayForKey:error:) andReturn:nonStringsValue];
                });
                it(@"Should return nil", ^{
                    [[configuration.reportHosts should] beNil];
                });
            });
        });
        
        context(@"locationHosts", ^{
            NSString *const key = @"location.collecting.hosts";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(jsonArrayForKey:error:) withArguments:key, kw_any()];
                [configuration locationHosts];
            });
            it(@"Should return valid value", ^{
                [[configuration.locationHosts should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveJSONArray:forKey:error:) withArguments:value, key, kw_any()];
                configuration.locationHosts = value;
            });
            context(@"Non-strings", ^{
                beforeEach(^{
                    [storage stub:@selector(jsonArrayForKey:error:) andReturn:nonStringsValue];
                });
                it(@"Should return nil", ^{
                    [[configuration.locationHosts should] beNil];
                });
            });
        });
        
        context(@"appleTrackingHosts", ^{
            NSString *key = @"apple_tracking.collecting.hosts";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(jsonArrayForKey:error:) withArguments:key, kw_any()];
                [configuration appleTrackingHosts];
            });
            it(@"Should return valid value", ^{
                [[configuration.appleTrackingHosts should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveJSONArray:forKey:error:) withArguments:value, key, kw_any()];
                configuration.appleTrackingHosts = value;
            });
            context(@"Non-strings", ^{
                beforeEach(^{
                    [storage stub:@selector(jsonArrayForKey:error:) andReturn:nonStringsValue];
                });
                it(@"Should return nil", ^{
                    [[configuration.appleTrackingHosts should] beNil];
                });
            });
        });
        
        context(@"Attribution deeplink conditions", ^{
            NSArray *deserializedValue = @[ [[AMAPair alloc] initWithKey:@"some key"
                                                                   value:@"some value"] ];
            NSArray *serializedValue = @[ @{} ];
            NSString *const key = @"attribution.deeplink.conditions";
            beforeEach(^{
                [storage stub:@selector(jsonArrayForKey:error:) andReturn:serializedValue];
                [AMAAttributionSerializer stub:@selector(fromJsonArray:) andReturn:deserializedValue];
                [AMAAttributionSerializer stub:@selector(toJsonArray:) andReturn:serializedValue];
            });
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(jsonArrayForKey:error:) withArguments:key, kw_any()];
                [configuration attributionDeeplinkConditions];
            });
            it(@"Serializer should be called with right arguments", ^{
                [[AMAAttributionSerializer should] receive:@selector(fromJsonArray:) withArguments:serializedValue];
                [configuration attributionDeeplinkConditions];
            });
            it(@"Should return valid value", ^{
                [[configuration.attributionDeeplinkConditions should] equal:deserializedValue];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveJSONArray:forKey:error:) withArguments:serializedValue, key, kw_any()];
                configuration.attributionDeeplinkConditions = deserializedValue;
            });
            it(@"Serializer should receive right arguments", ^{
                [[AMAAttributionSerializer should] receive:@selector(toJsonArray:) withArguments:deserializedValue];
                configuration.attributionDeeplinkConditions = deserializedValue;
            });
            context(@"Non-dictionaries", ^{
                NSArray *nonDictionaryArray = @[ @"aaa", @"bbb" ];
                beforeEach(^{
                    [storage stub:@selector(jsonArrayForKey:error:) andReturn:nonDictionaryArray];
                });
                it(@"Serializer should receive nil", ^{
                    [[AMAAttributionSerializer should] receive:@selector(fromJsonArray:) withArguments:nil];
                    [configuration attributionDeeplinkConditions];
                });
            });
        });
    });
    
    context(@"Number Array values", ^{
        NSArray *const value = @[ @1, @2 ];
        NSArray *const nonNumberValue = @[ @"foo", @"bar" ];
        beforeEach(^{
            [storage stub:@selector(jsonArrayForKey:error:) andReturn:value];
        });
        
        context(@"applePrivacyRetryPeriod", ^{
            NSString *key = @"apple_tracking.collecting.retry_period";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(jsonArrayForKey:error:) withArguments:key, kw_any()];
                [configuration applePrivacyRetryPeriod];
            });
            it(@"Should return valid value", ^{
                [[configuration.applePrivacyRetryPeriod should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveJSONArray:forKey:error:) withArguments:value, key, kw_any()];
                configuration.applePrivacyRetryPeriod = value;
            });
            context(@"Non-strings", ^{
                beforeEach(^{
                    [storage stub:@selector(jsonArrayForKey:error:) andReturn:nonNumberValue];
                });
                it(@"Should return nil", ^{
                    [[configuration.applePrivacyRetryPeriod should] beNil];
                });
            });
        });
    });

    context(@"Dictionary values", ^{
        context(@"Extended parameters", ^{
            NSString *const key = @"extended.parameters";
            NSDictionary *const value = @{
                @"get_ad" : @"https://tst.mobile.appmetrica.net",
                @"report_ad" : @"https://startup.tst.mobile.appmetrica.io",
            };

            beforeEach(^{
                [storage stub:@selector(jsonDictionaryForKey:error:) andReturn:value];
            });

            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(jsonDictionaryForKey:error:) withArguments:key, kw_any()];
                [configuration extendedParameters];
            });
            it(@"Should return valid value", ^{
                [[configuration.extendedParameters should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveJSONDictionary:forKey:error:) withArguments:value, key, kw_any()];
                configuration.extendedParameters = value;
            });

            __auto_type testWithStructure = ^(NSDictionary *structure) {
                beforeEach(^{
                    [storage stub:@selector(jsonDictionaryForKey:error:) andReturn:structure];
                });
                it(@"Should return nil", ^{
                    [[configuration.extendedParameters should] beNil];
                });
            };

            context(@"Should validate root invalid structure", ^{
                testWithStructure(@{ @123: @"B" });
            });

            context(@"Should validate value invalid structure", ^{
                testWithStructure(@{
                    @"get_ad" : @[@"https://tst.mobile.appmetrica.net"],
                    @"report_ad" : @[@"https://startup.tst.mobile.appmetrica.io"],
                });
            });
            
            context(@"Should validate invalid value", ^{
                testWithStructure(@{
                    @"get_ad" : @999,
                });
            });
        });
    });
});

SPEC_END
