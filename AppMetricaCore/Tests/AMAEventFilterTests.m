
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAEventFilter.h"
#import "AMAClientEventCondition.h"
#import "AMARevenueEventCondition.h"
#import "AMAECommerceEventCondition.h"

SPEC_BEGIN(AMAEventFilterTests)

describe(@"AMAEventFilter", ^{

    context(@"Init with JSON", ^{
        it(@"Should return valid object for minimum json", ^{
            NSDictionary *json = @{ @"event.type" : @4 };
            AMAEventFilter *filter = [[AMAEventFilter alloc] initWithJSON:json];
            [[theValue(filter.type) should] equal:theValue(AMAEventTypeClient)];
            [[filter.clientEventCondition should] beNil];
            [[filter.revenueEventCondition should] beNil];
            [[filter.eCommerceEventCondition should] beNil];
        });
        it(@"Revenue type", ^{
            NSDictionary *json = @{ @"event.type" : @21 };
            AMAEventFilter *filter = [[AMAEventFilter alloc] initWithJSON:json];
            [[theValue(filter.type) should] equal:theValue(AMAEventTypeRevenue)];
        });
        it(@"E-commerce type", ^{
            NSDictionary *json = @{ @"event.type" : @35 };
            AMAEventFilter *filter = [[AMAEventFilter alloc] initWithJSON:json];
            [[theValue(filter.type) should] equal:theValue(AMAEventTypeECommerce)];
        });
        it(@"Filled json", ^{
            NSDictionary *clientJSON = @{ @"aaa" : @"bbb" };
            NSDictionary *revenueJSON = @{ @"ccc" : @"ddd" };
            NSDictionary *eCommerceJSON = @{ @"eee" : @"fff" };
            AMAClientEventCondition *clientEventCondition = [AMAClientEventCondition nullMock];
            AMARevenueEventCondition *revenueEventCondition = [AMARevenueEventCondition nullMock];
            AMAECommerceEventCondition *ecomEventCondition = [AMAECommerceEventCondition nullMock];
            AMAClientEventCondition *allocedClientEventCondition = [AMAClientEventCondition nullMock];
            AMARevenueEventCondition *allocedRevenueEventCondition = [AMARevenueEventCondition nullMock];
            AMAECommerceEventCondition *allocedEcomEventCondition = [AMAECommerceEventCondition nullMock];
            [AMAClientEventCondition stub:@selector(alloc) andReturn:allocedClientEventCondition];
            [AMARevenueEventCondition stub:@selector(alloc) andReturn:allocedRevenueEventCondition];
            [AMAECommerceEventCondition stub:@selector(alloc) andReturn:allocedEcomEventCondition];
            [allocedClientEventCondition stub:@selector(initWithJSON:) andReturn:clientEventCondition withArguments:clientJSON];
            [allocedRevenueEventCondition stub:@selector(initWithJSON:) andReturn:revenueEventCondition withArguments:revenueJSON];
            [allocedEcomEventCondition stub:@selector(initWithJSON:) andReturn:ecomEventCondition withArguments:eCommerceJSON];
            NSDictionary *json = @{
                @"event.type" : @4,
                @"client.condition" : clientJSON,
                @"revenue.condition" : revenueJSON,
                @"ecommerce.condition" : eCommerceJSON,
            };
            AMAEventFilter *filter = [[AMAEventFilter alloc] initWithJSON:json];
            [[theValue(filter.type) should] equal:theValue(AMAEventTypeClient)];
            [[filter.clientEventCondition should] equal:clientEventCondition];
            [[filter.revenueEventCondition should] equal:revenueEventCondition];
            [[filter.eCommerceEventCondition should] equal:ecomEventCondition];
        });
    });
    context(@"JSON", ^{
        it(@"Empty object", ^{
            AMAEventFilter *filter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeClient
                                                          clientEventCondition:nil
                                                       eCommerceEventCondition:nil
                                                         revenueEventCondition:nil];
            NSDictionary *expectedJSON = @{
                @"event.type" : @4
            };
            [[[filter JSON] should] equal:expectedJSON];
        });
        it(@"Filled object", ^{
            NSDictionary *clientJSON = @{ @"aaa" : @"bbb" };
            NSDictionary *revenueJSON = @{ @"ccc" : @"ddd" };
            NSDictionary *eCommerceJSON = @{ @"eee" : @"fff" };
            AMAClientEventCondition *clientEventCondition = [AMAClientEventCondition nullMock];
            AMARevenueEventCondition *revenueEventCondition = [AMARevenueEventCondition nullMock];
            AMAECommerceEventCondition *ecomEventCondition = [AMAECommerceEventCondition nullMock];
            [clientEventCondition stub:@selector(JSON) andReturn:clientJSON];
            [revenueEventCondition stub:@selector(JSON) andReturn:revenueJSON];
            [ecomEventCondition stub:@selector(JSON) andReturn:eCommerceJSON];
            AMAEventFilter *filter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeClient
                                                          clientEventCondition:clientEventCondition
                                                       eCommerceEventCondition:ecomEventCondition
                                                         revenueEventCondition:revenueEventCondition];
            NSDictionary *expectedJSON = @{
                @"event.type" : @4,
                @"client.condition" : clientJSON,
                @"revenue.condition" : revenueJSON,
                @"ecommerce.condition" : eCommerceJSON,
            };
            [[[filter JSON] should] equal:expectedJSON];
        });
    });
    
    it(@"Should conform to AMAJSONSerializable", ^{
        AMAEventFilter *filter = [[AMAEventFilter alloc] init];
        [[filter should] conformToProtocol:@protocol(AMAJSONSerializable)];
    });
});

SPEC_END
