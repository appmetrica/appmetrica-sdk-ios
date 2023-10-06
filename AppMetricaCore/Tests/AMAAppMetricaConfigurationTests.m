
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAAppMetricaConfiguration.h"

static NSString *const kAMAValidAppVersion = @"v1.32";
static NSString *const kAMAValidAppBuildNumber = @"3417";

SPEC_BEGIN(AMAAppMetricaConfigurationTests)

describe(@"AMAAppMetricaConfiguration", ^{
    
    NSString *apiKey = @"550e8400-e29b-41d4-a716-446655440000";
    
    context(@"Defaults", ^{
        context(@"Bool", ^{
            it(@"Should have enabled revenue auto tracking", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
                [[theValue(config.revenueAutoTrackingEnabled) should] beYes];
            });
            it(@"Should have enabled app open tracking", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
                [[theValue(config.appOpenTrackingEnabled) should] beYes];
            });
            it(@"Should have disabled handleFirstActivationAsUpdate", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
                [[theValue(config.handleFirstActivationAsUpdate) should] beNo];
            });
            it(@"Should have disabled handleActivationAsSessionStart", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
                [[theValue(config.handleActivationAsSessionStart) should] beNo];
            });
            it(@"Should have enabled sessionsAutoTracking", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
                [[theValue(config.sessionsAutoTracking) should] beYes];
            });
            it(@"Should have disabled logs", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
                [[theValue(config.logs) should] beNo];
            });
            it(@"Should have disabled allowsBackgroundLocationUpdates", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
                [[theValue(config.allowsBackgroundLocationUpdates) should] beNo];
            });
            it(@"Should have disabled allowsBackgroundLocationUpdates", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
                [[theValue(config.allowsBackgroundLocationUpdates) should] beNo];
            });
            it(@"Should have disabled accurateLocationTracking", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
                [[theValue(config.accurateLocationTracking) should] beNo];
            });
        });
        context(@"Number", ^{
            it(@"Should have default sessionTimeout", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
                [[theValue(config.sessionTimeout) should] equal:theValue(10)];
            });
            it(@"Should have default dispatchPeriod", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
                [[theValue(config.dispatchPeriod) should] equal:theValue(90)];
            });
            it(@"Should have default maxReportsCount", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
                [[theValue(config.maxReportsCount) should] equal:theValue(7)];
            });
            it(@"Should have default maxReportsInDatabaseCount", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
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
            
            AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:@"-------"];
            
            [[config shouldNot] beNil];
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
        
        context(@"Location", ^{
            it(@"Should return location tracking true if locationTrackingState is nil", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
                
                [[theValue(config.locationTracking) should] beYes];
            });
            
            it(@"Should return location tracking state if non nil", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
                [config setLocationTracking:NO];
                
                [[theValue(config.locationTracking) should] beNo];
            });
        });
        
        context(@"Data sending", ^{
            it(@"Should return data sending true if locationTrackingState is nil", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
                
                [[theValue(config.dataSendingEnabled) should] beYes];
            });
            
            it(@"Should return location tracking state if non nil", ^{
                AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
                [config setDataSendingEnabled:NO];
                
                [[theValue(config.dataSendingEnabled) should] beNo];
            });
        });
    });
});

SPEC_END
