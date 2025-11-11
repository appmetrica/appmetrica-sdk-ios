
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAECommerceSerializer.h"
#import "AMARevenueInfoModelSerializer.h"
#import "AMAConversionAttributionModel.h"
#import "AMARevenueAttributionModel.h"
#import "AMAEngagementAttributionModel.h"
#import "AMAAttributionChecker.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMASKAdNetworkRequestor.h"
#import "AMAMetricaConfiguration.h"
#import "AMAAttributionModelConfiguration.h"
#import "AMAEvent.h"
#import "AMARevenueInfo.h"
#import "AMAEventValueProtocol.h"
#import "AMARevenueInfoModel.h"
#import "AMATransactionInfoModel.h"
#import "AMABinaryEventValue.h"
#import "AMARevenueDeduplicator.h"
#import "AMALightRevenueEvent.h"
#import "AMALightRevenueEventConverter.h"
#import "AMALightECommerceEventConverter.h"
#import "AMALightECommerceEvent.h"
#import "AMAReporter.h"

SPEC_BEGIN(AMAAttributionCheckerTests)

describe(@"AMAAttributionChecker", ^{

    AMAAttributionModelConfiguration *__block config = nil;
    id __block attributionModel = nil;
    AMAMetricaPersistentConfiguration *__block persistentConfiguration = nil;
    AMASKAdNetworkRequestor *__block skadNetworkRequestor = nil;
    AMAAttributionChecker *__block delegate = nil;
    AMARevenueDeduplicator *__block revenueDeduplicator = nil;
    AMALightRevenueEventConverter *__block lightRevenueEventConverter = nil;
    AMALightECommerceEventConverter *__block lightECommerceEventConverter = nil;
    AMAReporter *__block reporter = nil;

    beforeEach(^{
        attributionModel = [KWMock nullMockForProtocol:@protocol(AMAAttributionModel)];
        persistentConfiguration = [AMAMetricaPersistentConfiguration nullMock];
        skadNetworkRequestor = [AMASKAdNetworkRequestor nullMock];
        config = [AMAAttributionModelConfiguration nullMock];
        reporter = [AMAReporter nullMock];
        revenueDeduplicator = [AMARevenueDeduplicator nullMock];
        lightRevenueEventConverter = [AMALightRevenueEventConverter nullMock];
        lightECommerceEventConverter = [AMALightECommerceEventConverter nullMock];
        [AMASKAdNetworkRequestor stub:@selector(sharedInstance) andReturn:skadNetworkRequestor];
        AMAMetricaConfiguration *metricaConfiguration = [AMAMetricaConfiguration nullMock];
        [metricaConfiguration stub:@selector(persistent) andReturn:persistentConfiguration];
        [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:metricaConfiguration];
        delegate = [[AMAAttributionChecker alloc] initWithConfig:config
                                                        reporter:reporter
                                                attributionModel:attributionModel
                                             revenueDeduplicator:revenueDeduplicator
                                    lightECommerceEventConverter:lightECommerceEventConverter
                                      lightRevenueEventConverter:lightRevenueEventConverter];
    });
    afterEach(^{
        [AMASKAdNetworkRequestor clearStubs];
        [AMAMetricaConfiguration clearStubs];
    });

    context(@"Client event", ^{
        NSString *eventName = @"some event name";
        it(@"Should pass to model", ^{
            [[attributionModel should] receive:@selector(checkAttributionForClientEvent:) withArguments:eventName];
            [delegate checkClientEventAttribution:eventName];
        });
        context(@"Old value is nil", ^{
            beforeEach(^{
                [persistentConfiguration stub:@selector(conversionValue) andReturn:nil];
            });
            it(@"Should update if non nil", ^{
                NSNumber *newValue = @23;
                [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:newValue];
                [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                [delegate checkClientEventAttribution:eventName];
            });
            it(@"Should not update if nil", ^{
                [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:nil];
                [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                [delegate checkClientEventAttribution:eventName];
            });
            it(@"Should update if zero", ^{
                NSNumber *newValue = @0;
                [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:newValue];
                [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                [delegate checkClientEventAttribution:eventName];
            });
            it(@"Should send event if updated", ^{
                NSNumber *newValue = @23;
                [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(YES)];
                [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:newValue];
                [[reporter should] receive:@selector(reportAttributionEventWithName:value:)
                             withArguments:@"conversion_value_update", @{ @"new_value" : newValue }];
                [delegate checkClientEventAttribution:eventName];
            });
            it(@"Should not send event if not updated", ^{
                NSNumber *newValue = @23;
                [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(NO)];
                [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:newValue];
                [[reporter shouldNot] receive:@selector(reportAttributionEventWithName:value:)];
                [delegate checkClientEventAttribution:eventName];
            });
        });
        context(@"Old value is not nil", ^{
            beforeEach(^{
                [persistentConfiguration stub:@selector(conversionValue) andReturn:@12];
            });
            it(@"Should not update if nil", ^{
                NSNumber *newValue = @23;
                [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:newValue];
                [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                [delegate checkClientEventAttribution:eventName];
            });
            it(@"Should not update if nil", ^{
                [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:nil];
                [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                [delegate checkClientEventAttribution:eventName];
            });
            it(@"Should update if zero", ^{
                NSNumber *newValue = @0;
                [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:newValue];
                [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                [delegate checkClientEventAttribution:eventName];
            });
            it(@"Should update if zero and old value is zero", ^{
                [persistentConfiguration stub:@selector(conversionValue) andReturn:@0];
                NSNumber *newValue = @0;
                [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:newValue];
                [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                [delegate checkClientEventAttribution:eventName];
            });
            it(@"Should not update if value is the same", ^{
                NSNumber *newValue = @12;
                [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:newValue];
                [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                [delegate checkClientEventAttribution:eventName];
            });
            it(@"Should send event if updated", ^{
                NSNumber *newValue = @23;
                [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(YES)];
                [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:newValue];
                [[reporter should] receive:@selector(reportAttributionEventWithName:value:)
                             withArguments:@"conversion_value_update", @{ @"old_value" : @12, @"new_value" : newValue }];
                [delegate checkClientEventAttribution:eventName];
            });
            it(@"Should not send event if not updated", ^{
                NSNumber *newValue = @23;
                [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(NO)];
                [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:newValue];
                [[reporter shouldNot] receive:@selector(reportAttributionEventWithName:value:)];
                [delegate checkClientEventAttribution:eventName];
            });
        });
    });
    context(@"Revenue event", ^{
        AMARevenueInfoModel *__block revenue = nil;
        AMALightRevenueEvent *__block lightEvent = nil;
        beforeEach(^{
            [revenueDeduplicator stub:@selector(checkForID:) andReturn:theValue(YES)];
            revenue = [AMARevenueInfoModel nullMock];
            lightEvent = [AMALightRevenueEvent nullMock];
            [lightRevenueEventConverter stub:@selector(eventFromModel:) andReturn:lightEvent];
        });
        it(@"Should pass to model", ^{
            [[attributionModel should] receive:@selector(checkAttributionForRevenueEvent:) withArguments:lightEvent];
            [delegate checkRevenueEventAttribution:revenue];
        });
        it(@"Should convert", ^{
            [[lightRevenueEventConverter should] receive:@selector(eventFromModel:) withArguments:revenue];
            [delegate checkRevenueEventAttribution:revenue];
        });
        context(@"Deduplication", ^{
            NSString *transactionID = @"some id";
            beforeEach(^{
                [lightEvent stub:@selector(transactionID) andReturn:transactionID];
            });
            it(@"Should pass to revenue deduplicator", ^{
                [[revenueDeduplicator should] receive:@selector(checkForID:) withArguments:transactionID];
                [delegate checkRevenueEventAttribution:revenue];
            });
            it(@"Should pass to model if unique", ^{
                [revenueDeduplicator stub:@selector(checkForID:) andReturn:theValue(YES)];
                [[attributionModel should] receive:@selector(checkAttributionForRevenueEvent:) withArguments:lightEvent];
                [delegate checkRevenueEventAttribution:revenue];
            });
            it(@"Should not pass to model if duplicate", ^{
                [revenueDeduplicator stub:@selector(checkForID:) andReturn:theValue(NO)];
                [[attributionModel shouldNot] receive:@selector(checkAttributionForRevenueEvent:)];
                [delegate checkRevenueEventAttribution:revenue];
            });
        });
        context(@"Restore", ^{
            it(@"Should pass to model if not restored", ^{
                [lightEvent stub:@selector(isRestore) andReturn:theValue(NO)];
                [[attributionModel should] receive:@selector(checkAttributionForRevenueEvent:) withArguments:lightEvent];
                [delegate checkRevenueEventAttribution:revenue];
            });
            it(@"Should not pass to model if restored", ^{
                [lightEvent stub:@selector(isRestore) andReturn:theValue(YES)];
                [[attributionModel shouldNot] receive:@selector(checkAttributionForRevenueEvent:)];
                [delegate checkRevenueEventAttribution:revenue];
            });
        });
        context(@"Old value is nil", ^{
            beforeEach(^{
                [persistentConfiguration stub:@selector(conversionValue) andReturn:nil];
            });
            it(@"Should update if non nil", ^{
                NSNumber *newValue = @23;
                [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:newValue];
                [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                [delegate checkRevenueEventAttribution:revenue];
            });
            it(@"Should not update if nil", ^{
                [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:nil];
                [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                [delegate checkRevenueEventAttribution:revenue];
            });
            it(@"Should update if zero", ^{
                NSNumber *newValue = @0;
                [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:newValue];
                [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                [delegate checkRevenueEventAttribution:revenue];
            });
            it(@"Should send event if updated", ^{
                NSNumber *newValue = @23;
                [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(YES)];
                [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:newValue];
                [[reporter should] receive:@selector(reportAttributionEventWithName:value:)
                             withArguments:@"conversion_value_update", @{ @"new_value" : newValue }];
                [delegate checkRevenueEventAttribution:revenue];
            });
            it(@"Should not send event if not updated", ^{
                NSNumber *newValue = @23;
                [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(NO)];
                [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:newValue];
                [[reporter shouldNot] receive:@selector(reportAttributionEventWithName:value:)];
                [delegate checkRevenueEventAttribution:revenue];
            });
        });
        context(@"Old value is not nil", ^{
            beforeEach(^{
                [persistentConfiguration stub:@selector(conversionValue) andReturn:@12];
            });
            it(@"Should not update if nil", ^{
                NSNumber *newValue = @23;
                [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:newValue];
                [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                [delegate checkRevenueEventAttribution:revenue];
            });
            it(@"Should not update if nil", ^{
                [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:nil];
                [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                [delegate checkRevenueEventAttribution:revenue];
            });
            it(@"Should update if zero", ^{
                NSNumber *newValue = @0;
                [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:newValue];
                [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                [delegate checkRevenueEventAttribution:revenue];
            });
            it(@"Should update if zero and old value is zero", ^{
                [persistentConfiguration stub:@selector(conversionValue) andReturn:@0];
                NSNumber *newValue = @0;
                [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:newValue];
                [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                [delegate checkRevenueEventAttribution:revenue];
            });
            it(@"Should not update if value is the same", ^{
                NSNumber *newValue = @12;
                [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:newValue];
                [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                [delegate checkRevenueEventAttribution:revenue];
            });
            it(@"Should send event if updated", ^{
                NSNumber *newValue = @23;
                [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(YES)];
                [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:newValue];
                [[reporter should] receive:@selector(reportAttributionEventWithName:value:)
                             withArguments:@"conversion_value_update", @{ @"old_value" : @12, @"new_value" : newValue }];
                [delegate checkRevenueEventAttribution:revenue];
            });
            it(@"Should not send event if not updated", ^{
                NSNumber *newValue = @23;
                [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(NO)];
                [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:newValue];
                [[reporter shouldNot] receive:@selector(reportAttributionEventWithName:value:)];
                [delegate checkRevenueEventAttribution:revenue];
            });
        });
    });
    context(@"E-commerce event", ^{
        AMALightECommerceEvent *__block lightEvent = nil;
        AMAECommerce *__block eCommerce = nil;
        beforeEach(^{
            eCommerce = [AMAECommerce nullMock];
            lightEvent = [AMALightECommerceEvent nullMock];
            [lightECommerceEventConverter stub:@selector(eventFromModel:) andReturn:lightEvent];
        });
        it(@"Should pass to model", ^{
            [[attributionModel should] receive:@selector(checkAttributionForECommerceEvent:) withArguments:lightEvent];
            [delegate checkECommerceEventAttribution:eCommerce];
        });
        it(@"Should convert", ^{
            [[lightECommerceEventConverter should] receive:@selector(eventFromModel:) withArguments:eCommerce];
            [delegate checkECommerceEventAttribution:eCommerce];
        });
        context(@"Old value is nil", ^{
            beforeEach(^{
                [persistentConfiguration stub:@selector(conversionValue) andReturn:nil];
            });
            it(@"Should update if non nil", ^{
                NSNumber *newValue = @23;
                [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:newValue];
                [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                [delegate checkECommerceEventAttribution:eCommerce];
            });
            it(@"Should not update if nil", ^{
                [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:nil];
                [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                [delegate checkECommerceEventAttribution:eCommerce];
            });
            it(@"Should update if zero", ^{
                NSNumber *newValue = @0;
                [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:newValue];
                [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                [delegate checkECommerceEventAttribution:eCommerce];
            });
            it(@"Should send event if updated", ^{
                NSNumber *newValue = @23;
                [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(YES)];
                [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:newValue];
                [[reporter should] receive:@selector(reportAttributionEventWithName:value:)
                             withArguments:@"conversion_value_update", @{ @"new_value" : newValue }];
                [delegate checkECommerceEventAttribution:eCommerce];
            });
            it(@"Should not send event if not updated", ^{
                NSNumber *newValue = @23;
                [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(NO)];
                [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:newValue];
                [[reporter shouldNot] receive:@selector(reportAttributionEventWithName:value:)];
                [delegate checkECommerceEventAttribution:eCommerce];
            });
        });
        context(@"Old value is not nil", ^{
            beforeEach(^{
                [persistentConfiguration stub:@selector(conversionValue) andReturn:@12];
            });
            it(@"Should not update if nil", ^{
                NSNumber *newValue = @23;
                [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:newValue];
                [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                [delegate checkECommerceEventAttribution:eCommerce];
            });
            it(@"Should not update if nil", ^{
                [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:nil];
                [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                [delegate checkECommerceEventAttribution:eCommerce];
            });
            it(@"Should update if zero", ^{
                NSNumber *newValue = @0;
                [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:newValue];
                [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                [delegate checkECommerceEventAttribution:eCommerce];
            });
            it(@"Should update if zero and old value is zero", ^{
                [persistentConfiguration stub:@selector(conversionValue) andReturn:@0];
                NSNumber *newValue = @0;
                [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:newValue];
                [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                [delegate checkECommerceEventAttribution:eCommerce];
            });
            it(@"Should not update if value is the same", ^{
                NSNumber *newValue = @12;
                [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:newValue];
                [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                [delegate checkECommerceEventAttribution:eCommerce];
            });
            it(@"Should send event if updated", ^{
                NSNumber *newValue = @23;
                [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(YES)];
                [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:newValue];
                [[reporter should] receive:@selector(reportAttributionEventWithName:value:)
                             withArguments:@"conversion_value_update", @{ @"old_value" : @12, @"new_value" : newValue }];
                [delegate checkECommerceEventAttribution:eCommerce];
            });
            it(@"Should not send event if not updated", ^{
                NSNumber *newValue = @23;
                [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(NO)];
                [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:newValue];
                [[reporter shouldNot] receive:@selector(reportAttributionEventWithName:value:)];
                [delegate checkECommerceEventAttribution:eCommerce];
            });
        });
    });
    context(@"Initial attribution", ^{
        it(@"Should pass to model", ^{
            [[attributionModel should] receive:@selector(checkInitialAttribution)];
            [delegate checkInitialAttribution];
        });
        context(@"Old value is nil", ^{
            beforeEach(^{
                [persistentConfiguration stub:@selector(conversionValue) andReturn:nil];
            });
            it(@"Should update if non nil", ^{
                NSNumber *newValue = @23;
                [attributionModel stub:@selector(checkInitialAttribution) andReturn:newValue];
                [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                [delegate checkInitialAttribution];
            });
            it(@"Should not update if nil", ^{
                [attributionModel stub:@selector(checkInitialAttribution) andReturn:nil];
                [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                [delegate checkInitialAttribution];
            });
            it(@"Should update if zero", ^{
                NSNumber *newValue = @0;
                [attributionModel stub:@selector(checkInitialAttribution) andReturn:newValue];
                [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                [delegate checkInitialAttribution];
            });
            it(@"Should send event if updated", ^{
                NSNumber *newValue = @23;
                [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(YES)];
                [attributionModel stub:@selector(checkInitialAttribution) andReturn:newValue];
                [[reporter should] receive:@selector(reportAttributionEventWithName:value:)
                             withArguments:@"conversion_value_update", @{ @"new_value" : newValue }];
                [delegate checkInitialAttribution];
            });
            it(@"Should not send event if not updated", ^{
                NSNumber *newValue = @23;
                [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(NO)];
                [attributionModel stub:@selector(checkInitialAttribution) andReturn:newValue];
                [[reporter shouldNot] receive:@selector(reportAttributionEventWithName:value:)];
                [delegate checkInitialAttribution];
            });
        });
        context(@"Old value is not nil", ^{
            beforeEach(^{
                [persistentConfiguration stub:@selector(conversionValue) andReturn:@12];
            });
            it(@"Should not update if nil", ^{
                NSNumber *newValue = @23;
                [attributionModel stub:@selector(checkInitialAttribution) andReturn:newValue];
                [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                [delegate checkInitialAttribution];
            });
            it(@"Should not update if nil", ^{
                [attributionModel stub:@selector(checkInitialAttribution) andReturn:nil];
                [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                [delegate checkInitialAttribution];
            });
            it(@"Should update if zero", ^{
                NSNumber *newValue = @0;
                [attributionModel stub:@selector(checkInitialAttribution) andReturn:newValue];
                [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                [delegate checkInitialAttribution];
            });
            it(@"Should update if zero and old value is zero", ^{
                [persistentConfiguration stub:@selector(conversionValue) andReturn:@0];
                NSNumber *newValue = @0;
                [attributionModel stub:@selector(checkInitialAttribution) andReturn:newValue];
                [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                [delegate checkInitialAttribution];
            });
            it(@"Should not update if value is the same", ^{
                NSNumber *newValue = @12;
                [attributionModel stub:@selector(checkInitialAttribution) andReturn:newValue];
                [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                [delegate checkInitialAttribution];
            });
            it(@"Should send event if updated", ^{
                NSNumber *newValue = @23;
                [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(YES)];
                [attributionModel stub:@selector(checkInitialAttribution) andReturn:newValue];
                [[reporter should] receive:@selector(reportAttributionEventWithName:value:)
                             withArguments:@"conversion_value_update", @{ @"old_value" : @12, @"new_value" : newValue }];
                [delegate checkInitialAttribution];
            });
            it(@"Should not send event if not updated", ^{
                NSNumber *newValue = @23;
                [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(NO)];
                [attributionModel stub:@selector(checkInitialAttribution) andReturn:newValue];
                [[reporter shouldNot] receive:@selector(reportAttributionEventWithName:value:)];
                [delegate checkInitialAttribution];
            });
        });
    });
    context(@"Serialized event", ^{
        context(@"Client event", ^{
            NSString *eventName = @"event name";
            AMAEvent *event = [[AMAEvent alloc] init];
            beforeEach(^{
                event.type = AMAEventTypeClient;
                event.name = eventName;
            });
            it(@"Should pass to model", ^{
                [[attributionModel should] receive:@selector(checkAttributionForClientEvent:) withArguments:eventName];
                [delegate checkSerializedEventAttribution:event];
            });
            context(@"Old value is nil", ^{
                beforeEach(^{
                    [persistentConfiguration stub:@selector(conversionValue) andReturn:nil];
                });
                it(@"Should update if non nil", ^{
                    NSNumber *newValue = @23;
                    [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:newValue];
                    [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                    [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should not update if nil", ^{
                    [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:nil];
                    [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                    [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should update if zero", ^{
                    NSNumber *newValue = @0;
                    [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:newValue];
                    [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                    [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should send event if updated", ^{
                    NSNumber *newValue = @23;
                    [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:newValue];
                    [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(YES)];
                    [[reporter should] receive:@selector(reportAttributionEventWithName:value:)
                                 withArguments:@"conversion_value_update", @{ @"new_value" : newValue }];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should not send event if not updated", ^{
                    NSNumber *newValue = @23;
                    [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:newValue];
                    [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(NO)];
                    [[reporter shouldNot] receive:@selector(reportAttributionEventWithName:value:)];
                    [delegate checkSerializedEventAttribution:event];
                });
            });
            context(@"Old value is not nil", ^{
                beforeEach(^{
                    [persistentConfiguration stub:@selector(conversionValue) andReturn:@12];
                });
                it(@"Should not update if nil", ^{
                    NSNumber *newValue = @23;
                    [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:newValue];
                    [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                    [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should not update if nil", ^{
                    [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:nil];
                    [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                    [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should update if zero", ^{
                    NSNumber *newValue = @0;
                    [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:newValue];
                    [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                    [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should update if zero and old value is zero", ^{
                    [persistentConfiguration stub:@selector(conversionValue) andReturn:@0];
                    NSNumber *newValue = @0;
                    [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:newValue];
                    [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                    [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should not update if value is the same", ^{
                    NSNumber *newValue = @12;
                    [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:newValue];
                    [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                    [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should send event if updated", ^{
                    NSNumber *newValue = @23;
                    [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:newValue];
                    [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(YES)];
                    [[reporter should] receive:@selector(reportAttributionEventWithName:value:)
                                 withArguments:@"conversion_value_update", @{ @"old_value" : @12, @"new_value" : newValue }];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should not send event if not updated", ^{
                    NSNumber *newValue = @23;
                    [attributionModel stub:@selector(checkAttributionForClientEvent:) andReturn:newValue];
                    [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(NO)];
                    [[reporter shouldNot] receive:@selector(reportAttributionEventWithName:value:)];
                    [delegate checkSerializedEventAttribution:event];
                });
            });
        });
        context(@"Revenue event", ^{
            AMALightRevenueEvent *__block lightEvent = nil;
            AMAEvent *event = [[AMAEvent alloc] init];
            id value = [[AMABinaryEventValue alloc] initWithData:[NSData data] gZipped:NO];
            beforeEach(^{
                lightEvent = [AMALightRevenueEvent nullMock];
                [revenueDeduplicator stub:@selector(checkForID:) andReturn:theValue(YES)];
                [lightRevenueEventConverter stub:@selector(eventFromSerializedValue:) andReturn:lightEvent];
                event.type = AMAEventTypeRevenue;
                event.value = value;
            });
            it(@"Should pass to model", ^{
                [[attributionModel should] receive:@selector(checkAttributionForRevenueEvent:) withArguments:lightEvent];
                [delegate checkSerializedEventAttribution:event];
            });
            it(@"Should convert", ^{
                [[lightRevenueEventConverter should] receive:@selector(eventFromSerializedValue:) withArguments:value];
                [delegate checkSerializedEventAttribution:event];
            });
            context(@"Deduplication", ^{
                NSString *transactionID = @"some id";
                beforeEach(^{
                    [lightEvent stub:@selector(transactionID) andReturn:transactionID];
                });
                it(@"Should pass to revenue deduplicator", ^{
                    [[revenueDeduplicator should] receive:@selector(checkForID:) withArguments:transactionID];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should pass to checker if unique", ^{
                    [revenueDeduplicator stub:@selector(checkForID:) andReturn:theValue(YES)];
                    [[attributionModel should] receive:@selector(checkAttributionForRevenueEvent:) withArguments:lightEvent];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should not pass to checker if duplicate", ^{
                    [revenueDeduplicator stub:@selector(checkForID:) andReturn:theValue(NO)];
                    [[attributionModel shouldNot] receive:@selector(checkAttributionForRevenueEvent:)];
                    [delegate checkSerializedEventAttribution:event];
                });
            });
            context(@"Restore", ^{
                it(@"Should pass to model if not restored", ^{
                    [lightEvent stub:@selector(isRestore) andReturn:theValue(NO)];
                    [[attributionModel should] receive:@selector(checkAttributionForRevenueEvent:) withArguments:lightEvent];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should not pass to model if restored", ^{
                    [lightEvent stub:@selector(isRestore) andReturn:theValue(YES)];
                    [[attributionModel shouldNot] receive:@selector(checkAttributionForRevenueEvent:)];
                    [delegate checkSerializedEventAttribution:event];
                });
            });
            context(@"Old value is nil", ^{
                beforeEach(^{
                    [persistentConfiguration stub:@selector(conversionValue) andReturn:nil];
                });
                it(@"Should update if non nil", ^{
                    NSNumber *newValue = @23;
                    [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:newValue];
                    [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                    [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should not update if nil", ^{
                    [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:nil];
                    [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                    [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should update if zero", ^{
                    NSNumber *newValue = @0;
                    [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:newValue];
                    [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                    [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should send event if updated", ^{
                    NSNumber *newValue = @23;
                    [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:newValue];
                    [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(YES)];
                    [[reporter should] receive:@selector(reportAttributionEventWithName:value:)
                                 withArguments:@"conversion_value_update", @{ @"new_value" : newValue }];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should not send event if not updated", ^{
                    NSNumber *newValue = @23;
                    [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:newValue];
                    [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(NO)];
                    [[reporter shouldNot] receive:@selector(reportAttributionEventWithName:value:)];
                    [delegate checkSerializedEventAttribution:event];
                });
            });
            context(@"Old value is not nil", ^{
                beforeEach(^{
                    [persistentConfiguration stub:@selector(conversionValue) andReturn:@12];
                });
                it(@"Should not update if nil", ^{
                    NSNumber *newValue = @23;
                    [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:newValue];
                    [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                    [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should not update if nil", ^{
                    [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:nil];
                    [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                    [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should update if zero", ^{
                    NSNumber *newValue = @0;
                    [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:newValue];
                    [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                    [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should update if zero and old value is zero", ^{
                    [persistentConfiguration stub:@selector(conversionValue) andReturn:@0];
                    NSNumber *newValue = @0;
                    [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:newValue];
                    [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                    [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should not update if value is the same", ^{
                    NSNumber *newValue = @12;
                    [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:newValue];
                    [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                    [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should send event if updated", ^{
                    NSNumber *newValue = @23;
                    [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:newValue];
                    [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(YES)];
                    [[reporter should] receive:@selector(reportAttributionEventWithName:value:)
                                 withArguments:@"conversion_value_update", @{ @"old_value" : @12, @"new_value" : newValue }];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should not send event if not updated", ^{
                    NSNumber *newValue = @23;
                    [attributionModel stub:@selector(checkAttributionForRevenueEvent:) andReturn:newValue];
                    [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(NO)];
                    [[reporter shouldNot] receive:@selector(reportAttributionEventWithName:value:)];
                    [delegate checkSerializedEventAttribution:event];
                });
            });
        });
        context(@"E-commerce event", ^{
            AMALightECommerceEvent *__block lightEvent = nil;
            AMAEvent *event = [[AMAEvent alloc] init];
            id value = [[AMABinaryEventValue alloc] initWithData:[NSData data] gZipped:NO];;
            beforeEach(^{
                event.type = AMAEventTypeECommerce;
                event.value = value;
                lightEvent = [AMALightECommerceEvent nullMock];
                [lightECommerceEventConverter stub:@selector(eventFromSerializedValue:) andReturn:lightEvent];
            });
            it(@"Should pass model", ^{
                [[attributionModel should] receive:@selector(checkAttributionForECommerceEvent:) withArguments:lightEvent];
                [delegate checkSerializedEventAttribution:event];
            });
            it(@"Should convert", ^{
                [[lightECommerceEventConverter should] receive:@selector(eventFromSerializedValue:) withArguments:value];
                [delegate checkSerializedEventAttribution:event];
            });
            context(@"Old value is nil", ^{
                beforeEach(^{
                    [persistentConfiguration stub:@selector(conversionValue) andReturn:nil];
                });
                it(@"Should update if non nil", ^{
                    NSNumber *newValue = @23;
                    [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:newValue];
                    [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                    [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should not update if nil", ^{
                    [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:nil];
                    [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                    [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should update if zero", ^{
                    NSNumber *newValue = @0;
                    [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:newValue];
                    [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                    [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should send event if updated", ^{
                    NSNumber *newValue = @23;
                    [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:newValue];
                    [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(YES)];
                    [[reporter should] receive:@selector(reportAttributionEventWithName:value:)
                                 withArguments:@"conversion_value_update", @{ @"new_value" : newValue }];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should not send event if not updated", ^{
                    NSNumber *newValue = @23;
                    [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:newValue];
                    [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(NO)];
                    [[reporter shouldNot] receive:@selector(reportAttributionEventWithName:value:)];
                    [delegate checkSerializedEventAttribution:event];
                });
            });
            context(@"Old value is not nil", ^{
                beforeEach(^{
                    [persistentConfiguration stub:@selector(conversionValue) andReturn:@12];
                });
                it(@"Should not update if nil", ^{
                    NSNumber *newValue = @23;
                    [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:newValue];
                    [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                    [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should not update if nil", ^{
                    [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:nil];
                    [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                    [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should update if zero", ^{
                    NSNumber *newValue = @0;
                    [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:newValue];
                    [[persistentConfiguration should] receive:@selector(setConversionValue:) withArguments:newValue];
                    [[skadNetworkRequestor should] receive:@selector(updateConversionValue:) withArguments:theValue(newValue.intValue)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should update if zero and old value is zero", ^{
                    [persistentConfiguration stub:@selector(conversionValue) andReturn:@0];
                    NSNumber *newValue = @0;
                    [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:newValue];
                    [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                    [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should not update if value is the same", ^{
                    NSNumber *newValue = @12;
                    [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:newValue];
                    [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                    [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should send event if updated", ^{
                    NSNumber *newValue = @23;
                    [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:newValue];
                    [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(YES)];
                    [[reporter should] receive:@selector(reportAttributionEventWithName:value:)
                                 withArguments:@"conversion_value_update", @{ @"old_value" : @12, @"new_value" : newValue }];
                    [delegate checkSerializedEventAttribution:event];
                });
                it(@"Should not send event if not updated", ^{
                    NSNumber *newValue = @23;
                    [attributionModel stub:@selector(checkAttributionForECommerceEvent:) andReturn:newValue];
                    [skadNetworkRequestor stub:@selector(updateConversionValue:) andReturn:theValue(NO)];
                    [[reporter shouldNot] receive:@selector(reportAttributionEventWithName:value:)];
                    [delegate checkSerializedEventAttribution:event];
                });
            });
        });
        context(@"Bad event", ^{
            AMAEvent *event = [[AMAEvent alloc] init];
            beforeEach(^{
                event.type = AMAEventTypeOpen;
            });
            it(@"Should not do anything", ^{
                [[attributionModel shouldNot] receive:@selector(checkAttributionForClientEvent:)];
                [[attributionModel shouldNot] receive:@selector(checkAttributionForRevenueEvent:)];
                [[attributionModel shouldNot] receive:@selector(checkAttributionForECommerceEvent:)];
                [[persistentConfiguration shouldNot] receive:@selector(setConversionValue:)];
                [[skadNetworkRequestor shouldNot] receive:@selector(updateConversionValue:)];
                [[reporter shouldNot] receive:@selector(reportAttributionEventWithName:value:)];
                [delegate checkSerializedEventAttribution:event];
            });
        });
    });

});

SPEC_END
