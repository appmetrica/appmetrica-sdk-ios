
#import <Kiwi/Kiwi.h>
#import "AMARevenueAttributionModelConfiguration.h"
#import "AMACurrencyMapping.h"
#import "AMABoundMapping.h"
#import "AMAEventFilter.h"

SPEC_BEGIN(AMARevenueAttributionModelConfigurationTests)

describe(@"AMARevenueAttributionModelConfiguration", ^{

    AMARevenueAttributionModelConfiguration *__block config;

    context(@"Init with JSON", ^{
        AMACurrencyMapping *__block currencyMapping = nil;
        NSDictionary *currencyJSON = @{ @"aaa" : @"bbb" };
        beforeEach(^{
            currencyMapping = [AMACurrencyMapping nullMock];
            AMACurrencyMapping *allocedCurrencyMapping = [AMACurrencyMapping nullMock];
            [AMACurrencyMapping stub:@selector(alloc) andReturn:allocedCurrencyMapping];
            [allocedCurrencyMapping stub:@selector(initWithJSON:) andReturn:currencyMapping withArguments:currencyJSON];
        });
        it(@"Should return nil for nil JSON", ^{
            [[[[AMARevenueAttributionModelConfiguration alloc] initWithJSON:nil] should] beNil];
        });
        it(@"Empty arrays", ^{
            NSDictionary *json = @{
                @"mappings" : @[],
                @"events" : @[],
                @"currency.mapping" : currencyJSON
            };
            config = [[AMARevenueAttributionModelConfiguration alloc] initWithJSON:json];
            [[config.currencyMapping should] equal:currencyMapping];
            [[config.events should] equal:@[]];
            [[config.boundMappings should] equal:@[]];
        });
        it(@"Filled arrays", ^{
            NSDictionary *firstBoundMappingJSON = @{ @"ccc" : @"ddd" };
            NSDictionary *secondBoundMappingJSON = @{ @"eee" : @"fff" };
            NSDictionary *firstEventJSON = @{ @"ggg" : @"hhh" };
            NSDictionary *secondEventJSON = @{ @"iii" : @"jjj" };
            AMABoundMapping *firstBoundMapping = [AMABoundMapping nullMock];
            AMABoundMapping *secondBoundMapping = [AMABoundMapping nullMock];
            AMABoundMapping *allocedBoundMapping = [AMABoundMapping nullMock];
            [AMABoundMapping stub:@selector(alloc) andReturn:allocedBoundMapping];
            [allocedBoundMapping stub:@selector(initWithJSON:) andReturn:firstBoundMapping withArguments:firstBoundMappingJSON];
            [allocedBoundMapping stub:@selector(initWithJSON:) andReturn:secondBoundMapping withArguments:secondBoundMappingJSON];
            AMAEventFilter *firstEventFilter = [AMAEventFilter nullMock];
            AMAEventFilter *secondEventFilter = [AMAEventFilter nullMock];
            AMAEventFilter *allocedEventFilter = [AMAEventFilter nullMock];
            [AMAEventFilter stub:@selector(alloc) andReturn:allocedEventFilter];
            [allocedEventFilter stub:@selector(initWithJSON:) andReturn:firstEventFilter withArguments:firstEventJSON];
            [allocedEventFilter stub:@selector(initWithJSON:) andReturn:secondEventFilter withArguments:secondEventJSON];

            NSDictionary *json = @{
                @"mappings" : @[ firstBoundMappingJSON, secondBoundMappingJSON ],
                @"events" : @[ firstEventJSON, secondEventJSON ],
                @"currency.mapping" : currencyJSON
            };
            config = [[AMARevenueAttributionModelConfiguration alloc] initWithJSON:json];
            [[config.currencyMapping should] equal:currencyMapping];
            [[config.events should] equal:@[ firstEventFilter, secondEventFilter ]];
            [[config.boundMappings should] equal:@[ firstBoundMapping, secondBoundMapping ]];
        });
    });
    context(@"JSON", ^{
        AMACurrencyMapping *__block currencyMapping = nil;
        NSDictionary *currencyJSON = @{ @"aaa" : @"bbb" };
        beforeEach(^{
            currencyMapping = [AMACurrencyMapping nullMock];
            [currencyMapping stub:@selector(JSON) andReturn:currencyJSON];
        });
        it(@"Empty arrays", ^{
            config = [[AMARevenueAttributionModelConfiguration alloc] initWithBoundMappings:@[]
                                                                                     events:@[]
                                                                            currencyMapping:currencyMapping];
            NSDictionary *expectedJSON = @{
                @"mappings" : @[],
                @"events" : @[],
                @"currency.mapping" : currencyJSON
            };
            [[[config JSON] should] equal:expectedJSON];
        });
        it(@"Filled arrays", ^{
            NSDictionary *firstBoundMappingJSON = @{ @"ccc" : @"ddd" };
            NSDictionary *secondBoundMappingJSON = @{ @"eee" : @"fff" };
            NSDictionary *firstEventJSON = @{ @"ggg" : @"hhh" };
            NSDictionary *secondEventJSON = @{ @"iii" : @"jjj" };
            AMABoundMapping *firstBoundMapping = [AMABoundMapping nullMock];
            AMABoundMapping *secondBoundMapping = [AMABoundMapping nullMock];
            [firstBoundMapping stub:@selector(JSON) andReturn:firstBoundMappingJSON];
            [secondBoundMapping stub:@selector(JSON) andReturn:secondBoundMappingJSON];
            AMAEventFilter *firstEventFilter = [AMAEventFilter nullMock];
            AMAEventFilter *secondEventFilter = [AMAEventFilter nullMock];
            [firstEventFilter stub:@selector(JSON) andReturn:firstEventJSON];
            [secondEventFilter stub:@selector(JSON) andReturn:secondEventJSON];
            config = [[AMARevenueAttributionModelConfiguration alloc] initWithBoundMappings:@[ firstBoundMapping, secondBoundMapping ]
                                                                                     events:@[ firstEventFilter, secondEventFilter ]
                                                                            currencyMapping:currencyMapping];
            NSDictionary *expectedJSON = @{
                @"mappings" : @[ firstBoundMappingJSON, secondBoundMappingJSON ],
                @"events" : @[ firstEventJSON, secondEventJSON ],
                @"currency.mapping" : currencyJSON
            };
            [[[config JSON] should] equal:expectedJSON];
        });
    });
    
    it(@"Should conform to AMAJSONSerializable", ^{
        __auto_type *configuration = [[AMARevenueAttributionModelConfiguration alloc] init];
        [[configuration should] conformToProtocol:@protocol(AMAJSONSerializable)];
    });
});

SPEC_END
