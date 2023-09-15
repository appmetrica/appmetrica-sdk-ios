
#import <Kiwi/Kiwi.h>
#import "AMACore.h"
#import "AMARevenueAttributionModel.h"
#import "AMABoundMapping.h"
#import "AMAEventFilter.h"
#import "AMACurrencyMapping.h"
#import "AMARevenueAttributionModelConfiguration.h"
#import "AMAEventSumBoundBasedModelHelper.h"
#import "AMARevenueEventCondition.h"
#import "AMAECommerceEventCondition.h"
#import "AMAEventTypes.h"
#import "AMAECommerce+Internal.h"
#import "AMALightRevenueEvent.h"
#import "AMALightECommerceEvent.h"

SPEC_BEGIN(AMARevenueAttributionModelTests)

describe(@"AMARevenueAttributionModel", ^{

    AMAEventSumBoundBasedModelHelper *__block eventSumBoundBasedModelHelper = nil;
    AMARevenueAttributionModel *__block model = nil;
    AMARevenueAttributionModelConfiguration *__block config = nil;
    NSArray *__block boundMappings = nil;
    AMARevenueEventCondition *__block firstRevenueEventCondition = nil;
    AMARevenueEventCondition *__block secondRevenueEventCondition = nil;
    AMARevenueEventCondition *__block thirdRevenueEventCondition = nil;
    AMARevenueEventCondition *__block fourthRevenueEventCondition = nil;
    AMAECommerceEventCondition *__block firstEComEventCondition = nil;
    AMAECommerceEventCondition *__block secondEComEventCondition = nil;
    AMAECommerceEventCondition *__block thirdEComEventCondition = nil;
    AMAECommerceEventCondition *__block fourthEComEventCondition = nil;
    AMACurrencyMapping *__block currencyMapping = nil;

    beforeEach(^{
        eventSumBoundBasedModelHelper = [AMAEventSumBoundBasedModelHelper nullMock];
        boundMappings = @[ [AMABoundMapping nullMock] ];
        firstRevenueEventCondition = [AMARevenueEventCondition nullMock];
        secondRevenueEventCondition = [AMARevenueEventCondition nullMock];
        thirdRevenueEventCondition = [AMARevenueEventCondition nullMock];
        fourthRevenueEventCondition = [AMARevenueEventCondition nullMock];
        firstEComEventCondition = [AMAECommerceEventCondition nullMock];
        secondEComEventCondition = [AMAECommerceEventCondition nullMock];
        thirdEComEventCondition = [AMAECommerceEventCondition nullMock];
        fourthEComEventCondition = [AMAECommerceEventCondition nullMock];
        AMAEventFilter *firstFilter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeRevenue
                                                           clientEventCondition:nil
                                                        eCommerceEventCondition:firstEComEventCondition
                                                          revenueEventCondition:firstRevenueEventCondition];
        AMAEventFilter *secondFilter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeRevenue
                                                            clientEventCondition:nil
                                                         eCommerceEventCondition:secondEComEventCondition
                                                           revenueEventCondition:secondRevenueEventCondition];
        AMAEventFilter *thirdFilter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeECommerce
                                                           clientEventCondition:nil
                                                        eCommerceEventCondition:thirdEComEventCondition
                                                          revenueEventCondition:thirdRevenueEventCondition];
        AMAEventFilter *fourthFilter = [[AMAEventFilter alloc] initWithEventType:AMAEventTypeECommerce
                                                            clientEventCondition:nil
                                                         eCommerceEventCondition:fourthEComEventCondition
                                                           revenueEventCondition:fourthRevenueEventCondition];

        currencyMapping = [AMACurrencyMapping nullMock];
        config = [[AMARevenueAttributionModelConfiguration alloc] initWithBoundMappings:boundMappings
                                                                                 events:@[ firstFilter, secondFilter, thirdFilter, fourthFilter ]
                                                                        currencyMapping:currencyMapping];
    });

    context(@"Initial attribution", ^{
        beforeEach(^{
            model = [[AMARevenueAttributionModel alloc] initWithConfig:config
                                         eventSumBoundBasedModelHelper:eventSumBoundBasedModelHelper];
        });
        it(@"Nil config", ^{
            model = [[AMARevenueAttributionModel alloc] initWithConfig:nil eventSumBoundBasedModelHelper:eventSumBoundBasedModelHelper];
            [eventSumBoundBasedModelHelper stub:@selector(calculateNewConversionValue:boundMappings:) andReturn:@10];
            [[eventSumBoundBasedModelHelper should] receive:@selector(calculateNewConversionValue:boundMappings:)
                                              withArguments:[NSDecimalNumber zero], nil];
            [[[model checkInitialAttribution] should] equal:@10];
        });
        it(@"Should ask eventSumBoundBasedModelHelper", ^{
            [[eventSumBoundBasedModelHelper should] receive:@selector(calculateNewConversionValue:boundMappings:)
                                              withArguments:[NSDecimalNumber zero], boundMappings];
            [model checkInitialAttribution];
        });
        it(@"Should be nil", ^{
            [eventSumBoundBasedModelHelper stub:@selector(calculateNewConversionValue:boundMappings:) andReturn:nil];
            [[[model checkInitialAttribution] should] beNil];
        });
        it(@"Should be 10", ^{
            [eventSumBoundBasedModelHelper stub:@selector(calculateNewConversionValue:boundMappings:) andReturn:@10];
            [[[model checkInitialAttribution] should] equal:@10];
        });
    });
    context(@"Revenue attribution", ^{
        AMALightRevenueEvent *__block revenue = nil;
        beforeEach(^{
            model = [[AMARevenueAttributionModel alloc] initWithConfig:config
                                         eventSumBoundBasedModelHelper:eventSumBoundBasedModelHelper];
        });
        context(@"Nil config", ^{
            beforeEach(^{
                model = [[AMARevenueAttributionModel alloc] initWithConfig:nil
                                             eventSumBoundBasedModelHelper:eventSumBoundBasedModelHelper];
                revenue = [[AMALightRevenueEvent alloc] initWithPriceMicros:[NSDecimalNumber decimalNumberWithString:@"333"]
                                                                   currency:@"USD"
                                                                   quantity:1
                                                              transactionID:@"a"
                                                                     isAuto:NO
                                                                  isRestore:NO];
            });
            it(@"Should be nil", ^{
                NSNumber *result = [model checkAttributionForRevenueEvent:revenue];
                [[result should] beNil];
            });
            it(@"Should not interact with eventSumBoundBasedModelHelper", ^{
                [[eventSumBoundBasedModelHelper shouldNot] receive:@selector(calculateNewConversionValue:boundMappings:)];
                [model checkAttributionForRevenueEvent:revenue];
            });
        });
        context(@"No match", ^{
            beforeEach(^{
                [firstRevenueEventCondition stub:@selector(checkEvent:) andReturn:theValue(NO)];
                [secondRevenueEventCondition stub:@selector(checkEvent:) andReturn:theValue(NO)];
                revenue = [[AMALightRevenueEvent alloc] initWithPriceMicros:[NSDecimalNumber decimalNumberWithString:@"333"]
                                                                   currency:@"USD"
                                                                   quantity:1
                                                              transactionID:@"a"
                                                                     isAuto:NO
                                                                  isRestore:NO];
            });
            it(@"Should be nil", ^{
                NSNumber *result = [model checkAttributionForRevenueEvent:revenue];
                [[result should] beNil];
            });
            it(@"Should ask right conditions", ^{
                [[firstRevenueEventCondition should] receive:@selector(checkEvent:) withArguments:theValue(NO)];
                [[secondRevenueEventCondition should] receive:@selector(checkEvent:) withArguments:theValue(NO)];
                [[thirdRevenueEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[fourthRevenueEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[firstEComEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[secondEComEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[thirdEComEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[fourthEComEventCondition shouldNot] receive:@selector(checkEvent:)];
                [model checkAttributionForRevenueEvent:revenue];
            });
            it(@"Should not interact with eventSumBoundBasedModelHelper", ^{
                [[eventSumBoundBasedModelHelper shouldNot] receive:@selector(calculateNewConversionValue:boundMappings:)];
                [model checkAttributionForRevenueEvent:revenue];
            });
        });
        context(@"First match", ^{
            beforeEach(^{
                [firstRevenueEventCondition stub:@selector(checkEvent:) andReturn:theValue(YES)];
                [secondRevenueEventCondition stub:@selector(checkEvent:) andReturn:theValue(NO)];
                revenue = [[AMALightRevenueEvent alloc] initWithPriceMicros:[NSDecimalNumber decimalNumberWithString:@"333"]
                                                                   currency:@"USD"
                                                                   quantity:2
                                                              transactionID:@"a"
                                                                     isAuto:NO
                                                                  isRestore:NO];
            });
            it(@"Should ask right conditions", ^{
                [[firstRevenueEventCondition should] receive:@selector(checkEvent:) withArguments:theValue(NO)];
                [[secondRevenueEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[thirdRevenueEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[fourthRevenueEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[firstEComEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[secondEComEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[thirdEComEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[fourthEComEventCondition shouldNot] receive:@selector(checkEvent:)];
                [model checkAttributionForRevenueEvent:revenue];
            });
            it(@"Should pass correct arguments to currencyMapping", ^{
                [[currencyMapping should] receive:@selector(convert:currency:scale:error:)
                                    withArguments:[NSDecimalNumber decimalNumberWithString:@"666"], @"USD", theValue(1), kw_any()];
                [model checkAttributionForRevenueEvent:revenue];
            });
            it(@"Should pass correct arguments to eventSumBoundBasedModelHelper", ^{
                NSDecimalNumber *converted = [NSDecimalNumber decimalNumberWithString:@"123"];
                [currencyMapping stub:@selector(convert:currency:scale:error:) andReturn:converted];
                [[eventSumBoundBasedModelHelper should] receive:@selector(calculateNewConversionValue:boundMappings:)
                                                  withArguments:converted, boundMappings];
                [model checkAttributionForRevenueEvent:revenue];
            });
            it(@"Should use safe multiplication", ^{
                NSDecimalNumber *price = [NSDecimalNumber decimalNumberWithString:@"333"];
                [[AMADecimalUtils should] receive:@selector(decimalNumber:bySafelyMultiplyingBy:or:)
                                    withArguments:price, [NSDecimalNumber decimalNumberWithString:@"2"], [NSDecimalNumber zero]];
                [model checkAttributionForRevenueEvent:revenue];
            });
            it(@"Should return valid value", ^{
                NSDecimalNumber *converted = [NSDecimalNumber decimalNumberWithString:@"123"];
                [currencyMapping stub:@selector(convert:currency:scale:error:) andReturn:converted];
                [eventSumBoundBasedModelHelper stub:@selector(calculateNewConversionValue:boundMappings:) andReturn:@10];
                NSNumber *result = [model checkAttributionForRevenueEvent:revenue];
                [[result should] equal:@10];
            });
        });
        context(@"Second match", ^{
            beforeEach(^{
                [firstRevenueEventCondition stub:@selector(checkEvent:) andReturn:theValue(NO)];
                [secondRevenueEventCondition stub:@selector(checkEvent:) andReturn:theValue(YES)];
                revenue = [[AMALightRevenueEvent alloc] initWithPriceMicros:[NSDecimalNumber decimalNumberWithString:@"333"]
                                                                   currency:@"USD"
                                                                   quantity:2
                                                              transactionID:@"a"
                                                                     isAuto:NO
                                                                  isRestore:NO];
            });
            it(@"Should ask right conditions", ^{
                [[firstRevenueEventCondition should] receive:@selector(checkEvent:) withArguments:theValue(NO)];
                [[secondRevenueEventCondition should] receive:@selector(checkEvent:) withArguments:theValue(NO)];
                [[thirdRevenueEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[fourthRevenueEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[firstEComEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[secondEComEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[thirdEComEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[fourthEComEventCondition shouldNot] receive:@selector(checkEvent:)];
                [model checkAttributionForRevenueEvent:revenue];
            });
            it(@"Should return valid value", ^{
                NSDecimalNumber *converted = [NSDecimalNumber decimalNumberWithString:@"123"];
                [currencyMapping stub:@selector(convert:currency:scale:error:) andReturn:converted];
                [eventSumBoundBasedModelHelper stub:@selector(calculateNewConversionValue:boundMappings:) andReturn:@10];
                NSNumber *result = [model checkAttributionForRevenueEvent:revenue];
                [[result should] equal:@10];
            });
        });
    });
    context(@"E-commerce attribution", ^{
        AMALightECommerceEvent *__block event = nil;
        beforeEach(^{
            model = [[AMARevenueAttributionModel alloc] initWithConfig:config
                                         eventSumBoundBasedModelHelper:eventSumBoundBasedModelHelper];
        });
        context(@"Nil config", ^{
            beforeEach(^{
                model = [[AMARevenueAttributionModel alloc] initWithConfig:nil
                                             eventSumBoundBasedModelHelper:eventSumBoundBasedModelHelper];
                event = [[AMALightECommerceEvent alloc] initWithType:AMAECommerceEventTypeScreen
                                                             amounts:@[]
                                                             isFirst:YES];
            });
            it(@"Should be nil", ^{
                NSNumber *result = [model checkAttributionForECommerceEvent:event];
                [[result should] beNil];
            });
            it(@"Should not interact with eventSumBoundBasedModelHelper", ^{
                [[eventSumBoundBasedModelHelper shouldNot] receive:@selector(calculateNewConversionValue:boundMappings:)];
                [model checkAttributionForECommerceEvent:event];
            });
        });
        context(@"No match", ^{
            beforeEach(^{
                [thirdEComEventCondition stub:@selector(checkEvent:) andReturn:theValue(NO)];
                [fourthEComEventCondition stub:@selector(checkEvent:) andReturn:theValue(NO)];
                event = [[AMALightECommerceEvent alloc] initWithType:AMAECommerceEventTypeScreen
                                                             amounts:@[]
                                                             isFirst:YES];
            });
            it(@"Should be nil", ^{
                NSNumber *result = [model checkAttributionForECommerceEvent:event];
                [[result should] beNil];
            });
            it(@"Should ask right conditions", ^{
                [[firstRevenueEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[secondRevenueEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[thirdRevenueEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[fourthRevenueEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[firstEComEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[secondEComEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[thirdEComEventCondition should] receive:@selector(checkEvent:) withArguments:theValue(AMAECommerceEventTypeScreen)];
                [[fourthEComEventCondition should] receive:@selector(checkEvent:) withArguments:theValue(AMAECommerceEventTypeScreen)];
                [model checkAttributionForECommerceEvent:event];
            });
            it(@"Should not interact with eventSumBoundBasedModelHelper", ^{
                [[eventSumBoundBasedModelHelper shouldNot] receive:@selector(calculateNewConversionValue:boundMappings:)];
                [model checkAttributionForECommerceEvent:event];
            });
        });
        context(@"First match", ^{
            beforeEach(^{
                [thirdEComEventCondition stub:@selector(checkEvent:) andReturn:theValue(YES)];
                [fourthEComEventCondition stub:@selector(checkEvent:) andReturn:theValue(NO)];
            });
            it(@"Should ask right conditions", ^{
                [[firstRevenueEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[secondRevenueEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[thirdRevenueEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[fourthRevenueEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[firstEComEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[secondEComEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[thirdEComEventCondition should] receive:@selector(checkEvent:) withArguments:theValue(AMAECommerceEventTypeScreen)];
                [[fourthEComEventCondition shouldNot] receive:@selector(checkEvent:)];
                event = [[AMALightECommerceEvent alloc] initWithType:AMAECommerceEventTypeScreen
                                                             amounts:@[]
                                                             isFirst:YES];

                [model checkAttributionForECommerceEvent:event];
            });
            it(@"Should pass correct arguments to currencyMapping", ^{
                NSDecimalNumber *firstValue = [NSDecimalNumber decimalNumberWithString:@"456"];
                NSDecimalNumber *secondValue = [NSDecimalNumber decimalNumberWithString:@"8787"];
                event = [[AMALightECommerceEvent alloc] initWithType:AMAECommerceEventTypeScreen
                                                             amounts:@[
                                                                 [[AMAECommerceAmount alloc] initWithUnit:@"USD" value:firstValue],
                                                                 [[AMAECommerceAmount alloc] initWithUnit:@"BYN" value:secondValue]
                                                             ]
                                                             isFirst:YES];
                [[currencyMapping should] receive:@selector(convert:currency:scale:error:)
                                    withArguments:firstValue, @"USD", theValue(1000000), kw_any()];
                [[currencyMapping should] receive:@selector(convert:currency:scale:error:)
                                    withArguments:secondValue, @"BYN", theValue(1000000), kw_any()];
                [model checkAttributionForECommerceEvent:event];
            });
            context(@"Should pass correct arguments to eventSumBoundBasedModelHelper", ^{
                it(@"Empty list", ^{
                    [[eventSumBoundBasedModelHelper should] receive:@selector(calculateNewConversionValue:boundMappings:)
                                                      withArguments:[NSDecimalNumber zero], boundMappings];
                    event = [[AMALightECommerceEvent alloc] initWithType:AMAECommerceEventTypeScreen
                                                                 amounts:@[]
                                                                 isFirst:YES];
                    [model checkAttributionForECommerceEvent:event];
                });
                it(@"Single element", ^{
                    NSDecimalNumber *firstValue = [NSDecimalNumber decimalNumberWithString:@"456"];
                    [currencyMapping stub:@selector(convert:currency:scale:error:) andReturn:[NSDecimalNumber decimalNumberWithString:@"66"]
                            withArguments:firstValue, @"USD", theValue(1000000), kw_any()];
                    [[eventSumBoundBasedModelHelper should] receive:@selector(calculateNewConversionValue:boundMappings:)
                                                      withArguments:[NSDecimalNumber decimalNumberWithString:@"66"], boundMappings];
                    event = [[AMALightECommerceEvent alloc] initWithType:AMAECommerceEventTypeScreen
                                                                 amounts:@[ [[AMAECommerceAmount alloc] initWithUnit:@"USD" value:firstValue] ]
                                                                 isFirst:YES];
                    [model checkAttributionForECommerceEvent:event];
                });
                it(@"Multiple elements", ^{
                    NSDecimalNumber *firstValue = [NSDecimalNumber decimalNumberWithString:@"456"];
                    NSDecimalNumber *secondValue = [NSDecimalNumber decimalNumberWithString:@"8787"];
                    [currencyMapping stub:@selector(convert:currency:scale:error:) andReturn:[NSDecimalNumber decimalNumberWithString:@"66"]
                                        withArguments:firstValue, @"USD", theValue(1000000), kw_any()];
                    [currencyMapping stub:@selector(convert:currency:scale:error:) andReturn:[NSDecimalNumber decimalNumberWithString:@"22"]
                                        withArguments:secondValue, @"BYN", theValue(1000000), kw_any()];
                    [[eventSumBoundBasedModelHelper should] receive:@selector(calculateNewConversionValue:boundMappings:)
                                                      withArguments:[NSDecimalNumber decimalNumberWithString:@"88"], boundMappings];
                    event = [[AMALightECommerceEvent alloc] initWithType:AMAECommerceEventTypeScreen
                                                                 amounts:@[
                                                                     [[AMAECommerceAmount alloc] initWithUnit:@"USD" value:firstValue],
                                                                     [[AMAECommerceAmount alloc] initWithUnit:@"BYN" value:secondValue]
                                                                 ]
                                                                 isFirst:YES];
                    [model checkAttributionForECommerceEvent:event];
                });
            });
            it(@"Should use safe addition", ^{
                NSDecimalNumber *firstConverted = [NSDecimalNumber decimalNumberWithString:@"11"];
                NSDecimalNumber *secondConverted = [NSDecimalNumber decimalNumberWithString:@"22"];
                NSDecimalNumber *firstValue = [NSDecimalNumber decimalNumberWithString:@"111"];
                NSDecimalNumber *secondValue = [NSDecimalNumber decimalNumberWithString:@"222"];
                [currencyMapping stub:@selector(convert:currency:scale:error:) andReturn:firstConverted
                        withArguments:firstValue, @"USD", theValue(1000000), kw_any()];
                [currencyMapping stub:@selector(convert:currency:scale:error:) andReturn:secondConverted
                        withArguments:secondValue, @"BYN", theValue(1000000), kw_any()];
                [AMADecimalUtils stub:@selector(decimalNumber:bySafelyAdding:or:) andReturn:firstConverted];
                [[AMADecimalUtils should] receive:@selector(decimalNumber:bySafelyAdding:or:)
                                    withArguments:[NSDecimalNumber zero], firstConverted, [NSDecimalNumber zero]];
                [[AMADecimalUtils should] receive:@selector(decimalNumber:bySafelyAdding:or:)
                                    withArguments:firstConverted, secondConverted, firstConverted];
                event = [[AMALightECommerceEvent alloc] initWithType:AMAECommerceEventTypeScreen
                                                             amounts:@[
                                                                 [[AMAECommerceAmount alloc] initWithUnit:@"USD" value:firstValue],
                                                                 [[AMAECommerceAmount alloc] initWithUnit:@"BYN" value:secondValue]
                                                             ]
                                                             isFirst:YES];
                [model checkAttributionForECommerceEvent:event];
            });
            it(@"Should return valid value", ^{
                NSDecimalNumber *firstValue = [NSDecimalNumber decimalNumberWithString:@"456"];
                NSDecimalNumber *secondValue = [NSDecimalNumber decimalNumberWithString:@"8787"];
                [currencyMapping stub:@selector(convert:currency:scale:error:) andReturn:[NSDecimalNumber decimalNumberWithString:@"66"]
                        withArguments:firstValue, @"USD", theValue(1000000), kw_any()];
                [currencyMapping stub:@selector(convert:currency:scale:error:) andReturn:[NSDecimalNumber decimalNumberWithString:@"22"]
                        withArguments:secondValue, @"BYN", theValue(1000000), kw_any()];
                [eventSumBoundBasedModelHelper stub:@selector(calculateNewConversionValue:boundMappings:) andReturn:@13];
                event = [[AMALightECommerceEvent alloc] initWithType:AMAECommerceEventTypeScreen
                                                             amounts:@[
                                                                 [[AMAECommerceAmount alloc] initWithUnit:@"USD" value:firstValue],
                                                                 [[AMAECommerceAmount alloc] initWithUnit:@"BYN" value:secondValue]
                                                             ]
                                                             isFirst:YES];
                NSNumber *result = [model checkAttributionForECommerceEvent:event];
                [[result should] equal:@13];
            });
        });
        context(@"Second match", ^{
            beforeEach(^{
                [thirdEComEventCondition stub:@selector(checkEvent:) andReturn:theValue(NO)];
                [fourthEComEventCondition stub:@selector(checkEvent:) andReturn:theValue(YES)];
            });
            it(@"Should ask right conditions", ^{
                [[firstRevenueEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[secondRevenueEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[thirdRevenueEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[fourthRevenueEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[firstEComEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[secondEComEventCondition shouldNot] receive:@selector(checkEvent:)];
                [[thirdEComEventCondition should] receive:@selector(checkEvent:) withArguments:theValue(AMAECommerceEventTypeScreen)];
                [[fourthEComEventCondition should] receive:@selector(checkEvent:) withArguments:theValue(AMAECommerceEventTypeScreen)];
                event = [[AMALightECommerceEvent alloc] initWithType:AMAECommerceEventTypeScreen
                                                             amounts:@[]
                                                             isFirst:YES];
                [model checkAttributionForECommerceEvent:event];
            });
            it(@"Should return valid value", ^{
                NSDecimalNumber *firstValue = [NSDecimalNumber decimalNumberWithString:@"456"];
                NSDecimalNumber *secondValue = [NSDecimalNumber decimalNumberWithString:@"8787"];
                [currencyMapping stub:@selector(convert:currency:scale:error:) andReturn:[NSDecimalNumber decimalNumberWithString:@"66"]
                        withArguments:firstValue, @"USD", theValue(1000000), kw_any()];
                [currencyMapping stub:@selector(convert:currency:scale:error:) andReturn:[NSDecimalNumber decimalNumberWithString:@"22"]
                        withArguments:secondValue, @"BYN", theValue(1000000), kw_any()];
                [eventSumBoundBasedModelHelper stub:@selector(calculateNewConversionValue:boundMappings:) andReturn:@13];
                event = [[AMALightECommerceEvent alloc] initWithType:AMAECommerceEventTypeScreen
                                                             amounts:@[
                                                                 [[AMAECommerceAmount alloc] initWithUnit:@"USD" value:firstValue],
                                                                 [[AMAECommerceAmount alloc] initWithUnit:@"BYN" value:secondValue]
                                                             ]
                                                             isFirst:YES];
                NSNumber *result = [model checkAttributionForECommerceEvent:event];
                [[result should] equal:@13];
            });
        });
    });
    
    it(@"Should conform to AMAAttributionModel", ^{
        AMARevenueAttributionModel *model = [[AMARevenueAttributionModel alloc] init];
        [[model should] conformToProtocol:@protocol(AMAAttributionModel)];
    });
});

SPEC_END
