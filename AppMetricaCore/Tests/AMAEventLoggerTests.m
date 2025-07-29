
#import <Kiwi/Kiwi.h>
#import "AMAEventLogger.h"
#import "AMAMetricaConfiguration.h"
#import "AMAReporterConfiguration.h"
#import "AMAEvent.h"
#import "AMALogSpy.h"

SPEC_BEGIN(AMAEventLoggerTests)

describe(@"AMAEventLogger", ^{

    NSString *const apiKey = @"d9b4296b-8fa1-48d1-ad58-3a40c045c4cc";
    NSString *const eventName = @"EVENT_NAME";
    AMAEventType const eventType = AMAEventTypeClient;
    NSNumber *const eventOid = @16;
    NSNumber *const sessionOid = @23;
    NSUInteger const sequenceNumber = 42;

    AMAMetricaConfiguration *__block configurationInstance = nil;
    AMAReporterConfiguration *__block reporterConfiguration = nil;
    AMAEvent *__block event = nil;
    AMALogSpy *__block logSpy = nil;
    AMAEventLogger *__block logger = nil;

    beforeEach(^{
        reporterConfiguration = [AMAReporterConfiguration nullMock];
        configurationInstance = [AMAMetricaConfiguration nullMock];
        [configurationInstance stub:@selector(configurationForApiKey:) andReturn:reporterConfiguration];
        [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:configurationInstance];

        event = [AMAEvent nullMock];
        [event stub:@selector(name) andReturn:eventName];
        [event stub:@selector(type) andReturn:theValue(eventType)];
        [event stub:@selector(oid) andReturn:eventOid];
        [event stub:@selector(sessionOid) andReturn:sessionOid];
        [event stub:@selector(sequenceNumber) andReturn:theValue(sequenceNumber)];

        logSpy = [[AMALogSpy alloc] init];
        [AMALogFacade stub:@selector(sharedLog) andReturn:logSpy];

        logger = [[AMAEventLogger alloc] initWithApiKey:apiKey];
    });
    afterEach(^{
        [AMAMetricaConfiguration clearStubs];
    });

    AMALogMessageSpy *(^message)(NSString *) = ^(NSString *text) {
        return [AMALogMessageSpy messageWithText:text channel:@"AppMetricaCore" level:AMALogLevelInfo];
    };
    NSString *(^textWithApiKeySuffix)(NSString *) = ^(NSString *text) {
        return [NSString stringWithFormat:@"%@ (apiKey: d9b4296b-xxxx-xxxx-xxxx-xxxxxxxxc4cc).", text];
    };
    
    context(@"Log enabled", ^{
        beforeEach(^{
            [reporterConfiguration stub:@selector(logsEnabled) andReturn:theValue(YES)];
        });
        NSString *(^suffixWithNullMetainfo)(NSString *, NSString *, NSString *) = ^(NSString *prefix,
                                                                                    NSString *eventName,
                                                                                    NSString *extraArguments) {
            NSString *text = [NSString stringWithFormat:@"%@ eventOid (null), sessionOid (null), "
                              "sequenceNumber (null), name '%@'%@.", prefix, eventName, extraArguments ?: @""];
            return textWithApiKeySuffix(text);
        };
        NSString *(^suffixWithPopulatedlMetainfo)(NSString *, NSString *) = ^(NSString *prefix, NSString *eventName) {
            NSString *text = [NSString stringWithFormat:@"%@ eventOid 16, sessionOid 23, "
                              "sequenceNumber 42, name '%@'.", prefix, eventName];
            return textWithApiKeySuffix(text);
        };
        context(@"Client event received", ^{
            it(@"Should log", ^{
                NSDictionary *params = @{ @"foo" : @"bar" };
                [logger logClientEventReceivedWithName:eventName parameters:params];
                NSString *expectedText = suffixWithNullMetainfo(@"Client event is received:", 
                                                                @"EVENT_NAME",
                                                                [NSString stringWithFormat:@", parameters %@", params]);
                [[logSpy.messages should] equal:@[ message(expectedText) ]];
            });
        });
        context(@"Profile event received", ^{
            it(@"Should log", ^{
                [logger logProfileEventReceived];
                NSString *expectedText = suffixWithNullMetainfo(@"Profile event is received:", nil, nil);
                [[logSpy.messages should] equal:@[ message(expectedText) ]];
            });
        });
        context(@"Revenue event received", ^{
            it(@"Should log", ^{
                [logger logRevenueEventReceived];
                NSString *expectedText = suffixWithNullMetainfo(@"Revenue event is received:", nil, nil);
                [[logSpy.messages should] equal:@[ message(expectedText) ]];
            });
        });
        context(@"AdRevenue event received", ^{
            it(@"Should log", ^{
                [logger logAdRevenueEventReceived];
                NSString *expectedText = suffixWithNullMetainfo(@"AdRevenue event is received:", nil, nil);
                [[logSpy.messages should] equal:@[ message(expectedText) ]];
            });
        });
        context(@"Event built", ^{
            it(@"Should log", ^{
                [logger logEventBuilt:event];
                NSString *expectedText = suffixWithPopulatedlMetainfo(@"Client event is built:", @"EVENT_NAME");
                [[logSpy.messages should] equal:@[ message(expectedText) ]];
            });
        });
        context(@"Event saved", ^{
            it(@"Should log", ^{
                [logger logEventSaved:event];
                NSString *expectedText = suffixWithPopulatedlMetainfo(@"Client event is saved to db:", @"EVENT_NAME");
                [[logSpy.messages should] equal:@[ message(expectedText) ]];
            });
        });
        context(@"Event sent", ^{
            it(@"Should log", ^{
                [logger logEventSent:event];
                NSString *expectedText = suffixWithPopulatedlMetainfo(@"Client event is sent:", @"EVENT_NAME");
                [[logSpy.messages should] equal:@[ message(expectedText) ]];
            });
        });
        context(@"Event purged", ^{
            it(@"Should log", ^{
                [logger logEventPurged:event];
                NSString *expectedText = suffixWithPopulatedlMetainfo(@"Client event is removed from db:", @"EVENT_NAME");
                [[logSpy.messages should] equal:@[ message(expectedText) ]];
            });
        });
        context(@"Different types", ^{
            void (^logEventSentWithType)(AMAEventType) = ^(AMAEventType eventType) {
                [event stub:@selector(type) andReturn:theValue(eventType)];
                [logger logEventSent:event];
            };
            NSString *(^textForEventWithTypeName)(NSString *) = ^(NSString *typeName) {
                NSString *text =
                [NSString stringWithFormat:@"%@ event is sent: eventOid 16, sessionOid 23, "
                 "sequenceNumber 42, name 'EVENT_NAME'.", typeName];
                return textWithApiKeySuffix(text);
            };
            it(@"Should log client event", ^{
                logEventSentWithType(AMAEventTypeClient);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"Client")) ]];
            });
            it(@"Should log profile event", ^{
                logEventSentWithType(AMAEventTypeProfile);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"Profile")) ]];
            });
            it(@"Should log revenue event", ^{
                logEventSentWithType(AMAEventTypeRevenue);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"Revenue")) ]];
            });
            it(@"Should log adRevenue event", ^{
                logEventSentWithType(AMAEventTypeAdRevenue);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"AdRevenue")) ]];
            });
            it(@"Should log init event", ^{
                logEventSentWithType(AMAEventTypeInit);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"Init")) ]];
            });
            it(@"Should log start event", ^{
                logEventSentWithType(AMAEventTypeStart);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"Start")) ]];
            });
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            it(@"Should log referrer event", ^{
                logEventSentWithType(AMAEventTypeReferrer);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"Referrer")) ]];
            });
