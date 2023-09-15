
#import <Kiwi/Kiwi.h>
#import "AMAEventCountByKeyHelper.h"
#import "AMAConversionAttributionModel.h"
#import "AMAConversionAttributionModelConfiguration.h"
#import "AMAAttributionMapping.h"
#import "AMAEventFilter.h"
#import "AMAClientEventCondition.h"
#import "AMARevenueEventCondition.h"
#import "AMAECommerceEventCondition.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAMetricaConfiguration.h"
#import "AMALightRevenueEvent.h"
#import "AMALightECommerceEvent.h"

SPEC_BEGIN(AMAConversionAttributionModelTests)

describe(@"AMAConversionAttributionModel", ^{

    AMAEventCountByKeyHelper *__block eventCountByKeyHelper = nil;
    AMAConversionAttributionModel *__block conversion = nil;
    AMAMetricaPersistentConfiguration *__block persistentConfiguration = nil;
    beforeEach(^{
        eventCountByKeyHelper = [AMAEventCountByKeyHelper nullMock];
        persistentConfiguration = [AMAMetricaPersistentConfiguration nullMock];
        AMAMetricaConfiguration *configuration = [AMAMetricaConfiguration nullMock];
        [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:configuration];
        [configuration stub:@selector(persistent) andReturn:persistentConfiguration];
    });
    context(@"Client event", ^{
        beforeEach(^{
            AMAEventFilter *firstClientEventFilter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeClient
                                                                          clientEventCondition:[[AMAClientEventCondition alloc] initWithName:@"client name #1"]
                                                                       eCommerceEventCondition:nil
                                                                         revenueEventCondition:nil];
            AMAAttributionMapping *firstClientMapping = [[AMAAttributionMapping alloc] initWithEventFilters:@[firstClientEventFilter]
                                                                                              requiredCount:1
                                                                                        conversionValueDiff:0];
            AMAEventFilter *secondClientEventFilter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeClient
                                                                           clientEventCondition:[[AMAClientEventCondition alloc] initWithName:@"client name #2"]
                                                                        eCommerceEventCondition:nil
                                                                          revenueEventCondition:nil];
            AMAAttributionMapping *secondClientMapping = [[AMAAttributionMapping alloc] initWithEventFilters:@[secondClientEventFilter]
                                                                                               requiredCount:2
                                                                                         conversionValueDiff:1];
            AMAEventFilter *thirdClientEventFilter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeClient
                                                                          clientEventCondition:[[AMAClientEventCondition alloc] initWithName:@"client name #3"]
                                                                       eCommerceEventCondition:nil
                                                                         revenueEventCondition:nil];
            AMAAttributionMapping *thirdClientMapping = [[AMAAttributionMapping alloc] initWithEventFilters:@[thirdClientEventFilter]
                                                                                              requiredCount:2
                                                                                        conversionValueDiff:2];
            AMAAttributionMapping *firstAndSecondMapping = [[AMAAttributionMapping alloc] initWithEventFilters:@[firstClientEventFilter, secondClientEventFilter]
                                                                                                 requiredCount:3
                                                                                           conversionValueDiff:4];
            AMAEventFilter *fourthClientEventFilter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeClient
                                                                           clientEventCondition:[[AMAClientEventCondition alloc] initWithName:@"client name #4"]
                                                                        eCommerceEventCondition:nil
                                                                          revenueEventCondition:nil];
            AMAAttributionMapping *fourthClientMapping = [[AMAAttributionMapping alloc] initWithEventFilters:@[fourthClientEventFilter, fourthClientEventFilter]
                                                                                               requiredCount:1
                                                                                         conversionValueDiff:8];
            AMAConversionAttributionModelConfiguration *config = [[AMAConversionAttributionModelConfiguration alloc] initWithMappings:@[
                firstClientMapping, secondClientMapping, firstAndSecondMapping, thirdClientMapping, fourthClientMapping
            ]];
            conversion = [[AMAConversionAttributionModel alloc] initWithConfig:config
                                                        eventCountByKeyHelper:eventCountByKeyHelper];

        });
        it(@"Nil config", ^{
            conversion = [[AMAConversionAttributionModel alloc] initWithConfig:nil
                                                         eventCountByKeyHelper:eventCountByKeyHelper];
            [[[conversion checkAttributionForClientEvent:@"some name"] should] beNil];
        });
        it(@"Should be nil for no match", ^{
            [[[conversion checkAttributionForClientEvent:@"bad name"] should] beNil];
        });
        context(@"client name #1", ^{
            it(@"Should be 0 for 1 event", ^{
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"0"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(1), @"0"];
                [[[conversion checkAttributionForClientEvent:@"client name #1"] should] equal:theValue(0)];
            });
            it(@"Should be prev value for 1 event", ^{
                [persistentConfiguration stub:@selector(conversionValue) andReturn:@10];
                [[[conversion checkAttributionForClientEvent:@"client name #1"] should] equal:theValue(10)];
            });
            it(@"Should be nil for 2 events", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"0"];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"0"];
                [[[conversion checkAttributionForClientEvent:@"client name #1"] should] beNil];
            });
            it(@"Should be prev value for 2 events f has prev value", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"0"];
                [persistentConfiguration stub:@selector(conversionValue) andReturn:@10];
                [[[conversion checkAttributionForClientEvent:@"client name #1"] should] beNil];
            });
            it(@"Should be 4 for event if it triggers to mappings", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(2) withArguments:@"4"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"0"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"4"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(1), @"0"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(3), @"4"];
                [[[conversion checkAttributionForClientEvent:@"client name #1"] should] equal:theValue(4)];
            });
            it(@"Should not increment unnecessary counts", ^{
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"1"];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"2"];
                [conversion checkAttributionForClientEvent:@"client name #1"];
            });
        });
        context(@"client name #2", ^{
            it(@"Should be nil for 1 event", ^{
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"1"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(1), @"1"];
                [[[conversion checkAttributionForClientEvent:@"client name #2"] should] beNil];
            });
            it(@"Should be nil for 1 event if has prev", ^{
                [persistentConfiguration stub:@selector(conversionValue) andReturn:@10];
                [[[conversion checkAttributionForClientEvent:@"client name #2"] should] beNil];
            });
            it(@"Should be 1 for 2 events", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"1"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"1"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(2), @"1"];
                [[[conversion checkAttributionForClientEvent:@"client name #2"] should] equal:@1];
            });
            it(@"Should be 9 for 2 events if has prev", ^{
                [persistentConfiguration stub:@selector(conversionValue) andReturn:@8];
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"1"];
                [[[conversion checkAttributionForClientEvent:@"client name #2"] should] equal:@9];
            });
            it(@"Should be nil for 3 events", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(2) withArguments:@"1"];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"1"];
                [[[conversion checkAttributionForClientEvent:@"client name #2"] should] beNil];
            });
            it(@"Should be 5 for event if it triggers 2 mappings", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(2) withArguments:@"4"];
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"1"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"1"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"4"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(2), @"1"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(3), @"4"];
                [[[conversion checkAttributionForClientEvent:@"client name #2"] should] equal:theValue(5)];
            });
            it(@"Should be nil if does not trigger anything", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"4"];
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(2) withArguments:@"1"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"1"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"4"];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"1"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(2), @"4"];
                [[[conversion checkAttributionForClientEvent:@"client name #2"] should] beNil];
            });
            it(@"Should not increment unnecessary counts", ^{
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"0"];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"2"];
                [conversion checkAttributionForClientEvent:@"client name #2"];
            });
        });
        context(@"client event #3", ^{
            it(@"Should be 2 for 2 events", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"2"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"2"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(2), @"2"];
                [[[conversion checkAttributionForClientEvent:@"client name #3"] should] equal:@2];
            });
            it(@"Should be nil for 1 event", ^{
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"2"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(1), @"2"];
                [[[conversion checkAttributionForClientEvent:@"client name #3"] should] beNil];
            });
            it(@"Should be nil for 3 events", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(2) withArguments:@"2"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"2"];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"2"];
                [[[conversion checkAttributionForClientEvent:@"client name #3"] should] beNil];
            });
        });
        context(@"client event #4", ^{
            it(@"Should be 8 for 1 event", ^{
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"8"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(1), @"8"];
                [[[conversion checkAttributionForClientEvent:@"client name #4"] should] equal:@8];
            });
            it(@"Should be nil for 2 events", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"8"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"8"];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"8"];
                [[[conversion checkAttributionForClientEvent:@"client name #4"] should] beNil];
            });
        });
    });
    context(@"Revenue event", ^{
        AMALightRevenueEvent *__block revenue = nil;
        AMAAttributionMapping *__block apiRevenueMapping = nil;
        beforeEach(^{
            revenue = [AMALightRevenueEvent nullMock];
            AMAEventFilter *apiRevenueFilter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeRevenue
                                                                    clientEventCondition:nil
                                                                 eCommerceEventCondition:nil
                                                                   revenueEventCondition:[[AMARevenueEventCondition alloc] initWithSource:AMARevenueSourceAPI]];
            apiRevenueMapping = [[AMAAttributionMapping alloc] initWithEventFilters:@[apiRevenueFilter, apiRevenueFilter]
                                                                      requiredCount:2
                                                                conversionValueDiff:0];
            AMAEventFilter *autoRevenueFilter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeRevenue
                                                                     clientEventCondition:nil
                                                                  eCommerceEventCondition:nil
                                                                    revenueEventCondition:[[AMARevenueEventCondition alloc] initWithSource:AMARevenueSourceAuto]];
            AMAAttributionMapping *autoRevenueMapping = [[AMAAttributionMapping alloc] initWithEventFilters:@[autoRevenueFilter]
                                                                                             requiredCount:1
                                                                                       conversionValueDiff:1];
            AMAAttributionMapping *secondAutoRevenueMapping = [[AMAAttributionMapping alloc] initWithEventFilters:@[autoRevenueFilter]
                                                                                                    requiredCount:2
                                                                                              conversionValueDiff:2];
            AMAConversionAttributionModelConfiguration *config = [[AMAConversionAttributionModelConfiguration alloc] initWithMappings:@[
                apiRevenueMapping, autoRevenueMapping, secondAutoRevenueMapping
            ]];
            conversion = [[AMAConversionAttributionModel alloc] initWithConfig:config
                                                         eventCountByKeyHelper:eventCountByKeyHelper];

        });
        it(@"Nil config", ^{
            conversion = [[AMAConversionAttributionModel alloc] initWithConfig:nil
                                                         eventCountByKeyHelper:eventCountByKeyHelper];
            [[[conversion checkAttributionForRevenueEvent:revenue] should] beNil];
        });
        it(@"Should be nil for no match", ^{
            [revenue stub:@selector(isAuto) andReturn:theValue(YES)];
            AMAConversionAttributionModelConfiguration *config = [[AMAConversionAttributionModelConfiguration alloc] initWithMappings:@[
                apiRevenueMapping
            ]];
            conversion = [[AMAConversionAttributionModel alloc] initWithConfig:config
                                                         eventCountByKeyHelper:eventCountByKeyHelper];
            [[[conversion checkAttributionForRevenueEvent:revenue] should] beNil];
        });
        context(@"API", ^{
            beforeEach(^{
                [revenue stub:@selector(isAuto) andReturn:theValue(NO)];
            });
            it(@"Should be nil for 1 event", ^{
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"0"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(1), @"0"];
                [[[conversion checkAttributionForRevenueEvent:revenue] should] beNil];
            });
            it(@"Should be nil for 1 event if has prev", ^{
                [persistentConfiguration stub:@selector(conversionValue) andReturn:@10];
                [[[conversion checkAttributionForRevenueEvent:revenue] should] beNil];
            });
            it(@"Should be 0 for 2 events", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"0"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"0"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(2), @"0"];
                [[[conversion checkAttributionForRevenueEvent:revenue] should] equal:@0];
            });
            it(@"Should be prev for 2 events if has prev", ^{
                [persistentConfiguration stub:@selector(conversionValue) andReturn:@10];
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"0"];
                [[[conversion checkAttributionForRevenueEvent:revenue] should] equal:@10];
            });
            it(@"Should be nil for 3 events", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(2) withArguments:@"0"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"0"];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"0"];
                [[[conversion checkAttributionForRevenueEvent:revenue] should] beNil];
            });
        });
        context(@"Automatic", ^{
            beforeEach(^{
                [revenue stub:@selector(isAuto) andReturn:theValue(YES)];
            });
            it(@"Should be 1 for 1 event", ^{
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"1"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"2"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(1), @"1"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(1), @"2"];
                [[[conversion checkAttributionForRevenueEvent:revenue] should] equal:@1];
            });
            it(@"Should be 9 for 1 event if has prev", ^{
                [persistentConfiguration stub:@selector(conversionValue) andReturn:@8];
                [[[conversion checkAttributionForRevenueEvent:revenue] should] equal:@9];
            });
            it(@"Should be 3 for event that triggers 2 mappings", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"2"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"1"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(1), @"1"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"2"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(2), @"2"];
                [[[conversion checkAttributionForRevenueEvent:revenue] should] equal:@3];
            });
            it(@"Should be 2 for 2 events", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"2"];
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"1"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"1"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"2"];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"1"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(2), @"2"];
                [[[conversion checkAttributionForRevenueEvent:revenue] should] equal:@2];
            });
            it(@"Should be nil if does not trigger anything", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(2) withArguments:@"2"];
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"1"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"1"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"2"];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"1"];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"2"];
                [[[conversion checkAttributionForRevenueEvent:revenue] should] beNil];
            });
        });
    });
    context(@"E-commerce event", ^{
        AMALightECommerceEvent *__block eCommerce = nil;
        AMAAttributionMapping *__block screenMapping = nil;
        beforeEach(^{
            eCommerce = [AMALightECommerceEvent nullMock];
            [eCommerce stub:@selector(isFirst) andReturn:theValue(YES)];
            AMAEventFilter *screenFilter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeECommerce
                                                                clientEventCondition:nil
                                                             eCommerceEventCondition:[[AMAECommerceEventCondition alloc] initWithType:AMAECommerceEventTypeScreen]
                                                               revenueEventCondition:nil];
            AMAEventFilter *productCardFilter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeECommerce
                                                                     clientEventCondition:nil
                                                                  eCommerceEventCondition:[[AMAECommerceEventCondition alloc] initWithType:AMAECommerceEventTypeProductCard]
                                                                    revenueEventCondition:nil];
            AMAEventFilter *productDetailsFilter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeECommerce
                                                                        clientEventCondition:nil
                                                                     eCommerceEventCondition:[[AMAECommerceEventCondition alloc] initWithType:AMAECommerceEventTypeProductDetails]
                                                                       revenueEventCondition:nil];
            AMAEventFilter *addToCartFilter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeECommerce
                                                                   clientEventCondition:nil
                                                                eCommerceEventCondition:[[AMAECommerceEventCondition alloc] initWithType:AMAECommerceEventTypeAddToCart]
                                                                  revenueEventCondition:nil];
            AMAEventFilter *removeFromCartFilter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeECommerce
                                                                        clientEventCondition:nil
                                                                     eCommerceEventCondition:[[AMAECommerceEventCondition alloc] initWithType:AMAECommerceEventTypeRemoveFromCart]
                                                                       revenueEventCondition:nil];
            AMAEventFilter *beginCheckoutFilter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeECommerce
                                                                       clientEventCondition:nil
                                                                    eCommerceEventCondition:[[AMAECommerceEventCondition alloc] initWithType:AMAECommerceEventTypeBeginCheckout]
                                                                      revenueEventCondition:nil];
            AMAEventFilter *purchaseFilter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeECommerce
                                                                  clientEventCondition:nil
                                                               eCommerceEventCondition:[[AMAECommerceEventCondition alloc] initWithType:AMAECommerceEventTypePurchase]
                                                                 revenueEventCondition:nil];
            screenMapping = [[AMAAttributionMapping alloc] initWithEventFilters:@[screenFilter]
                                                                  requiredCount:1
                                                            conversionValueDiff:0];
            AMAAttributionMapping *productCardMapping = [[AMAAttributionMapping alloc] initWithEventFilters:@[productCardFilter]
                                                                                              requiredCount:2
                                                                                        conversionValueDiff:1];
            AMAAttributionMapping *productDetailsMapping = [[AMAAttributionMapping alloc] initWithEventFilters:@[productDetailsFilter]
                                                                                                 requiredCount:1
                                                                                           conversionValueDiff:2];
            AMAAttributionMapping *addToCartMapping = [[AMAAttributionMapping alloc] initWithEventFilters:@[addToCartFilter, addToCartFilter]
                                                                                            requiredCount:1
                                                                                      conversionValueDiff:4];
            AMAAttributionMapping *removeFromCartMapping = [[AMAAttributionMapping alloc] initWithEventFilters:@[removeFromCartFilter]
                                                                                                 requiredCount:1
                                                                                           conversionValueDiff:8];
            AMAAttributionMapping *beginCheckoutMapping = [[AMAAttributionMapping alloc] initWithEventFilters:@[beginCheckoutFilter]
                                                                                                requiredCount:1
                                                                                          conversionValueDiff:16];
            AMAAttributionMapping *purchaseMapping = [[AMAAttributionMapping alloc] initWithEventFilters:@[purchaseFilter]
                                                                                           requiredCount:1
                                                                                     conversionValueDiff:32];
            AMAAttributionMapping *beginCheckoutAndPurchaseMapping = [[AMAAttributionMapping alloc] initWithEventFilters:@[beginCheckoutFilter, purchaseFilter]
                                                                                                           requiredCount:2
                                                                                                     conversionValueDiff:64];
            AMAConversionAttributionModelConfiguration *config = [[AMAConversionAttributionModelConfiguration alloc] initWithMappings:@[
                screenMapping,
                productCardMapping,
                productDetailsMapping,
                addToCartMapping,
                removeFromCartMapping,
                beginCheckoutMapping,
                purchaseMapping,
                beginCheckoutAndPurchaseMapping
            ]];
            conversion = [[AMAConversionAttributionModel alloc] initWithConfig:config
                                                         eventCountByKeyHelper:eventCountByKeyHelper];
        });
        it(@"Nil config", ^{
            [eCommerce stub:@selector(type) andReturn:theValue(AMAECommerceEventTypePurchase)];
            conversion = [[AMAConversionAttributionModel alloc] initWithConfig:nil
                                                         eventCountByKeyHelper:eventCountByKeyHelper];
            [[[conversion checkAttributionForECommerceEvent:eCommerce] should] beNil];
        });
        it(@"Should be nil for no match", ^{
            [eCommerce stub:@selector(type) andReturn:theValue(AMAECommerceEventTypePurchase)];
            AMAConversionAttributionModelConfiguration *config = [[AMAConversionAttributionModelConfiguration alloc] initWithMappings:@[
                screenMapping
            ]];
            conversion = [[AMAConversionAttributionModel alloc] initWithConfig:config
                                                         eventCountByKeyHelper:eventCountByKeyHelper];
            [[[conversion checkAttributionForECommerceEvent:eCommerce] should] beNil];
        });
        it(@"Should be nil for non-first", ^{
            [eCommerce stub:@selector(type) andReturn:theValue(AMAECommerceEventTypeScreen)];
            [eCommerce stub:@selector(isFirst) andReturn:theValue(NO)];
            [[[conversion checkAttributionForECommerceEvent:eCommerce] should] beNil];
        });
        context(@"Screen type", ^{
            beforeEach(^{
                [eCommerce stub:@selector(type) andReturn:theValue(AMAECommerceEventTypeScreen)];
            });
            it(@"Should be 0 for 1 event", ^{
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"0"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(1), @"0"];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] equal:theValue(0)];
            });
            it(@"Should be prev for 1 event if has prev", ^{
                [persistentConfiguration stub:@selector(conversionValue) andReturn:@10];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] equal:@10];
            });
            it(@"Should be nil for 2 events", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"0"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"0"];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"0"];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] beNil];
            });
            it(@"Should be nil for 2 events if has prev", ^{
                [persistentConfiguration stub:@selector(conversionValue) andReturn:@10];
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"0"];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] beNil];
            });
        });
        context(@"Product card type", ^{
            beforeEach(^{
                [eCommerce stub:@selector(type) andReturn:theValue(AMAECommerceEventTypeProductCard)];
            });
            it(@"Should be nil for 1 event", ^{
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"1"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(1), @"1"];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] beNil];
            });
            it(@"Should be 1 for 2 events", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"1"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"1"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(2), @"1"];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] equal:@1];
            });
            it(@"Should be nil for 3 events", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(2) withArguments:@"1"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"1"];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"1"];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] beNil];
            });
        });
        context(@"Product details type", ^{
            beforeEach(^{
                [eCommerce stub:@selector(type) andReturn:theValue(AMAECommerceEventTypeProductDetails)];
            });
            it(@"Should be 2 for 1 event", ^{
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"2"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(1), @"2"];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] equal:@2];
            });
            it(@"Should be 10 for 1 event if has prev", ^{
                [persistentConfiguration stub:@selector(conversionValue) andReturn:@8];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] equal:@10];
            });
            it(@"Should be nil for 2 events", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"2"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"2"];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"2"];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] beNil];
            });
            it(@"Should be nil for 2 events if has prev", ^{
                [persistentConfiguration stub:@selector(conversionValue) andReturn:@10];
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"2"];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] beNil];
            });
        });
        context(@"Add to cart type", ^{
            beforeEach(^{
                [eCommerce stub:@selector(type) andReturn:theValue(AMAECommerceEventTypeAddToCart)];
            });
            it(@"Should be 4 for 1 event", ^{
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"4"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(1), @"4"];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] equal:@4];
            });
            it(@"Should be nil for 2 events", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"4"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"4"];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"4"];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] beNil];
            });
        });
        context(@"Remove from cart type", ^{
            beforeEach(^{
                [eCommerce stub:@selector(type) andReturn:theValue(AMAECommerceEventTypeRemoveFromCart)];
            });
            it(@"Should be 8 for 1 event", ^{
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"8"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(1), @"8"];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] equal:theValue(8)];
            });
            it(@"Should be nil for 2 events", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"8"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"8"];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"8"];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] beNil];
            });
        });
        context(@"Begin checkout type", ^{
            beforeEach(^{
                [eCommerce stub:@selector(type) andReturn:theValue(AMAECommerceEventTypeBeginCheckout)];
            });
            it(@"Should be 16 for 1 event", ^{
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"16"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(1), @"16"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"64"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(1), @"64"];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] equal:theValue(16)];
            });
            it(@"Should be 80 if event triggers 2 mappings", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"64"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"16"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(1), @"16"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"64"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(2), @"64"];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] equal:theValue(80)];
            });
            it(@"Should be 64 if triggers only second mapping", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"64"];
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"16"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"16"];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"16"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"64"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(2), @"64"];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] equal:theValue(64)];
            });
            it(@"Should be nil if does not trigger anything", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"16"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"16"];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"16"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"64"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(1), @"64"];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] beNil];
            });
        });
        context(@"Purchase type", ^{
            beforeEach(^{
                [eCommerce stub:@selector(type) andReturn:theValue(AMAECommerceEventTypePurchase)];
            });
            it(@"Should be 32 for 1 event", ^{
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"32"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(1), @"32"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"64"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(1), @"64"];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] equal:theValue(32)];
            });
            it(@"Should be 96 if event triggers 2 mappings", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"64"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"32"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(1), @"32"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"64"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(2), @"64"];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] equal:theValue(96)];
            });
            it(@"Should be 64 if triggers only second mapping", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"64"];
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"32"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"32"];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"32"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"64"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(2), @"64"];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] equal:theValue(64)];
            });
            it(@"Should be nil if does not trigger anything", ^{
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(1) withArguments:@"32"];
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(2) withArguments:@"64"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"32"];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"32"];
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"64"];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"64"];
                [[[conversion checkAttributionForECommerceEvent:eCommerce] should] beNil];
            });
        });
    });
    context(@"Mixed mappings", ^{
        AMALightECommerceEvent *__block eCommerce = nil;
        AMALightRevenueEvent *__block revenue = nil;
        beforeEach(^{
            eCommerce = [AMALightECommerceEvent nullMock];
            [eCommerce stub:@selector(isFirst) andReturn:theValue(YES)];
            revenue = [AMALightRevenueEvent nullMock];
            AMAEventFilter *screenFilter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeECommerce
                                                                clientEventCondition:nil
                                                             eCommerceEventCondition:[[AMAECommerceEventCondition alloc] initWithType:AMAECommerceEventTypeScreen]
                                                               revenueEventCondition:nil];
            AMAEventFilter *apiRevenueFilter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeRevenue
                                                                    clientEventCondition:nil
                                                                 eCommerceEventCondition:nil
                                                                   revenueEventCondition:[[AMARevenueEventCondition alloc] initWithSource:AMARevenueSourceAPI]];
            AMAEventFilter *firstClientEventFilter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeClient
                                                                          clientEventCondition:[[AMAClientEventCondition alloc] initWithName:@"client name #1"]
                                                                       eCommerceEventCondition:nil
                                                                         revenueEventCondition:nil];
            AMAEventFilter *secondClientEventFilter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeClient
                                                                           clientEventCondition:[[AMAClientEventCondition alloc] initWithName:@"client name #2"]
                                                                        eCommerceEventCondition:nil
                                                                          revenueEventCondition:nil];
            AMAAttributionMapping *secondClientMapping = [[AMAAttributionMapping alloc] initWithEventFilters:@[secondClientEventFilter]
                                                                                               requiredCount:1
                                                                                         conversionValueDiff:1];
            AMAAttributionMapping *mixedMapping = [[AMAAttributionMapping alloc] initWithEventFilters:@[firstClientEventFilter, apiRevenueFilter, screenFilter]
                                                                                        requiredCount:4
                                                                                  conversionValueDiff:2];
            AMAConversionAttributionModelConfiguration *config = [[AMAConversionAttributionModelConfiguration alloc] initWithMappings:@[
                mixedMapping, secondClientMapping
            ]];
            conversion = [[AMAConversionAttributionModel alloc] initWithConfig:config
                                                         eventCountByKeyHelper:eventCountByKeyHelper];
        });
        it(@"Should be 2 for 3 mixed events and screen type", ^{
            [eCommerce stub:@selector(type) andReturn:theValue(AMAECommerceEventTypeScreen)];
            [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(3) withArguments:@"2"];
            [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(4), @"2"];
            [[[conversion checkAttributionForECommerceEvent:eCommerce] should] equal:@2];
        });
        it(@"Should be 2 for 3 mixed events and revenue", ^{
            [revenue stub:@selector(isAuto) andReturn:theValue(NO)];
            [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(3) withArguments:@"2"];
            [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(4), @"2"];
            [[[conversion checkAttributionForRevenueEvent:revenue] should] equal:@2];
        });
        it(@"Should be 2 for 3 mixed events and first client event", ^{
            [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(3) withArguments:@"2"];
            [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(4), @"2"];
            [[[conversion checkAttributionForClientEvent:@"client name #1"] should] equal:@2];
        });
        it(@"Should be nil for 3 mixed events and third client event", ^{
            [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(3) withArguments:@"2"];
            [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:) withArguments:kw_any(), @"2"];
            [[[conversion checkAttributionForClientEvent:@"client name #3"] should] beNil];
        });
        it(@"Should be 1 for second client event", ^{
            [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(1), @"1"];
            [[[conversion checkAttributionForClientEvent:@"client name #2"] should] equal:@1];
        });
    });
    
    it(@"Should conform to AMAAttributionModel", ^{
        AMAConversionAttributionModel *model = [[AMAConversionAttributionModel alloc] init];
        [[model should] conformToProtocol:@protocol(AMAAttributionModel)];
    });
});

SPEC_END
