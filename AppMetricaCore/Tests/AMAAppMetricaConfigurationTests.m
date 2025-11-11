
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAAppMetricaConfiguration+JSONSerializable.h"
#import "AMAAppMetricaConfiguration+Internal.h"
#import "AMAAppMetricaPreloadInfo+JSONSerializable.h"
#import "AMAMetricaInMemoryConfiguration.h"

static NSString *const kAMAValidAppVersion = @"v1.32";
static NSString *const kAMAValidAppBuildNumber = @"3417";

SPEC_BEGIN(AMAAppMetricaConfigurationTests)

describe(@"AMAAppMetricaConfiguration", ^{
    
    NSString *apiKey = @"550e8400-e29b-41d4-a716-446655440000";
    
    context(@"Defaults", ^{
        context(@"Bool", ^{
            it(@"Should have enabled revenue auto tracking", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
                [[theValue(config.revenueAutoTrackingEnabled) should] beYes];
            });
            it(@"Should have enabled app open tracking", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
                [[theValue(config.appOpenTrackingEnabled) should] beYes];
            });
            it(@"Should have disabled handleFirstActivationAsUpdate", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
                [[theValue(config.handleFirstActivationAsUpdate) should] beNo];
            });
            it(@"Should have disabled handleActivationAsSessionStart", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
                [[theValue(config.handleActivationAsSessionStart) should] beNo];
            });
            it(@"Should have enabled sessionsAutoTracking", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
                [[theValue(config.sessionsAutoTracking) should] beYes];
            });
            it(@"Should have disabled logs", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
                [[theValue(config.areLogsEnabled) should] beNo];
            });
            it(@"Should have enabled locationTracking", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
                [[theValue(config.locationTracking) should] beYes];
            });
            it(@"Should have disabled allowsBackgroundLocationUpdates", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
                [[theValue(config.allowsBackgroundLocationUpdates) should] beNo];
            });
            it(@"Should have disabled accurateLocationTracking", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
                [[theValue(config.accurateLocationTracking) should] beNo];
            });
            it(@"Should have enabled advertisingIdentifierTracking", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
                [[theValue(config.advertisingIdentifierTrackingEnabled) should] beYes];
            });
        });
        context(@"Number", ^{
            it(@"Should have default sessionTimeout", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
                [[theValue(config.sessionTimeout) should] equal:theValue(10)];
            });
            it(@"Should have default dispatchPeriod", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
                [[theValue(config.dispatchPeriod) should] equal:theValue(90)];
            });
            it(@"Should have default maxReportsCount", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
                [[theValue(config.maxReportsCount) should] equal:theValue(7)];
            });
            it(@"Should have default maxReportsInDatabaseCount", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
                [[theValue(config.maxReportsInDatabaseCount) should] equal:theValue(1000)];
            });
        });
    });
    
    context(@"Handling Invalid Values", ^{
        __block AMATestAssertionHandler *handler = nil;
        beforeEach(^{
            handler = [AMATestAssertionHandler new];
            [handler beginAssertIgnoring];
        });
        afterEach(^{
            [handler endAssertIgnoring];
        });
        
        it(@"Should validate APIKey", ^{
            [AMAIdentifierValidator stub:@selector(isValidUUIDKey:) andReturn:theValue(YES)];
            
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:@"-------"];
            
            [[config shouldNot] beNil];
        });
        
        it(@"Should not be created with non number string as APIKey", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:@"Not a number"];
            
            [[config should] beNil];
        });
        
        it(@"Should not be created with empty string as APIKey", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:@""];
            
            [[config should] beNil];
        });
        it(@"Should not be created with nil string as APIKey", ^{
            NSString *nilString = nil;
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:nilString];
            
            [[config should] beNil];
        });
        
        it(@"Should ignore attempt to set empty appVersion", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
            config.appVersion = @"";
            
            [[config.appVersion should] beNil];
        });
        
        it(@"Should ignore attempt to set nil as appVersion", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
            config.appVersion = kAMAValidAppVersion;
            config.appVersion = nil;
            
            [[config.appVersion should] equal:kAMAValidAppVersion];
        });
        
        it(@"Should set valid appBuildNumber", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
            config.appBuildNumber = kAMAValidAppBuildNumber;
            
            [[config.appBuildNumber should] equal:kAMAValidAppBuildNumber];
        });
        
        it(@"Should ignore attempt to set empty appBuildNumber", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
            
            config.appBuildNumber = @"";
            [[config.appBuildNumber should] beNil];
        });
        
        it(@"Should ignore attempt to set nil as appBuildNumber", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
            
            config.appBuildNumber = kAMAValidAppBuildNumber;
            config.appBuildNumber = nil;
            
            [[config.appBuildNumber should] equal:kAMAValidAppBuildNumber];
        });
        
        it(@"Should ignore attempt to set negative appBuildNumber", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
            config.appBuildNumber = @"-154";
            
            [[config.appBuildNumber should] beNil];
        });
        
        it(@"Should ignore attempt to set non integer appBuildNumber", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
            config.appBuildNumber = @"10.5";
            
            [[config.appBuildNumber should] beNil];
        });
        
        it(@"Should ignore attempt to set non integer string with an integer in the beginning appBuildNumber", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
            config.appBuildNumber = @"10 some other stuff";
            
            [[config.appBuildNumber should] beNil];
        });
        
        it(@"Should ignore attempt to set non number appBuildNumber", ^{
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
            config.appBuildNumber = @"Not a number";
            
            [[config.appBuildNumber should] beNil];
        });
        
        context(@"Location", ^{
            it(@"Should return location tracking true if locationTrackingState is nil", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
                
                [[theValue(config.locationTracking) should] beYes];
            });
            
            it(@"Should return location tracking state if non nil", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
                [config setLocationTracking:NO];
                
                [[theValue(config.locationTracking) should] beNo];
            });
        });
        
        context(@"Data sending", ^{
            it(@"Should return data sending true if locationTrackingState is nil", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
                
                [[theValue(config.dataSendingEnabled) should] beYes];
            });
            
            it(@"Should return location tracking state if non nil", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
                [config setDataSendingEnabled:NO];
                
                [[theValue(config.dataSendingEnabled) should] beNo];
            });
        });
    });
    
    context(@"JSON", ^{
        NSDictionary *const preloadInfoJson = @{
            kAMATrackingID: @"trackingID",
            kAMAAdditionalInfo: @{
                @"key1": @"info1",
                @"key2": @"info2"
            }
        };
        NSString *const appVersion = @"1.0.1";
        NSString *const userProfileID = @"user123";
        NSString *const appBuildNumber = @"12345";
        NSArray *const customHosts = @[@"https://appmetri.ca"];
        NSDictionary *const appEnvironment = @{ @"foo" : @"bar" };
        NSUInteger const maxReportsInDatabaseCount = 4999;
        NSUInteger const dispatchPeriod = 110;
        NSUInteger const sessionTimeout = 7;
        NSUInteger const maxReportsCount = 99;
        CLLocation *const customLocation = [[CLLocation alloc] initWithLatitude:37.7749 longitude:-122.4194];
        
        context(@"JSON Serialization", ^{
            __block AMAAppMetricaConfiguration *config = nil;
            __block AMAAppMetricaPreloadInfo *preloadInfo = nil;
            beforeEach(^{
                config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
                preloadInfo = [[AMAAppMetricaPreloadInfo alloc] initWithJSON:preloadInfoJson];
            });
            it(@"should correctly serialize to JSON", ^{
                config.handleFirstActivationAsUpdate = YES;
                config.handleActivationAsSessionStart = NO;
                config.sessionsAutoTracking = YES;
                config.dataSendingEnabled = NO;
                config.maxReportsInDatabaseCount = maxReportsInDatabaseCount;
                config.locationTracking = YES;
                config.allowsBackgroundLocationUpdates = YES;
                config.accurateLocationTracking = YES;
                config.dispatchPeriod = dispatchPeriod;
                config.sessionTimeout = sessionTimeout;
                config.maxReportsCount = maxReportsCount;
                config.logsEnabled = YES;
                config.appOpenTrackingEnabled = YES;
                config.revenueAutoTrackingEnabled = YES;
                config.appVersion = appVersion;
                config.userProfileID = userProfileID;
                config.appBuildNumber = appBuildNumber;
                config.customHosts = customHosts;
                config.appEnvironment = appEnvironment;
                config.preloadInfo = preloadInfo;
                config.customLocation = customLocation;
                
                NSDictionary *json = [config JSON];
                
                [[json[kAMAAPIKey] should] equal:apiKey];
                [[json[kAMAHandleFirstActivationAsUpdate] should] equal:@(YES)];
                [[json[kAMAHandleActivationAsSessionStart] should] equal:@(NO)];
                [[json[kAMASessionsAutoTracking] should] equal:@(YES)];
                [[json[kAMADataSendingEnabled] should] equal:@(NO)];
                [[json[kAMAMaximumReportsInDatabaseCount] should] equal:@(maxReportsInDatabaseCount)];
                [[json[kAMAMaxReportsCount] should] equal:@(maxReportsCount)];
                [[json[kAMALocationTracking] should] equal:@(YES)];
                [[json[kAMAAllowsBackgroundLocationUpdates] should] equal:@(YES)];
                [[json[kAMAAccurateLocationTracking] should] equal:@(YES)];
                [[json[kAMAAppOpenTrackingEnabled] should] equal:@(YES)];
                [[json[kAMARevenueAutoTrackingEnabled] should] equal:@(YES)];
                [[json[kAMADispatchPeriod] should] equal:@(dispatchPeriod)];
                [[json[kAMASessionTimeout] should] equal:@(sessionTimeout)];
                [[json[kAMALogsEnabled] should] equal:@(YES)];
                [[json[kAMAAppVersion] should] equal:appVersion];
                [[json[kAMAUserProfileID] should] equal:userProfileID];
                [[json[kAMAAppBuildNumber] should] equal:appBuildNumber];
                [[json[kAMACustomHosts] should] equal:customHosts];
                [[json[kAMACustomLocation][kAMALatitude] should] equal:@(customLocation.coordinate.latitude)];
                [[json[kAMACustomLocation][kAMALongitude] should] equal:@(customLocation.coordinate.longitude)];
                [[json[kAMAAppEnvironment] should] equal:appEnvironment];
                [[json[kAMAPreloadInfo] should] equal:preloadInfoJson];
            });
            it(@"should handle empty fields in JSON serialization", ^{
                NSDictionary *json = [config JSON];
                [[json[kAMAAppVersion] should] equal:[NSNull null]];
                [[json[kAMAPreloadInfo] should] equal:[NSNull null]];
                [[json[kAMAUserProfileID] should] equal:[NSNull null]];
                [[json[kAMAAppBuildNumber] should] equal:[NSNull null]];
                [[json[kAMACustomHosts] should] equal:[NSNull null]];
                [[json[kAMAAppEnvironment] should] equal:[NSNull null]];
                [[json[kAMADataSendingEnabled] should] beNil];
                [[json[kAMALocationTracking] should] beNil];
            });
        });
        
        context(@"JSON Deserialization", ^{
            it(@"should correctly deserialize from valid JSON", ^{
                NSDictionary *json = @{
                    kAMAAPIKey: apiKey,
                    kAMAHandleFirstActivationAsUpdate: @(YES),
                    kAMAHandleActivationAsSessionStart: @(NO),
                    kAMASessionsAutoTracking: @(YES),
                    kAMADataSendingEnabled: @(NO),
                    kAMAMaximumReportsInDatabaseCount: @(maxReportsInDatabaseCount),
                    kAMALocationTracking: @(YES),
                    kAMAAllowsBackgroundLocationUpdates: @(YES),
                    kAMAAccurateLocationTracking: @(YES),
                    kAMADispatchPeriod: @(dispatchPeriod),
                    kAMASessionTimeout: @(sessionTimeout),
                    kAMAMaxReportsCount: @(maxReportsCount),
                    kAMALogsEnabled: @(YES),
                    kAMAAppOpenTrackingEnabled: @(YES),
                    kAMARevenueAutoTrackingEnabled: @(YES),
                    kAMAAppVersion: appVersion,
                    kAMAUserProfileID: userProfileID,
                    kAMAAppBuildNumber: appBuildNumber,
                    kAMACustomHosts: customHosts,
                    kAMAAppEnvironment: appEnvironment,
                    kAMACustomLocation: @{
                        kAMALatitude: @(customLocation.coordinate.latitude),
                        kAMALongitude: @(customLocation.coordinate.longitude)
                    },
                    kAMAPreloadInfo: preloadInfoJson,
                };
                
                AMAAppMetricaConfiguration *deserializedConfig = [[AMAAppMetricaConfiguration alloc] initWithJSON:json];
                
                [[deserializedConfig.APIKey should] equal:apiKey];
                [[theValue(deserializedConfig.handleFirstActivationAsUpdate) should] equal:@(YES)];
                [[theValue(deserializedConfig.handleActivationAsSessionStart) should] equal:@(NO)];
                [[theValue(deserializedConfig.sessionsAutoTracking) should] equal:@(YES)];
                [[theValue(deserializedConfig.dataSendingEnabled) should] equal:@(NO)];
                [[theValue(deserializedConfig.maxReportsInDatabaseCount) should] equal:@(maxReportsInDatabaseCount)];
                [[theValue(deserializedConfig.maxReportsCount) should] equal:@(maxReportsCount)];
                [[theValue(deserializedConfig.locationTracking) should] equal:@(YES)];
                [[theValue(deserializedConfig.allowsBackgroundLocationUpdates) should] equal:@(YES)];
                [[theValue(deserializedConfig.appOpenTrackingEnabled) should] equal:@(YES)];
                [[theValue(deserializedConfig.revenueAutoTrackingEnabled) should] equal:@(YES)];
                [[theValue(deserializedConfig.accurateLocationTracking) should] equal:@(YES)];
                [[theValue(deserializedConfig.dispatchPeriod) should] equal:@(dispatchPeriod)];
                [[theValue(deserializedConfig.sessionTimeout) should] equal:@(sessionTimeout)];
                [[theValue(deserializedConfig.areLogsEnabled) should] equal:@(YES)];
                [[deserializedConfig.appVersion should] equal:appVersion];
                [[deserializedConfig.userProfileID should] equal:userProfileID];
                [[deserializedConfig.appBuildNumber should] equal:appBuildNumber];
                [[deserializedConfig.customHosts should] equal:customHosts];
                [[theValue(deserializedConfig.customLocation.coordinate.latitude) should] equal:@(customLocation.coordinate.latitude)];
                [[theValue(deserializedConfig.customLocation.coordinate.longitude) should] equal:@(customLocation.coordinate.longitude)];
                [[deserializedConfig.appEnvironment should] equal:appEnvironment];
                [[[deserializedConfig.preloadInfo JSON] should] equal:preloadInfoJson];
            });
            
            it(@"should return nil when deserializing invalid JSON", ^{
                NSDictionary *invalidJson = @{ @"invalid.key": @"invalid value" };
                AMAAppMetricaConfiguration *deserializedConfig = [[AMAAppMetricaConfiguration alloc] initWithJSON:invalidJson];
                [[deserializedConfig should] beNil];
            });
            
            it(@"should handle missing optional fields with default values in JSON deserialization", ^{
                NSDictionary *json = @{
                    kAMAAPIKey: apiKey
                };
                
                AMAAppMetricaConfiguration *deserializedConfig = [[AMAAppMetricaConfiguration alloc] initWithJSON:json];
                
                [[deserializedConfig.APIKey should] equal:apiKey];
                [[deserializedConfig.appEnvironment should] beNil];
                
                [[theValue(deserializedConfig.revenueAutoTrackingEnabled) should] equal:theValue(kAMADefaultRevenueAutoTrackingEnabled)];
                [[theValue(deserializedConfig.appOpenTrackingEnabled) should] equal:theValue(kAMADefaultAppOpenTrackingEnabled)];
                [[theValue(deserializedConfig.handleFirstActivationAsUpdate) should] beNo];
                [[theValue(deserializedConfig.handleActivationAsSessionStart) should] beNo];
                [[theValue(deserializedConfig.sessionsAutoTracking) should] beYes];
                [[theValue(deserializedConfig.allowsBackgroundLocationUpdates) should] beNo];
                [[theValue(deserializedConfig.areLogsEnabled) should] beNo];
                [[theValue(deserializedConfig.accurateLocationTracking) should] beNo];
                [[theValue(deserializedConfig.locationTracking) should] beYes];
                [[theValue(deserializedConfig.dataSendingEnabled) should] beYes];
                
                [[theValue(deserializedConfig.sessionTimeout) should] equal:theValue(kAMASessionValidIntervalInSecondsDefault)];
                [[theValue(deserializedConfig.dispatchPeriod) should] equal:theValue(kAMADefaultDispatchPeriodSeconds)];
                [[theValue(deserializedConfig.maxReportsCount) should] equal:theValue(kAMAAutomaticReporterDefaultMaxReportsCount)];
                [[theValue(deserializedConfig.maxReportsInDatabaseCount) should] equal:theValue(kAMAMaxReportsInDatabaseCount)];
            });
        });
    });
});

SPEC_END
