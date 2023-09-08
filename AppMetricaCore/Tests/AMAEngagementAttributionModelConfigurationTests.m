
#import <Kiwi/Kiwi.h>
#import "AMAEngagementAttributionModelConfiguration.h"
#import "AMAEventFilter.h"
#import "AMABoundMapping.h"

SPEC_BEGIN(AMAEngagementAttributionModelConfigurationTests)

describe(@"AMAEngagementAttributionModelConfiguration", ^{

    context(@"Init with JSON", ^{
        it(@"Should be nil for nil json", ^{
            [[[[AMAEngagementAttributionModelConfiguration alloc] initWithJSON:nil] should] beNil];
        });
        it(@"Should return valid object for filled json", ^{
            NSDictionary *firstFilterJSON = @{ @"aaa" : @"bbb" };
            NSDictionary *secondFilterJSON = @{ @"ccc" : @"ddd" };
            NSDictionary *firstMappingJSON = @{ @"eee" : @"fff" };
            NSDictionary *secondMappingJSON = @{ @"ggg" : @"iii" };
            AMAEventFilter *firstFilter = [AMAEventFilter nullMock];
            AMAEventFilter *secondFilter = [AMAEventFilter nullMock];
            AMABoundMapping *firstMapping = [AMABoundMapping nullMock];
            AMABoundMapping *secondMapping = [AMABoundMapping nullMock];
            AMAEventFilter *allocedFilter = [AMAEventFilter nullMock];
            AMABoundMapping *allocedMapping = [AMABoundMapping nullMock];
            [AMAEventFilter stub:@selector(alloc) andReturn:allocedFilter];
            [AMABoundMapping stub:@selector(alloc) andReturn:allocedMapping];
            [allocedFilter stub:@selector(initWithJSON:) andReturn:firstFilter withArguments:firstFilterJSON];
            [allocedFilter stub:@selector(initWithJSON:) andReturn:secondFilter withArguments:secondFilterJSON];
            [allocedMapping stub:@selector(initWithJSON:) andReturn:firstMapping withArguments:firstMappingJSON];
            [allocedMapping stub:@selector(initWithJSON:) andReturn:secondMapping withArguments:secondMappingJSON];

            NSDictionary *json = @{
                @"event.filters" : @[ firstFilterJSON, secondFilterJSON ],
                @"mappings" : @[ firstMappingJSON, secondMappingJSON ]
            };
            AMAEngagementAttributionModelConfiguration *config = [[AMAEngagementAttributionModelConfiguration alloc] initWithJSON:json];
            [[config.eventFilters should] equal:@[ firstFilter, secondFilter ]];
            [[config.boundMappings should] equal:@[ firstMapping, secondMapping ]];
        });
    });
    context(@"JSON", ^{
        it(@"Filled object", ^{
            AMAEventFilter *firstFilter = [AMAEventFilter nullMock];
            AMAEventFilter *secondFilter = [AMAEventFilter nullMock];
            NSDictionary *firstFilterJSON = @{ @"aaa" : @"bbb" };
            NSDictionary *secondFilterJSON = @{ @"ccc" : @"ddd" };
            [firstFilter stub:@selector(JSON) andReturn:firstFilterJSON];
            [secondFilter stub:@selector(JSON) andReturn:secondFilterJSON];
            AMABoundMapping *firstMapping = [AMABoundMapping nullMock];
            AMABoundMapping *secondMapping = [AMABoundMapping nullMock];
            NSDictionary *firstMappingJSON = @{ @"eee" : @"fff" };
            NSDictionary *secondMappingJSON = @{ @"ggg" : @"iii" };
            [firstMapping stub:@selector(JSON) andReturn:firstMappingJSON];
            [secondMapping stub:@selector(JSON) andReturn:secondMappingJSON];
            AMAEngagementAttributionModelConfiguration *config = [[AMAEngagementAttributionModelConfiguration alloc]
                initWithEventFilters:@[ firstFilter, secondFilter ]
                       boundMappings:@[ firstMapping, secondMapping ]
            ];
            NSDictionary *expectedJSON = @{
                @"event.filters" : @[ firstFilterJSON, secondFilterJSON ],
                @"mappings" : @[ firstMappingJSON, secondMappingJSON ]
            };
            [[[config JSON] should] equal:expectedJSON];
        });
        it(@"Empty object", ^{
            AMAEngagementAttributionModelConfiguration *config = [[AMAEngagementAttributionModelConfiguration alloc]
                initWithEventFilters:@[]
                       boundMappings:@[]
            ];
            NSDictionary *expectedJSON = @{
                @"event.filters" : @[],
                @"mappings" : @[]
            };
            [[[config JSON] should] equal:expectedJSON];
        });
    });
});

SPEC_END
