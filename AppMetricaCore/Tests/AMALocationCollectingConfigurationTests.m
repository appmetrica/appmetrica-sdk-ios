
#import <Kiwi/Kiwi.h>
#import <CoreLocation/CoreLocation.h>
#import "AMALocationCollectingConfiguration.h"
#import "AMAMetricaConfigurationTestUtilities.h"

SPEC_BEGIN(AMALocationCollectingConfigurationTests)

describe(@"AMALocationCollectingConfiguration", ^{

    double const EPSILON = DBL_EPSILON * 1000;
    AMAMetricaConfiguration *__block metricaCofiguration = nil;
    AMALocationCollectingConfiguration *__block configuration = nil;

    beforeEach(^{
        [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];
        metricaCofiguration = [AMAMetricaConfiguration sharedInstance];
        configuration = [[AMALocationCollectingConfiguration alloc] initWithMetricaConfiguration:metricaCofiguration];
    });

    context(@"Collecting enabled", ^{
        it(@"Should retrun NO if disabled", ^{
            [metricaCofiguration.startup stub:@selector(locationCollectingEnabled) andReturn:theValue(NO)];
            [[theValue(configuration.collectingEnabled) should] beNo];
        });
        it(@"Should retrun YES if enabled", ^{
            [metricaCofiguration.startup stub:@selector(locationCollectingEnabled) andReturn:theValue(YES)];
            [[theValue(configuration.collectingEnabled) should] beYes];
        });
    });
    
    context(@"Visits collecting enabled", ^{
        it(@"Should retrun NO if disabled", ^{
            [metricaCofiguration.startup stub:@selector(locationVisitsCollectingEnabled) andReturn:theValue(NO)];
            [[theValue(configuration.visitsCollectingEnabled) should] beNo];
        });
        it(@"Should retrun YES if enabled", ^{
            [metricaCofiguration.startup stub:@selector(locationVisitsCollectingEnabled) andReturn:theValue(YES)];
            [[theValue(configuration.visitsCollectingEnabled) should] beYes];
        });
    });
         
    it(@"Should return hosts", ^{
        NSArray *hosts = @[ @"foo", @"bar" ];
        [metricaCofiguration.startup stub:@selector(locationHosts) andReturn:hosts];
        [[configuration.hosts should] equal:hosts];
    });

    context(@"minUpdateInterval", ^{
        it(@"Should return existing value", ^{
            [metricaCofiguration.startup stub:@selector(locationMinUpdateInterval) andReturn:@23];
            [[theValue(configuration.minUpdateInterval) should] equal:23.0 withDelta:EPSILON];
        });
        it(@"Should return default value", ^{
            [[theValue(configuration.minUpdateInterval) should] equal:5.0 withDelta:EPSILON];
        });
    });

    context(@"minUpdateDistance", ^{
        it(@"Should return existing value", ^{
            [metricaCofiguration.startup stub:@selector(locationMinUpdateDistance) andReturn:@108];
            [[theValue(configuration.minUpdateDistance) should] equal:108.0 withDelta:EPSILON];
        });
        it(@"Should return default value", ^{
            [[theValue(configuration.minUpdateDistance) should] equal:10.0 withDelta:EPSILON];
        });
    });

    context(@"recordsCountToForceFlush", ^{
        it(@"Should return existing value", ^{
            [metricaCofiguration.startup stub:@selector(locationRecordsCountToForceFlush) andReturn:@42];
            [[theValue(configuration.recordsCountToForceFlush) should] equal:theValue(42)];
        });
        it(@"Should return default value", ^{
            [[theValue(configuration.recordsCountToForceFlush) should] equal:theValue(10)];
        });
    });

    context(@"maxRecordsCountInBatch", ^{
        it(@"Should return existing value", ^{
            [metricaCofiguration.startup stub:@selector(locationMaxRecordsCountInBatch) andReturn:@15];
            [[theValue(configuration.maxRecordsCountInBatch) should] equal:theValue(15)];
        });
        it(@"Should return default value", ^{
            [[theValue(configuration.maxRecordsCountInBatch) should] equal:theValue(100)];
        });
    });

    context(@"maxAgeToForceFlush", ^{
        it(@"Should return existing value", ^{
            [metricaCofiguration.startup stub:@selector(locationMaxAgeToForceFlush) andReturn:@16];
            [[theValue(configuration.maxAgeToForceFlush) should] equal:16.0 withDelta:EPSILON];
        });
        it(@"Should return default value", ^{
            [[theValue(configuration.maxAgeToForceFlush) should] equal:60.0 withDelta:EPSILON];
        });
    });

    context(@"maxRecordsToStoreLocally", ^{
        it(@"Should return existing value", ^{
            [metricaCofiguration.startup stub:@selector(locationMaxRecordsToStoreLocally) andReturn:@8];
            [[theValue(configuration.maxRecordsToStoreLocally) should] equal:theValue(8)];
        });
        it(@"Should return default value", ^{
            [[theValue(configuration.maxRecordsToStoreLocally) should] equal:theValue(5000)];
        });
    });
         
    context(@"defaultDesiredAccuracy", ^{
        it(@"Should return existing value", ^{
            [metricaCofiguration.startup stub:@selector(locationDefaultDesiredAccuracy) andReturn:@3000];
            [[theValue(configuration.defaultDesiredAccuracy) should] equal:theValue(3000)];
        });
        it(@"Should return default value", ^{
            [[theValue(configuration.defaultDesiredAccuracy) should] equal:theValue(kCLLocationAccuracyHundredMeters)];
        });
    });
    
    context(@"defaultDistanceFilter", ^{
        it(@"Should return existing value", ^{
            [metricaCofiguration.startup stub:@selector(locationDefaultDistanceFilter) andReturn:@125];
            [[theValue(configuration.defaultDistanceFilter) should] equal:theValue(125)];
        });
        it(@"Should return default value", ^{
            [[theValue(configuration.defaultDistanceFilter) should] equal:theValue(350)];
        });
    });
         
    context(@"accurateDesiredAccuracy", ^{
        it(@"Should return existing value", ^{
            [metricaCofiguration.startup stub:@selector(locationAccurateDesiredAccuracy) andReturn:@100];
            [[theValue(configuration.accurateDesiredAccuracy) should] equal:theValue(100)];
        });
        it(@"Should return default value", ^{
            [[theValue(configuration.accurateDesiredAccuracy) should]
                equal:theValue(kCLLocationAccuracyNearestTenMeters)];
        });
    });
         
    context(@"accurateDistanceFilter", ^{
        it(@"Should return existing value", ^{
            [metricaCofiguration.startup stub:@selector(locationAccurateDistanceFilter) andReturn:@50];
            [[theValue(configuration.accurateDistanceFilter) should] equal:theValue(50)];
        });
        it(@"Should return default value", ^{
            [[theValue(configuration.accurateDistanceFilter) should] equal:theValue(10)];
        });
    });
         
    context(@"pausesLocationUpdatesAutomatically", ^{
        it(@"Should return existing value", ^{
            [metricaCofiguration.startup stub:@selector(locationPausesLocationUpdatesAutomatically)
                                    andReturn:@NO];
            [[theValue(configuration.pausesLocationUpdatesAutomatically) should] beNo];
        });
        it(@"Should return default value", ^{
            [[theValue(configuration.pausesLocationUpdatesAutomatically) should] beYes];
        });
    });
});

SPEC_END

