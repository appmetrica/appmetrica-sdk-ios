
#import <Kiwi/Kiwi.h>
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAMetricaConfiguration.h"
#import "AMAEventCountByKeyHelper.h"
#import "AMAEngagementAttributionModel.h"
#import "AMABoundMappingChecker.h"
#import "AMAEventFilter.h"
#import "AMABoundMapping.h"
#import "AMAEngagementAttributionModelConfiguration.h"
#import "AMAClientEventCondition.h"
#import "AMARevenueEventCondition.h"
#import "AMAECommerceEventCondition.h"
#import "AMALightRevenueEvent.h"
#import "AMALightECommerceEvent.h"

SPEC_BEGIN(AMAEngagementAttributionModelTests)

describe(@"AMAEngagementAttributionModel", ^{

    AMAEventCountByKeyHelper *__block eventCountByKeyHelper = nil;
    AMABoundMappingChecker *__block boundMappingChecker = nil;
    AMAEngagementAttributionModel *__block engagement = nil;
    AMAMetricaPersistentConfiguration *__block persistentConfiguration = nil;
    beforeEach(^{
        eventCountByKeyHelper = [AMAEventCountByKeyHelper nullMock];
        boundMappingChecker = [AMABoundMappingChecker nullMock];
        persistentConfiguration = [AMAMetricaPersistentConfiguration nullMock];
        AMAMetricaConfiguration *configuration = [AMAMetricaConfiguration nullMock];
        [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:configuration];
        [configuration stub:@selector(persistent) andReturn:persistentConfiguration];
        [persistentConfiguration stub:@selector(conversionValue) andReturn:@13];
    });
    context(@"Client event", ^{
        NSArray *boundMappings = @[ [AMABoundMapping nullMock] ];
        AMAClientEventCondition *__block firstClientCondition;
        AMAClientEventCondition *__block secondClientCondition;
        AMARevenueEventCondition *__block revenueEventCondition;
        AMAECommerceEventCondition *__block eCommerceCondition;
        AMAEventFilter *__block firstFilter;
        AMAEventFilter *__block secondFilter;
        beforeEach(^{
            revenueEventCondition = [AMARevenueEventCondition nullMock];
            eCommerceCondition = [AMAECommerceEventCondition nullMock];
            firstClientCondition = [AMAClientEventCondition nullMock];
            firstFilter = [AMAEventFilter nullMock];
            [firstFilter stub:@selector(clientEventCondition) andReturn:firstClientCondition];
            [firstFilter stub:@selector(revenueEventCondition) andReturn:revenueEventCondition];
            [firstFilter stub:@selector(eCommerceEventCondition) andReturn:eCommerceCondition];
            secondClientCondition = [AMAClientEventCondition nullMock];
            secondFilter = [AMAEventFilter nullMock];
            [secondFilter stub:@selector(clientEventCondition) andReturn:secondClientCondition];
            AMAEngagementAttributionModelConfiguration *config =
                [[AMAEngagementAttributionModelConfiguration alloc] initWithEventFilters:@[ firstFilter, secondFilter ]
                                                                           boundMappings:boundMappings];
            engagement = [[AMAEngagementAttributionModel alloc] initWithConfig:config
                                                         eventCountByKeyHelper:eventCountByKeyHelper
                                                           boundMappingChecker:boundMappingChecker];
        });
        context(@"Nil config", ^{
            beforeEach(^{
                engagement = [[AMAEngagementAttributionModel alloc] initWithConfig:nil
                                                             eventCountByKeyHelper:eventCountByKeyHelper
                                                               boundMappingChecker:boundMappingChecker];
            });
            it(@"Should not interact with eventCountByKeyHelper", ^{
                [[eventCountByKeyHelper shouldNot] receive:@selector(getCountForKey:)];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:)];
                [engagement checkAttributionForClientEvent:@"some name"];
            });
            it(@"Should not interact with boundMappingChecker", ^{
                [[boundMappingChecker shouldNot] receive:@selector(check:mappings:)];
                [engagement checkAttributionForClientEvent:@"some name"];
            });
            it(@"Should be nil", ^{
                [[[engagement checkAttributionForClientEvent:@"some name"] should] beNil];
            });
        });
        context(@"No match", ^{
            NSString *eventName = @"some name";
            beforeEach(^{
                [firstClientCondition stub:@selector(checkEvent:) andReturn:theValue(NO)];
                [secondClientCondition stub:@selector(checkEvent:) andReturn:theValue(NO)];
            });
            it(@"Should interact with right conditions", ^{
                [[firstClientCondition should] receive:@selector(checkEvent:) withArguments:eventName];
                [[secondClientCondition should] receive:@selector(checkEvent:) withArguments:eventName];
                [[revenueEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[eCommerceCondition shouldNot] receive:@selector(checkEvent:)];
                [engagement checkAttributionForClientEvent:eventName];
            });
            it(@"Should not interact with eventCountByKeyHelper", ^{
                [[eventCountByKeyHelper shouldNot] receive:@selector(getCountForKey:)];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:)];
                [engagement checkAttributionForClientEvent:eventName];
            });
            it(@"Should not interact with boundMappingChecker", ^{
                [[boundMappingChecker shouldNot] receive:@selector(check:mappings:)];
                [engagement checkAttributionForClientEvent:eventName];
            });
            it(@"Should be nil", ^{
                [[[engagement checkAttributionForClientEvent:eventName] should] beNil];
            });
        });
        context(@"First match", ^{
            NSString *eventName = @"some name";
            beforeEach(^{
                [firstClientCondition stub:@selector(checkEvent:) andReturn:theValue(YES)];
                [secondClientCondition stub:@selector(checkEvent:) andReturn:theValue(NO)];
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(4)];
                [boundMappingChecker stub:@selector(check:mappings:) andReturn:@10];
            });
            it(@"Should interact with right conditions", ^{
                [[firstClientCondition should] receive:@selector(checkEvent:) withArguments:eventName];
                [[secondClientCondition shouldNot] receive:@selector(checkEvent:) withArguments:eventName];
                [[revenueEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[eCommerceCondition shouldNot] receive:@selector(checkEvent:)];
                [engagement checkAttributionForClientEvent:eventName];
            });
            it(@"Should interact with eventCountByKeyHelper", ^{
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"engagement"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(5), @"engagement"];
                [engagement checkAttributionForClientEvent:eventName];
            });
            it(@"Should interact with boundMappingChecker", ^{
                [[boundMappingChecker should] receive:@selector(check:mappings:)
                                        withArguments:[NSDecimalNumber decimalNumberWithString:@"5"], boundMappings];
                [engagement checkAttributionForClientEvent:eventName];
            });
            it(@"Should be 10", ^{
                [[[engagement checkAttributionForClientEvent:eventName] should] equal:@10];
            });
        });
        context(@"Second match", ^{
            NSString *eventName = @"some name";
            beforeEach(^{
                [firstClientCondition stub:@selector(checkEvent:) andReturn:theValue(NO)];
                [secondClientCondition stub:@selector(checkEvent:) andReturn:theValue(YES)];
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(4)];
                [boundMappingChecker stub:@selector(check:mappings:) andReturn:@10];
            });
            it(@"Should interact with right conditions", ^{
                [[firstClientCondition should] receive:@selector(checkEvent:) withArguments:eventName];
                [[secondClientCondition should] receive:@selector(checkEvent:)];
                [[revenueEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[eCommerceCondition shouldNot] receive:@selector(checkEvent:)];
                [engagement checkAttributionForClientEvent:eventName];
            });
            it(@"Should interact with eventCountByKeyHelper", ^{
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"engagement"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(5), @"engagement"];
                [engagement checkAttributionForClientEvent:eventName];
            });
            it(@"Should interact with boundMappingChecker", ^{
                [[boundMappingChecker should] receive:@selector(check:mappings:)
                                        withArguments:[NSDecimalNumber decimalNumberWithString:@"5"], boundMappings];
                [engagement checkAttributionForClientEvent:eventName];
            });
            it(@"Should be 10", ^{
                [[[engagement checkAttributionForClientEvent:eventName] should] equal:@10];
            });
        });
    });
    context(@"Revenue event", ^{
        NSArray *boundMappings = @[ [AMABoundMapping nullMock] ];
        AMARevenueEventCondition *__block firstRevenueCondition;
        AMARevenueEventCondition *__block secondRevenueCondition;
        AMAClientEventCondition *__block clientCondition;
        AMAECommerceEventCondition *__block eCommerceCondition;
        AMAEventFilter *__block firstFilter;
        AMAEventFilter *__block secondFilter;
        AMALightRevenueEvent *__block revenue = nil;
        beforeEach(^{
            revenue = [AMALightRevenueEvent nullMock];
            [revenue stub:@selector(isAuto) andReturn:theValue(NO)];
            clientCondition = [AMAClientEventCondition nullMock];
            eCommerceCondition = [AMAECommerceEventCondition nullMock];
            firstRevenueCondition = [AMARevenueEventCondition nullMock];
            firstFilter = [AMAEventFilter nullMock];
            [firstFilter stub:@selector(revenueEventCondition) andReturn:firstRevenueCondition];
            [firstFilter stub:@selector(clientEventCondition) andReturn:clientCondition];
            [firstFilter stub:@selector(eCommerceEventCondition) andReturn:eCommerceCondition];
            secondRevenueCondition = [AMARevenueEventCondition nullMock];
            secondFilter = [AMAEventFilter nullMock];
            [secondFilter stub:@selector(revenueEventCondition) andReturn:secondRevenueCondition];
            AMAEngagementAttributionModelConfiguration *config =
                [[AMAEngagementAttributionModelConfiguration alloc] initWithEventFilters:@[ firstFilter, secondFilter ]
                                                                           boundMappings:boundMappings];
            engagement = [[AMAEngagementAttributionModel alloc] initWithConfig:config
                                                         eventCountByKeyHelper:eventCountByKeyHelper
                                                           boundMappingChecker:boundMappingChecker];
        });
        context(@"Nil config", ^{
            beforeEach(^{
                engagement = [[AMAEngagementAttributionModel alloc] initWithConfig:nil
                                                             eventCountByKeyHelper:eventCountByKeyHelper
                                                               boundMappingChecker:boundMappingChecker];
            });
            it(@"Should not interact with eventCountByKeyHelper", ^{
                [[eventCountByKeyHelper shouldNot] receive:@selector(getCountForKey:)];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:)];
                [engagement checkAttributionForRevenueEvent:revenue];
            });
            it(@"Should not interact with boundMappingChecker", ^{
                [[boundMappingChecker shouldNot] receive:@selector(check:mappings:)];
                [engagement checkAttributionForRevenueEvent:revenue];
            });
            it(@"Should be nil", ^{
                [[[engagement checkAttributionForRevenueEvent:revenue] should] beNil];
            });
        });
        context(@"No match", ^{
            beforeEach(^{
                [secondRevenueCondition stub:@selector(checkEvent:) andReturn:theValue(NO)];
            });
            it(@"Should interact with right conditions", ^{
                [[firstRevenueCondition should] receive:@selector(checkEvent:) withArguments:theValue(NO)];
                [[secondRevenueCondition should] receive:@selector(checkEvent:) withArguments:theValue(NO)];
                [[clientCondition shouldNot] receive:@selector(checkEvent:)];
                [[eCommerceCondition shouldNot] receive:@selector(checkEvent:)];
                [engagement checkAttributionForRevenueEvent:revenue];
            });
            it(@"Should not interact with eventCountByKeyHelper", ^{
                [[eventCountByKeyHelper shouldNot] receive:@selector(getCountForKey:)];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:)];
                [engagement checkAttributionForRevenueEvent:revenue];
            });
            it(@"Should not interact with boundMappingChecker", ^{
                [[boundMappingChecker shouldNot] receive:@selector(check:mappings:)];
                [engagement checkAttributionForRevenueEvent:revenue];
            });
            it(@"Should be nil", ^{
                [[[engagement checkAttributionForRevenueEvent:revenue] should] beNil];
            });
        });
        context(@"First match", ^{
            beforeEach(^{
                [firstRevenueCondition stub:@selector(checkEvent:) andReturn:theValue(YES)];
                [secondRevenueCondition stub:@selector(checkEvent:) andReturn:theValue(NO)];
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(4)];
                [boundMappingChecker stub:@selector(check:mappings:) andReturn:@10];
            });
            it(@"Should interact with right conditions", ^{
                [[firstRevenueCondition should] receive:@selector(checkEvent:) withArguments:theValue(NO)];
                [[secondRevenueCondition shouldNot] receive:@selector(checkEvent:)];
                [[clientCondition shouldNot] receive:@selector(checkEvent:)];
                [[eCommerceCondition shouldNot] receive:@selector(checkEvent:)];
                [engagement checkAttributionForRevenueEvent:revenue];
            });
            it(@"Should interact with eventCountByKeyHelper", ^{
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"engagement"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(5), @"engagement"];
                [engagement checkAttributionForRevenueEvent:revenue];
            });
            it(@"Should interact with boundMappingChecker", ^{
                [[boundMappingChecker should] receive:@selector(check:mappings:)
                                        withArguments:[NSDecimalNumber decimalNumberWithString:@"5"], boundMappings];
                [engagement checkAttributionForRevenueEvent:revenue];
            });
            it(@"Should be 10", ^{
                [[[engagement checkAttributionForRevenueEvent:revenue] should] equal:@10];
            });
        });
        context(@"Second match", ^{
            beforeEach(^{
                [firstRevenueCondition stub:@selector(checkEvent:) andReturn:theValue(NO)];
                [secondRevenueCondition stub:@selector(checkEvent:) andReturn:theValue(YES)];
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(4)];
                [boundMappingChecker stub:@selector(check:mappings:) andReturn:@10];
            });
            it(@"Should interact with right conditions", ^{
                [[firstRevenueCondition should] receive:@selector(checkEvent:) withArguments:theValue(NO)];
                [[secondRevenueCondition should] receive:@selector(checkEvent:) withArguments:theValue(NO)];
                [[clientCondition shouldNot] receive:@selector(checkEvent:)];
                [[eCommerceCondition shouldNot] receive:@selector(checkEvent:)];
                [engagement checkAttributionForRevenueEvent:revenue];
            });
            it(@"Should interact with eventCountByKeyHelper", ^{
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"engagement"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(5), @"engagement"];
                [engagement checkAttributionForRevenueEvent:revenue];
            });
            it(@"Should interact with boundMappingChecker", ^{
                [[boundMappingChecker should] receive:@selector(check:mappings:)
                                        withArguments:[NSDecimalNumber decimalNumberWithString:@"5"], boundMappings];
                [engagement checkAttributionForRevenueEvent:revenue];
            });
            it(@"Should be 10", ^{
                [[[engagement checkAttributionForRevenueEvent:revenue] should] equal:@10];
            });
        });
    });
    context(@"E-commerce event", ^{
        AMALightECommerceEvent *__block eCommerce = nil;
        NSArray *boundMappings = @[ [AMABoundMapping nullMock] ];
        AMAECommerceEventCondition *__block firstEComCondition;
        AMAECommerceEventCondition *__block secondEComCondition;
        AMAClientEventCondition *__block clientCondition;
        AMARevenueEventCondition *__block revenueCondition;
        AMAEventFilter *__block firstFilter;
        AMAEventFilter *__block secondFilter;
        beforeEach(^{
            eCommerce = [AMALightECommerceEvent nullMock];
            [eCommerce stub:@selector(isFirst) andReturn:theValue(YES)];
            clientCondition = [AMAClientEventCondition nullMock];
            revenueCondition = [AMARevenueEventCondition nullMock];
            firstEComCondition = [AMAECommerceEventCondition nullMock];
            firstFilter = [AMAEventFilter nullMock];
            [firstFilter stub:@selector(eCommerceEventCondition) andReturn:firstEComCondition];
            [firstFilter stub:@selector(clientEventCondition) andReturn:clientCondition];
            [firstFilter stub:@selector(revenueEventCondition) andReturn:revenueCondition];
            secondEComCondition = [AMAECommerceEventCondition nullMock];
            secondFilter = [AMAEventFilter nullMock];
            [secondFilter stub:@selector(eCommerceEventCondition) andReturn:secondEComCondition];
            AMAEngagementAttributionModelConfiguration *config =
                [[AMAEngagementAttributionModelConfiguration alloc] initWithEventFilters:@[ firstFilter, secondFilter ]
                                                                           boundMappings:boundMappings];
            engagement = [[AMAEngagementAttributionModel alloc] initWithConfig:config
                                                         eventCountByKeyHelper:eventCountByKeyHelper
                                                           boundMappingChecker:boundMappingChecker];
        });
        context(@"Nil config", ^{
            beforeEach(^{
                engagement = [[AMAEngagementAttributionModel alloc] initWithConfig:nil
                                                             eventCountByKeyHelper:eventCountByKeyHelper
                                                               boundMappingChecker:boundMappingChecker];
                [eCommerce stub:@selector(type) andReturn:theValue(AMAECommerceEventTypeProductCard)];
            });
            it(@"Should not interact with eventCountByKeyHelper", ^{
                [[eventCountByKeyHelper shouldNot] receive:@selector(getCountForKey:)];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:)];
                [engagement checkAttributionForECommerceEvent:eCommerce];
            });
            it(@"Should not interact with boundMappingChecker", ^{
                [[boundMappingChecker shouldNot] receive:@selector(check:mappings:)];
                [engagement checkAttributionForECommerceEvent:eCommerce];
            });
            it(@"Should be nil", ^{
                [[[engagement checkAttributionForECommerceEvent:eCommerce] should] beNil];
            });
        });
        context(@"No match", ^{
            beforeEach(^{
                [firstEComCondition stub:@selector(checkEvent:) andReturn:theValue(NO)];
                [secondEComCondition stub:@selector(checkEvent:) andReturn:theValue(NO)];
                [eCommerce stub:@selector(type) andReturn:theValue(AMAECommerceEventTypeProductCard)];
            });
            it(@"Should interact with right conditions", ^{
                [[firstEComCondition should] receive:@selector(checkEvent:) withArguments:theValue(AMAECommerceEventTypeProductCard)];
                [[secondEComCondition should] receive:@selector(checkEvent:) withArguments:theValue(AMAECommerceEventTypeProductCard)];
                [[clientCondition shouldNot] receive:@selector(checkEvent:)];
                [[revenueCondition shouldNot] receive:@selector(checkEvent:)];
                [engagement checkAttributionForECommerceEvent:eCommerce];
            });
            it(@"Should not interact with eventCountByKeyHelper", ^{
                [[eventCountByKeyHelper shouldNot] receive:@selector(getCountForKey:)];
                [[eventCountByKeyHelper shouldNot] receive:@selector(setCount:forKey:)];
                [engagement checkAttributionForECommerceEvent:eCommerce];
            });
            it(@"Should not interact with boundMappingChecker", ^{
                [[boundMappingChecker shouldNot] receive:@selector(check:mappings:)];
                [engagement checkAttributionForECommerceEvent:eCommerce];
            });
            it(@"Should be nil", ^{
                [[[engagement checkAttributionForECommerceEvent:eCommerce] should] beNil];
            });
        });
        context(@"First match", ^{
            beforeEach(^{
                [firstEComCondition stub:@selector(checkEvent:) andReturn:theValue(YES)];
                [secondEComCondition stub:@selector(checkEvent:) andReturn:theValue(NO)];
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(4)];
                [boundMappingChecker stub:@selector(check:mappings:) andReturn:@10];
                [eCommerce stub:@selector(type) andReturn:theValue(AMAECommerceEventTypeProductCard)];
            });
            it(@"Not first event", ^{
                [eCommerce stub:@selector(isFirst) andReturn:theValue(NO)];
                [[firstEComCondition shouldNot] receive:@selector(checkEvent:)];
                [[secondEComCondition shouldNot] receive:@selector(checkEvent:)];
                [[clientCondition shouldNot] receive:@selector(checkEvent:)];
                [[revenueCondition shouldNot] receive:@selector(checkEvent:)];
                [[[engagement checkAttributionForECommerceEvent:eCommerce] should] beNil];
            });
            it(@"Should interact with right conditions", ^{
                [[firstEComCondition should] receive:@selector(checkEvent:) withArguments:theValue(AMAECommerceEventTypeProductCard)];
                [[secondEComCondition shouldNot] receive:@selector(checkEvent:)];
                [[clientCondition shouldNot] receive:@selector(checkEvent:)];
                [[revenueCondition shouldNot] receive:@selector(checkEvent:)];
                [engagement checkAttributionForECommerceEvent:eCommerce];
            });
            it(@"Should interact with eventCountByKeyHelper", ^{
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"engagement"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(5), @"engagement"];
                [engagement checkAttributionForECommerceEvent:eCommerce];
            });
            it(@"Should interact with boundMappingChecker", ^{
                [[boundMappingChecker should] receive:@selector(check:mappings:)
                                        withArguments:[NSDecimalNumber decimalNumberWithString:@"5"], boundMappings];
                [engagement checkAttributionForECommerceEvent:eCommerce];
            });
            it(@"Should be 10", ^{
                [[[engagement checkAttributionForECommerceEvent:eCommerce] should] equal:@10];
            });
        });
        context(@"Second match", ^{
            beforeEach(^{
                [firstEComCondition stub:@selector(checkEvent:) andReturn:theValue(NO)];
                [secondEComCondition stub:@selector(checkEvent:) andReturn:theValue(YES)];
                [eventCountByKeyHelper stub:@selector(getCountForKey:) andReturn:theValue(4)];
                [boundMappingChecker stub:@selector(check:mappings:) andReturn:@10];
                [eCommerce stub:@selector(type) andReturn:theValue(AMAECommerceEventTypeProductCard)];
            });
            it(@"Should interact with right conditions", ^{
                [[firstEComCondition should] receive:@selector(checkEvent:) withArguments:theValue(AMAECommerceEventTypeProductCard)];
                [[secondEComCondition should] receive:@selector(checkEvent:) withArguments:theValue(AMAECommerceEventTypeProductCard)];
                [[clientCondition shouldNot] receive:@selector(checkEvent:)];
                [[revenueCondition shouldNot] receive:@selector(checkEvent:)];
                [engagement checkAttributionForECommerceEvent:eCommerce];
            });
            it(@"Should interact with eventCountByKeyHelper", ^{
                [[eventCountByKeyHelper should] receive:@selector(getCountForKey:) withArguments:@"engagement"];
                [[eventCountByKeyHelper should] receive:@selector(setCount:forKey:) withArguments:theValue(5), @"engagement"];
                [engagement checkAttributionForECommerceEvent:eCommerce];
            });
            it(@"Should interact with boundMappingChecker", ^{
                [[boundMappingChecker should] receive:@selector(check:mappings:)
                                        withArguments:[NSDecimalNumber decimalNumberWithString:@"5"], boundMappings];
                [engagement checkAttributionForECommerceEvent:eCommerce];
            });
            it(@"Should be 10", ^{
                [[[engagement checkAttributionForECommerceEvent:eCommerce] should] equal:@10];
            });
        });
    });
    context(@"Initial attribution", ^{
        NSArray *boundMappings = @[ [AMABoundMapping nullMock] ];
        beforeEach(^{
            AMAEngagementAttributionModelConfiguration *config =
                [[AMAEngagementAttributionModelConfiguration alloc] initWithEventFilters:@[]
                                                                           boundMappings:boundMappings];
            engagement = [[AMAEngagementAttributionModel alloc] initWithConfig:config
                                                         eventCountByKeyHelper:eventCountByKeyHelper
                                                           boundMappingChecker:boundMappingChecker];
        });
        it(@"Should ask boundMappingChecker", ^{
            [[boundMappingChecker should] receive:@selector(check:mappings:) withArguments:[NSDecimalNumber zero], boundMappings];
            [engagement checkInitialAttribution];
        });
        it(@"Should be nil", ^{
            [boundMappingChecker stub:@selector(check:mappings:) andReturn:nil];
            [[[engagement checkInitialAttribution] should] beNil];
        });
        it(@"Should be 10", ^{
            [boundMappingChecker stub:@selector(check:mappings:) andReturn:@10];
            [[[engagement checkInitialAttribution] should] equal:@10];
        });
    });
});

SPEC_END
