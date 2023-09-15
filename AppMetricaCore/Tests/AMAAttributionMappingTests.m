
#import <Foundation/Foundation.h>
#import <Kiwi/Kiwi.h>
#import "AMAAttributionMapping.h"
#import "AMAEventFilter.h"

SPEC_BEGIN(AMAAttributionMappingTests)

describe(@"AMAAttributionMapping", ^{

    context(@"Init with JSON", ^{
        it(@"Should return nil for nil json", ^{
            [[[[AMAAttributionMapping alloc] initWithJSON:nil] should] beNil];
        });
        it(@"Should return for empty json", ^{
            AMAAttributionMapping *result = [[AMAAttributionMapping alloc] initWithJSON:@{}];
            [[theValue(result.requiredCount) should] equal:theValue(0)];
            [[theValue(result.conversionValueDiff) should] equal:theValue(0)];
            [[result.eventFilters should] equal:@[]];
        });
        it(@"Should return for filled json", ^{
            NSDictionary *firstFilter = @{ @"aaa" : @"bbb" };
            NSDictionary *secondFilter = @{ @"ccc" : @"ddd" };
            AMAEventFilter *firstEventFilter = [AMAEventFilter nullMock];
            AMAEventFilter *secondEventFilter = [AMAEventFilter nullMock];
            AMAEventFilter *allocedFilter = [AMAEventFilter nullMock];
            [AMAEventFilter stub:@selector(alloc) andReturn:allocedFilter];
            [allocedFilter stub:@selector(initWithJSON:) andReturn:firstEventFilter withArguments:firstFilter];
            [allocedFilter stub:@selector(initWithJSON:) andReturn:secondEventFilter withArguments:secondFilter];
            NSDictionary *json = @{
                @"required.count" : @5,
                @"conversion.value.diff" : @8,
                @"event.filters" : @[ firstFilter, secondFilter ]
            };
            AMAAttributionMapping *result = [[AMAAttributionMapping alloc] initWithJSON:json];
            [[theValue(result.requiredCount) should] equal:theValue(5)];
            [[theValue(result.conversionValueDiff) should] equal:theValue(8)];
            [[result.eventFilters should] equal:@[ firstEventFilter, secondEventFilter ]];
        });
    });
    context(@"JSON", ^{
        it(@"Should create valid json", ^{
            AMAEventFilter *firstEventFilter = [AMAEventFilter nullMock];
            AMAEventFilter *secondEventFilter = [AMAEventFilter nullMock];
            NSDictionary *firstFilter = @{ @"aaa" : @"bbb" };
            NSDictionary *secondFilter = @{ @"ccc" : @"ddd" };
            [firstEventFilter stub:@selector(JSON) andReturn:firstFilter];
            [secondEventFilter stub:@selector(JSON) andReturn:secondFilter];
            AMAAttributionMapping *mapping = [[AMAAttributionMapping alloc] initWithEventFilters:@[ firstEventFilter, secondEventFilter ]
                                                                                   requiredCount:5
                                                                             conversionValueDiff:8];
            NSDictionary *expectedJSON = @{
                @"required.count" : @5,
                @"conversion.value.diff" : @8,
                @"event.filters" : @[ firstFilter, secondFilter ]
            };
            [[[mapping JSON] should] equal:expectedJSON];
        });
        it(@"Should create valid json for empty filters", ^{
            AMAAttributionMapping *mapping = [[AMAAttributionMapping alloc] initWithEventFilters:@[]
                                                                                   requiredCount:5
                                                                             conversionValueDiff:8];
            NSDictionary *expectedJSON = @{
                @"required.count" : @5,
                @"conversion.value.diff" : @8,
                @"event.filters" : @[]
            };
            [[[mapping JSON] should] equal:expectedJSON];
        });
    });
    it(@"Should conform to AMAJSONSerializable", ^{
        AMAAttributionMapping *mapping = [[AMAAttributionMapping alloc] init];
        [[mapping should] conformToProtocol:@protocol(AMAJSONSerializable)];
    });
});

SPEC_END
