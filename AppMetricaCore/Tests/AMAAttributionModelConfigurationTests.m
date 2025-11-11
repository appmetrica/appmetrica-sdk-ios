
#import <Foundation/Foundation.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAAttributionModelConfiguration.h"
#import "AMAConversionAttributionModelConfiguration.h"
#import "AMAEngagementAttributionModelConfiguration.h"
#import "AMARevenueAttributionModelConfiguration.h"

SPEC_BEGIN(AMAAttributionModelConfigurationTests)

describe(@"AMAAttributionModelConfiguration", ^{

    context(@"Max saved revenue ids", ^{
        it(@"Should return valid value", ^{
            AMAAttributionModelConfiguration *config =
                [[AMAAttributionModelConfiguration alloc] initWithType:AMAAttributionModelTypeConversion
                                                    maxSavedRevenueIDs:@17
                                                stopSendingTimeSeconds:@2
                                                            conversion:nil
                                                               revenue:nil
                                                            engagement:nil];
            [[config.maxSavedRevenueIDs should] equal:@17];
        });
        it(@"Should return default value", ^{
            AMAAttributionModelConfiguration *config =
                [[AMAAttributionModelConfiguration alloc] initWithType:AMAAttributionModelTypeConversion
                                                    maxSavedRevenueIDs:nil
                                                stopSendingTimeSeconds:@2
                                                            conversion:nil
                                                               revenue:nil
                                                            engagement:nil];
            [[config.maxSavedRevenueIDs should] equal:@50];
        });
    });
    context(@"Init with JSON", ^{
        AMAConversionAttributionModelConfiguration *__block conversionModel = nil;
        AMAEngagementAttributionModelConfiguration *__block engagementModel = nil;
        AMARevenueAttributionModelConfiguration *__block revenueModel = nil;
        AMAConversionAttributionModelConfiguration *__block allocedConversionModel = nil;
        AMAEngagementAttributionModelConfiguration *__block allocedEngagementModel = nil;
        AMARevenueAttributionModelConfiguration *__block allocedRevenueModel = nil;
        beforeEach(^{
            conversionModel = [AMAConversionAttributionModelConfiguration nullMock];
            engagementModel = [AMAEngagementAttributionModelConfiguration nullMock];
            revenueModel = [AMARevenueAttributionModelConfiguration nullMock];
            allocedConversionModel = [AMAConversionAttributionModelConfiguration nullMock];
            allocedEngagementModel = [AMAEngagementAttributionModelConfiguration nullMock];
            allocedRevenueModel = [AMARevenueAttributionModelConfiguration nullMock];
            [AMAConversionAttributionModelConfiguration stub:@selector(alloc) andReturn:allocedConversionModel];
            [AMAEngagementAttributionModelConfiguration stub:@selector(alloc) andReturn:allocedEngagementModel];
            [AMARevenueAttributionModelConfiguration stub:@selector(alloc) andReturn:allocedRevenueModel];
            [allocedConversionModel stub:@selector(initWithJSON:) andReturn:conversionModel];
            [allocedEngagementModel stub:@selector(initWithJSON:) andReturn:engagementModel];
            [allocedRevenueModel stub:@selector(initWithJSON:) andReturn:revenueModel];
        });
        it(@"Should return nil for nil json", ^{
            [[[[AMAAttributionModelConfiguration alloc] initWithJSON:nil] should] beNil];
        });
        it(@"Should return for empty JSON", ^{
            [[allocedConversionModel should] receive:@selector(initWithJSON:) withArguments:nil];
            [[allocedEngagementModel should] receive:@selector(initWithJSON:) withArguments:nil];
            [[allocedRevenueModel should] receive:@selector(initWithJSON:) withArguments:nil];
            AMAAttributionModelConfiguration *result = [[AMAAttributionModelConfiguration alloc] initWithJSON:@{}];
            [[theValue(result.type) should] equal:theValue(AMAAttributionModelTypeUnknown)];
            [[result.stopSendingTimeSeconds should] beNil];
            [[result.maxSavedRevenueIDs should] equal:@50];
            [[result.conversion should] equal:conversionModel];
            [[result.engagement should] equal:engagementModel];
            [[result.revenue should] equal:revenueModel];
        });
        it(@"Should return for filled JSON", ^{
            NSDictionary *conversionJSON = @{ @"aaa" : @"bbb" };
            NSDictionary *engagementJSON = @{ @"ccc" : @"ddd" };
            NSDictionary *revenueJSON = @{ @"eee" : @"fff" };
            NSDictionary *json = @{
                @"stop.sending.time.seconds" : @555666,
                @"max.saved.revenue.ids" : @43,
                @"model.type" : @1,
                @"conversion" : conversionJSON,
                @"engagement" : engagementJSON,
                @"revenue": revenueJSON
            };
            [[allocedConversionModel should] receive:@selector(initWithJSON:) withArguments:conversionJSON];
            [[allocedEngagementModel should] receive:@selector(initWithJSON:) withArguments:engagementJSON];
            [[allocedRevenueModel should] receive:@selector(initWithJSON:) withArguments:revenueJSON];
            AMAAttributionModelConfiguration *result = [[AMAAttributionModelConfiguration alloc] initWithJSON:json];
            [[theValue(result.type) should] equal:theValue(AMAAttributionModelTypeConversion)];
            [[result.stopSendingTimeSeconds should] equal:@555666];
            [[result.maxSavedRevenueIDs should] equal:@43];
            [[result.conversion should] equal:conversionModel];
            [[result.engagement should] equal:engagementModel];
            [[result.revenue should] equal:revenueModel];
        });
        it(@"Should convert engagement type", ^{
            NSDictionary *json = @{ @"model.type" : @2 };
            AMAAttributionModelConfiguration *result = [[AMAAttributionModelConfiguration alloc] initWithJSON:json];
            [[theValue(result.type) should] equal:theValue(AMAAttributionModelTypeRevenue)];
        });
        it(@"Should convert revenue type", ^{
            NSDictionary *json = @{ @"model.type" : @3 };
            AMAAttributionModelConfiguration *result = [[AMAAttributionModelConfiguration alloc] initWithJSON:json];
            [[theValue(result.type) should] equal:theValue(AMAAttributionModelTypeEngagement)];
        });
        it(@"Should convert unknown type", ^{
            NSDictionary *json = @{ @"model.type" : @0 };
            AMAAttributionModelConfiguration *result = [[AMAAttributionModelConfiguration alloc] initWithJSON:json];
            [[theValue(result.type) should] equal:theValue(AMAAttributionModelTypeUnknown)];
        });
    });
    context(@"JSON", ^{
        it(@"Should return valid json for filled object", ^{
            AMAConversionAttributionModelConfiguration *conversionModel = [AMAConversionAttributionModelConfiguration nullMock];
            AMAEngagementAttributionModelConfiguration *engagementModel = [AMAEngagementAttributionModelConfiguration nullMock];
            AMARevenueAttributionModelConfiguration *revenueModel = [AMARevenueAttributionModelConfiguration nullMock];
            NSDictionary *conversionJSON = @{ @"aaa" : @"bbb" };
            NSDictionary *engagementJSON = @{ @"ccc" : @"ddd" };
            NSDictionary *revenueJSON = @{ @"eee" : @"fff" };
            [conversionModel stub:@selector(JSON) andReturn:conversionJSON];
            [engagementModel stub:@selector(JSON) andReturn:engagementJSON];
            [revenueModel stub:@selector(JSON) andReturn:revenueJSON];
            AMAAttributionModelConfiguration *config = [[AMAAttributionModelConfiguration alloc] initWithType:AMAAttributionModelTypeConversion
                                                                                           maxSavedRevenueIDs:@17
                                                                                       stopSendingTimeSeconds:@45
                                                                                                   conversion:conversionModel
                                                                                                      revenue:revenueModel
                                                                                                   engagement:engagementModel];
            NSDictionary *expectedJSON = @{
                @"stop.sending.time.seconds" : @45,
                @"max.saved.revenue.ids" : @17,
                @"model.type" : @1,
                @"conversion" : conversionJSON,
                @"engagement" : engagementJSON,
                @"revenue": revenueJSON
            };
            [[[config JSON] should] equal:expectedJSON];
        });
        it(@"Should convert revenue type", ^{
            AMAAttributionModelConfiguration *config = [[AMAAttributionModelConfiguration alloc] initWithType:AMAAttributionModelTypeRevenue
                                                                                           maxSavedRevenueIDs:@17
                                                                                       stopSendingTimeSeconds:@45
                                                                                                   conversion:nil
                                                                                                      revenue:nil
                                                                                                   engagement:nil];
            [[[config JSON][@"model.type"] should] equal:@2];
        });
        it(@"Should convert engagement type", ^{
            AMAAttributionModelConfiguration *config = [[AMAAttributionModelConfiguration alloc] initWithType:AMAAttributionModelTypeEngagement
                                                                                           maxSavedRevenueIDs:@17
                                                                                       stopSendingTimeSeconds:@45
                                                                                                   conversion:nil
                                                                                                      revenue:nil
                                                                                                   engagement:nil];
            [[[config JSON][@"model.type"] should] equal:@3];
        });
        it(@"Should convert unknown type", ^{
            AMAAttributionModelConfiguration *config = [[AMAAttributionModelConfiguration alloc] initWithType:AMAAttributionModelTypeUnknown
                                                                                           maxSavedRevenueIDs:@17
                                                                                       stopSendingTimeSeconds:@45
                                                                                                   conversion:nil
                                                                                                      revenue:nil
                                                                                                   engagement:nil];
            [[[config JSON][@"model.type"] should] equal:@0];
        });
        it(@"Should return valid json for object with nils", ^{
            AMAAttributionModelConfiguration *config = [[AMAAttributionModelConfiguration alloc] initWithType:AMAAttributionModelTypeConversion
                                                                                           maxSavedRevenueIDs:nil
                                                                                       stopSendingTimeSeconds:@45
                                                                                                   conversion:nil
                                                                                                      revenue:nil
                                                                                                   engagement:nil];
            NSDictionary *expectedJSON = @{
                @"stop.sending.time.seconds" : @45,
                @"max.saved.revenue.ids" : @50,
                @"model.type" : @1
            };
            [[[config JSON] should] equal:expectedJSON];
        });
    });
    
    it(@"Should conform to AMAJSONSerializable", ^{
        __auto_type *configuration = [[AMAAttributionModelConfiguration alloc] init];
        [[configuration should] conformToProtocol:@protocol(AMAJSONSerializable)];
    });
});

SPEC_END