#pragma clang diagnostic pop
            it(@"Should alive event", ^{
                logEventSentWithType(AMAEventTypeAlive);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"Alive")) ]];
            });
            it(@"Should log first event", ^{
                logEventSentWithType(AMAEventTypeFirst);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"First")) ]];
            });
            it(@"Should log open event", ^{
                logEventSentWithType(AMAEventTypeOpen);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"Open")) ]];
            });
            it(@"Should log update event", ^{
                logEventSentWithType(AMAEventTypeUpdate);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"Update")) ]];
            });
            it(@"Should log protobuf crash event", ^{
                logEventSentWithType(AMAEventTypeProtobufCrash);
                [[logSpy.messages should]
                 equal:@[ message(textForEventWithTypeName(@"Crash (protobuf)")) ]];
            });
            it(@"Should log ANR event", ^{
                logEventSentWithType(AMAEventTypeProtobufANR);
                [[logSpy.messages should]
                 equal:@[ message(textForEventWithTypeName(@"Application not responding (protobuf)")) ]];
            });
            it(@"Should log custom event", ^{
                logEventSentWithType(1000);
                NSString *text = @"Event [1000] is sent: eventOid 16, sessionOid 23, "
                "sequenceNumber 42, name 'EVENT_NAME'.";
                [[logSpy.messages should] equal:@[ message(textWithApiKeySuffix(text)) ]];
            });
        });
    });
    context(@"Log disabled", ^{
        beforeEach(^{
            [reporterConfiguration stub:@selector(logsEnabled) andReturn:theValue(NO)];
        });
        NSString *(^textForEvent)(NSString *, NSString *) = ^(NSString *typeName, NSString *action) {
            NSString *text =
                [NSString stringWithFormat:@"%@ event is %@: eventOid 16, sessionOid 23, "
                                            "sequenceNumber 42, name 'EVENT_NAME'.", typeName, action];
            return textWithApiKeySuffix(text);
        };
        context(@"Received", ^{
            NSString *(^textForEventWithTypeName)(NSString *, NSString *, NSString *) = ^(NSString *typeName,
                                                                                          NSString *eventName,
                                                                                          NSString *extraArguments) {
                NSString *text =
                    [NSString stringWithFormat:@"%@ event is received: eventOid (null), sessionOid (null), "
                                                "sequenceNumber (null), name '%@'%@.", typeName, eventName, extraArguments ?: @""];
                return textWithApiKeySuffix(text);
            };
            it(@"Should log client event", ^{
                NSDictionary *params = @{ @"foo" : @"bar" };
                [logger logClientEventReceivedWithName:eventName parameters:params];
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"Client", 
                                                   eventName,
                                                   [NSString stringWithFormat:@", parameters %@", params])) ]];
            });
            it(@"Should log profile event", ^{
                [logger logProfileEventReceived];
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"Profile", nil, nil)) ]];
            });
            it(@"Should log revenue event", ^{
                [logger logRevenueEventReceived];
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"Revenue", nil, nil)) ]];
            });
            it(@"Should log adRevenue event", ^{
                [logger logAdRevenueEventReceived];
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"AdRevenue", nil, nil)) ]];
            });
        });
        context(@"Event built", ^{
            it(@"Should log", ^{
                [logger logEventBuilt:event];
                [[logSpy.messages should] equal:@[ message(textForEvent(@"Client", @"built")) ]];
            });
        });
        context(@"Event saved", ^{
            it(@"Should log", ^{
                [logger logEventSaved:event];
                [[logSpy.messages should] equal:@[ message(textForEvent(@"Client", @"saved to db")) ]];
            });
        });
        context(@"Event sent", ^{
            it(@"Should log", ^{
                [logger logEventSent:event];
                [[logSpy.messages should] equal:@[ message(textForEvent(@"Client", @"sent")) ]];
            });
        });
        context(@"Event purged", ^{
            it(@"Should log", ^{
                [logger logEventPurged:event];
                [[logSpy.messages should] equal:@[ message(textForEvent(@"Client", @"removed from db")) ]];
            });
        });
        context(@"Different types", ^{
            void (^logEventSentWithType)(AMAEventType) = ^(AMAEventType eventType) {
                [event stub:@selector(type) andReturn:theValue(eventType)];
                [logger logEventSent:event];
            };
            NSString *(^textForEventWithTypeName)(NSString *) = ^(NSString *typeName) {
                return textForEvent(typeName, @"sent");
            };
            it(@"Should log client event", ^{
                logEventSentWithType(AMAEventTypeClient);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"Client")) ]];
            });
            it(@"Should log profile event", ^{
                logEventSentWithType(AMAEventTypeProfile);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"Profile")) ]];
            });
            it(@"Should log revenue event", ^{
                logEventSentWithType(AMAEventTypeRevenue);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"Revenue")) ]];
            });
            it(@"Should log adRevenue event", ^{
                logEventSentWithType(AMAEventTypeAdRevenue);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"AdRevenue")) ]];
            });
            it(@"Should log init event", ^{
                logEventSentWithType(AMAEventTypeInit);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"Init")) ]];
            });
            it(@"Should log start event", ^{
                logEventSentWithType(AMAEventTypeStart);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"Start")) ]];
            });
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            it(@"Should log referrer event", ^{
                logEventSentWithType(AMAEventTypeReferrer);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"Referrer")) ]];
            });
