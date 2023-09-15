
#import <Foundation/Foundation.h>
#import <Kiwi/Kiwi.h>
#import "AMAConversionAttributionModelConfiguration.h"
#import "AMAAttributionMapping.h"

SPEC_BEGIN(AMAConversionAttributionModelConfigurationTests)

describe(@"AMAConversionAttributionModelConfiguration", ^{

    context(@"Init with JSON", ^{
        it(@"Should return nil for nil json", ^{
            [[[[AMAConversionAttributionModelConfiguration alloc] initWithJSON:nil] should] beNil];
        });
        it(@"Should return valid for filled JSON", ^{
            AMAAttributionMapping *allocedMapping = [AMAAttributionMapping nullMock];
            [AMAAttributionMapping stub:@selector(alloc) andReturn:allocedMapping];
            NSDictionary *firstJSON = @{ @"aaa" : @ "bbb" };
            NSDictionary *secondJSON = @{ @"ccc" : @ "ddd" };
            AMAAttributionMapping *firstMapping = [AMAAttributionMapping nullMock];
            AMAAttributionMapping *secondMapping = [AMAAttributionMapping nullMock];
            [allocedMapping stub:@selector(initWithJSON:) andReturn:firstMapping withArguments:firstJSON];
            [allocedMapping stub:@selector(initWithJSON:) andReturn:secondMapping withArguments:secondJSON];
            NSDictionary *json = @{
                @"mappings" : @[ firstJSON, secondJSON ]
            };
            AMAConversionAttributionModelConfiguration *config = [[AMAConversionAttributionModelConfiguration alloc] initWithJSON:json];
            [[config.mappings should] equal:@[ firstMapping, secondMapping ]];
        });
    });
    context(@"JSON", ^{
        it(@"Empty mappings", ^{
            AMAConversionAttributionModelConfiguration *config = [[AMAConversionAttributionModelConfiguration alloc]
                initWithMappings:@[]];
            NSDictionary *expectedJSON = @{
                @"mappings" : @[]
            };
            [[[config JSON] should] equal:expectedJSON];

        });
        it(@"Filled mappings", ^{
            NSDictionary *firstJSON = @{ @"aaa" : @ "bbb" };
            NSDictionary *secondJSON = @{ @"ccc" : @ "ddd" };
            AMAAttributionMapping *firstMapping = [AMAAttributionMapping nullMock];
            AMAAttributionMapping *secondMapping = [AMAAttributionMapping nullMock];
            [firstMapping stub:@selector(JSON) andReturn:firstJSON];
            [secondMapping stub:@selector(JSON) andReturn:secondJSON];
            AMAConversionAttributionModelConfiguration *config = [[AMAConversionAttributionModelConfiguration alloc]
                initWithMappings:@[ firstMapping, secondMapping]];
            NSDictionary *expectedJSON = @{
                @"mappings" : @[ firstJSON, secondJSON ]
            };
            [[[config JSON] should] equal:expectedJSON];
        });
    });
    
    it(@"Should conform to AMAJSONSerializable", ^{
        __auto_type *configuration = [[AMAConversionAttributionModelConfiguration alloc] init];
        [[configuration should] conformToProtocol:@protocol(AMAJSONSerializable)];
    });
});

SPEC_END