#pragma clang diagnostic pop
            it(@"Should alive event", ^{
                logEventSentWithType(AMAEventTypeAlive);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"Alive")) ]];
            });
            it(@"Should log first event", ^{
                logEventSentWithType(AMAEventTypeFirst);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"First")) ]];
            });
            it(@"Should log open event", ^{
                logEventSentWithType(AMAEventTypeOpen);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"Open")) ]];
            });
            it(@"Should log update event", ^{
                logEventSentWithType(AMAEventTypeUpdate);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"Update")) ]];
            });
            it(@"Should log protobuf crash event", ^{
                logEventSentWithType(AMAEventTypeProtobufCrash);
                [[logSpy.messages should] equal:@[ message(textForEventWithTypeName(@"Crash (protobuf)")) ]];
            });
            it(@"Should log ANR event", ^{
                logEventSentWithType(AMAEventTypeProtobufANR);
                [[logSpy.messages should]
                    equal:@[ message(textForEventWithTypeName(@"Application not responding (protobuf)")) ]];
            });
            it(@"Should log custom event", ^{
                logEventSentWithType(1000);
                NSString *text = @"Event [1000] is sent: eventOid 16, sessionOid 23, "
                                  "sequenceNumber 42, name 'EVENT_NAME'.";
                [[logSpy.messages should] equal:@[ message(textWithApiKeySuffix(text)) ]];
            });
        });
    });

});

SPEC_END
