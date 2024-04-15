
#import <Kiwi/Kiwi.h>
#import "AMACore.h"
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMAEventBuilder.h"
#import "AMAEvent.h"
#import "AMAEventValueProtocol.h"
#import "AMAEventTypeResolver.h"
#import "AMAEventValueFactory.h"
#import "AMAMetricaConfiguration.h"
#import "AMAReporterStateStorage.h"
#import "AMAAppMetricaPreloadInfo+AMAInternal.h"
#import "AMAEncryptedFileStorageFactory.h"
#import "AMAEventComposerProvider.h"
#import "AMAEventComposer.h"
#import "AMABinaryEventValue.h"
#import "AMAFileEventValue.h"
#import "AMAExtrasComposer.h"

SPEC_BEGIN(AMAEventBuilderTests)

describe(@"AMAEventBuilder", ^{

    NSObject<AMAEventValueProtocol> *__block stringValue = nil;
    NSObject<AMAEventValueProtocol> *__block binaryValue = nil;
    NSObject<AMAEventValueProtocol> *__block fileValue = nil;
    KWCaptureSpy *__block valueSpy = nil;

    AMAReporterStateStorage *__block stateStorage = nil;
    AMAEventValueFactory *__block valueFactory = nil;
    NSObject<AMADataEncoding> *__block gZipEncoder = nil;
    AMAEventComposerProvider *__block eventComposerProvider = nil;
    AMAEventComposer *__block eventComposer = nil;
    AMAEventBuilder *__block builder = nil;

    AMAEvent *__block event = nil;

    beforeEach(^{
        stateStorage = [AMAReporterStateStorage nullMock];
        stringValue = [KWMock nullMockForProtocol:@protocol(AMAEventValueProtocol)];
        binaryValue = [KWMock nullMockForProtocol:@protocol(AMAEventValueProtocol)];
        fileValue = [KWMock nullMockForProtocol:@protocol(AMAEventValueProtocol)];
        gZipEncoder = [KWMock nullMockForProtocol:@protocol(AMADataEncoding)];

        valueFactory = [AMAEventValueFactory nullMock];
        [valueFactory stub:@selector(stringEventValue:bytesTruncated:) andReturn:stringValue];
        [valueFactory stub:@selector(binaryEventValue:gZipped:bytesTruncated:) andReturn:binaryValue];
        [valueFactory stub:@selector(fileEventValue:fileName:encryptionType:truncationType:bytesTruncated:error:)
                 andReturn:fileValue];
        [valueFactory stub:@selector(fileEventValueWithGZippedData:fileName:bytesTruncated:error:)
                 andReturn:fileValue];

        eventComposerProvider = [AMAEventComposerProvider nullMock];
        eventComposer = [AMAEventComposer nullMock];
        [eventComposerProvider stub:@selector(composerForType:) andReturn:eventComposer];
    });

    context(@"With preload info", ^{
        AMAAppMetricaPreloadInfo *__block preloadInfo = nil;

        beforeEach(^{
            preloadInfo = [[AMAAppMetricaPreloadInfo alloc] initWithTrackingIdentifier:@"trackingID"];
            builder = [[AMAEventBuilder alloc] initWithStateStorage:stateStorage
                                                        preloadInfo:preloadInfo
                                                  eventValueFactory:valueFactory
                                                        gZipEncoder:gZipEncoder
                                              eventComposerProvider:eventComposerProvider];
            valueSpy = [valueFactory captureArgument:@selector(stringEventValue:bytesTruncated:) atIndex:0];
        });
        context(@"EVENT_FIRST", ^{
            context(@"Value", ^{
                beforeEach(^{
                    event = [builder eventFirstWithError:nil];
                });
                it(@"Should have preload info in value", ^{
                    NSDictionary *eventObject = [AMAJSONSerialization dictionaryWithJSONString:valueSpy.argument
                                                                                         error:nil];
                    [[eventObject should] equal:preloadInfo.preloadInfoJSONObject];
                });
                it(@"Should have valid value", ^{
                    [[((NSObject *)event.value) should] equal:stringValue];
                });
            });
            it(@"Should be passed to composer", ^{
                [[eventComposerProvider should] receive:@selector(composerForType:) withArguments:theValue(AMAEventTypeFirst)];
                [[eventComposer should] receive:@selector(compose:)];
                [builder eventFirstWithError:nil];
            });
        });
        context(@"EVENT_INIT", ^{
            context(@"Value", ^{
                
                NSDictionary *const kAMAAdditionalParams = @{
                    @"a" : @1,
                    @"b" : @2,
                };
                
                beforeEach(^{
                    event = [builder eventInitWithParameters:kAMAAdditionalParams error:nil];
                });
                it(@"Should have preload info with additional params in value", ^{
                    NSDictionary *eventObject = [AMAJSONSerialization dictionaryWithJSONString:valueSpy.argument
                                                                                         error:nil];
                    NSMutableDictionary *mutablePreload = [preloadInfo.preloadInfoJSONObject mutableCopy];
                    [mutablePreload addEntriesFromDictionary:kAMAAdditionalParams];
                    [[eventObject should] equal:mutablePreload];
                });
                it(@"Should have valid value", ^{
                    [[((NSObject *)event.value) should] equal:stringValue];
                });
            });
            it(@"Should be passed to composer", ^{
                [[eventComposerProvider should] receive:@selector(composerForType:) withArguments:theValue(AMAEventTypeInit)];
                [[eventComposer should] receive:@selector(compose:)];
                [builder eventInitWithParameters:nil error:nil];
            });
        });
        context(@"EVENT_UPDATE", ^{
            context(@"Value", ^{
                beforeEach(^{
                    event = [builder eventUpdateWithError:nil];
                });
                it(@"Should have preload info in value", ^{
                    NSDictionary *eventObject = [AMAJSONSerialization dictionaryWithJSONString:valueSpy.argument
                                                                                         error:nil];
                    [[eventObject should] equal:preloadInfo.preloadInfoJSONObject];
                });
                it(@"Should have valid value", ^{
                    [[((NSObject *)event.value) should] equal:stringValue];
                });
            });
            it(@"Should be passed to composer", ^{
                [[eventComposerProvider should] receive:@selector(composerForType:) withArguments:theValue(AMAEventTypeUpdate)];
                [[eventComposer should] receive:@selector(compose:)];
                [builder eventUpdateWithError:nil];
            });
        });
    });
    context(@"By default", ^{
        beforeEach(^{
            builder = [[AMAEventBuilder alloc] initWithStateStorage:stateStorage
                                                        preloadInfo:nil
                                                  eventValueFactory:valueFactory
                                                        gZipEncoder:gZipEncoder
                                              eventComposerProvider:eventComposerProvider];
        });

        context(@"EVENT_CLIENT", ^{
            context(@"Value", ^{
                beforeEach(^{
                    valueSpy = [valueFactory captureArgument:@selector(stringEventValue:bytesTruncated:) atIndex:0];
                    event = [builder clientEventNamed:@"event"
                                           parameters:@{@"key" : @"value"}
                                      firstOccurrence:AMAOptionalBoolFalse
                                                error:nil];
                });
                it(@"Should create json without linebreaks", ^{
                    [[valueSpy.argument shouldNot] containString:@"\n"];
                });
                it(@"Should create valid json", ^{
                    [[valueSpy.argument should] equal:@"{\"key\":\"value\"}"];
                });
                it(@"Should have valid value", ^{
                    [[((NSObject *)event.value) should] equal:stringValue];
                });
            });
            it(@"Should be passed to composer", ^{
                [[eventComposerProvider should] receive:@selector(composerForType:) withArguments:theValue(AMAEventTypeClient)];
                [[eventComposer should] receive:@selector(compose:)];
                [builder clientEventNamed:@"event"
                               parameters:nil
                          firstOccurrence:AMAOptionalBoolFalse
                                    error:nil];
            });
        });
        context(@"EVENT_REFERRER", ^{
            NSString *const referrer = @"foobar";
            context(@"Value", ^{
                beforeEach(^{
                    valueSpy = [valueFactory captureArgument:@selector(stringEventValue:bytesTruncated:) atIndex:0];
                    event = [builder eventReferrerWithValue:referrer error:nil];
                });
                it(@"Should contain valid value", ^{
                    [[valueSpy.argument should] equal:referrer];
                });
                it(@"Shouldn't construct EVENT_REFERRER with empty value", ^{
                    event = [builder eventReferrerWithValue:@"" error:nil];
                    [[event should] beNil];
                });
                it(@"Should have valid value", ^{
                    [[((NSObject *)event.value) should] equal:stringValue];
                });
            });
            it(@"Should be passed to composer", ^{
                [[eventComposerProvider should] receive:@selector(composerForType:) withArguments:theValue(AMAEventTypeReferrer)];
                [[eventComposer should] receive:@selector(compose:)];
                [builder eventReferrerWithValue:referrer error:nil];
            });
        });
        context(@"EVENT_ASA_TOKEN", ^{
            context(@"Value", ^{
                beforeEach(^{
                    valueSpy = [valueFactory captureArgument:@selector(stringEventValue:bytesTruncated:) atIndex:0];
                    event = [builder eventASATokenWithParameters:@{@"asaToken":@"123456789"} error:nil];
                });
                it(@"Should contain valid value", ^{
                    [[valueSpy.argument should] equal:@"{\"asaToken\":\"123456789\"}"];
                });
                it(@"Should have valid value", ^{
                    [[((NSObject *)event.value) should] equal:stringValue];
                });
            });
            it(@"Should be passed to composer", ^{
                [[eventComposerProvider should] receive:@selector(composerForType:) withArguments:theValue(AMAEventTypeASAToken)];
                [[eventComposer should] receive:@selector(compose:)];
                [builder eventASATokenWithParameters:@{@"asaToken":@"123456789"} error:nil];
            });
        });
        context(@"EVENT_OPEN", ^{
            context(@"Value", ^{
                beforeEach(^{
                    valueSpy = [valueFactory captureArgument:@selector(stringEventValue:bytesTruncated:) atIndex:0];
                    event = [builder eventOpen:@{ @"link": @"l" } attributionIDChanged:YES error:nil];
                });
                it(@"Should contain valid value", ^{
                    [[valueSpy.argument should] equal:@"{\"link\":\"l\"}"];
                });
                it(@"Should have valid value", ^{
                    [[((NSObject *)event.value) should] equal:stringValue];
                });
                it(@"Should have valid attribution id changed", ^{
                    [[theValue(event.attributionIDChanged) should] beYes];
                });
            });
            it(@"Should be passed to composer", ^{
                [[eventComposerProvider should] receive:@selector(composerForType:) withArguments:theValue(AMAEventTypeOpen)];
                [[eventComposer should] receive:@selector(compose:)];
                [builder eventOpen:@{ @"link": @"l" } attributionIDChanged:YES error:nil];
            });
        });
        context(@"EVENT_PERMISSIONS", ^{
            context(@"Event fields", ^{
                AMAEvent *__block event = nil;

                beforeEach(^{
                    valueSpy = [valueFactory captureArgument:@selector(stringEventValue:bytesTruncated:) atIndex:0];
                    event = [builder permissionsEventWithJSON:@"{\"permissions\":[]}" error:nil];
                });

                it(@"Should have valid value", ^{
                    [[(NSObject *)event.value should] equal:stringValue];
                });
                it(@"Should have valid type", ^{
                    [[theValue(event.type) should] equal:theValue(AMAEventTypePermissions)];
                });
                it(@"Should have valid value", ^{
                    [[valueSpy.argument should] equal:@"{\"permissions\":[]}"];
                });
            });
            it(@"Should be passed to composer", ^{
                [[eventComposerProvider should] receive:@selector(composerForType:) withArguments:theValue(AMAEventTypePermissions)];
                [[eventComposer should] receive:@selector(compose:)];
                [builder permissionsEventWithJSON:@"{\"permissions\":[]}" error:nil];
            });
        });
        context(@"EVENT_PROFILE", ^{
            NSData *const data = [@"PROFILE" dataUsingEncoding:NSUTF8StringEncoding];
            context(@"Event fields", ^{
                beforeEach(^{
                    valueSpy = [valueFactory captureArgument:@selector(binaryEventValue:gZipped:bytesTruncated:) atIndex:0];
                    event = [builder eventProfile:data];
                });
                it(@"Should construct event with empty name", ^{
                    [[event.name should] beEmpty];
                });
                it(@"Should construct event with valid data", ^{
                    [[valueSpy.argument should] equal:data];
                });
                it(@"Should construct event with valid type", ^{
                    [[theValue(event.type) should] equal:theValue(AMAEventTypeProfile)];
                });
                it(@"Should have valid value", ^{
                    [[((NSObject *)event.value) should] equal:binaryValue];
                });
            });
            it(@"Should be passed to composer", ^{
                [[eventComposerProvider should] receive:@selector(composerForType:) withArguments:theValue(AMAEventTypeProfile)];
                [[eventComposer should] receive:@selector(compose:)];
                [builder eventProfile:data];
            });
        });
        context(@"EVENT_START", ^{
            NSData *const data = [@"SOME_UUIDS" dataUsingEncoding:NSUTF8StringEncoding];
            context(@"Event fields", ^{
                beforeEach(^{
                    valueSpy = [valueFactory captureArgument:@selector(binaryEventValue:gZipped:bytesTruncated:) atIndex:0];
                    event = [builder eventStartWithData:data];
                });
                it(@"Should construct event with empty name", ^{
                    [[event.name should] beEmpty];
                });
                it(@"Should construct event with valid data", ^{
                    [[valueSpy.argument should] equal:data];
                });
                it(@"Should construct event with valid type", ^{
                    [[theValue(event.type) should] equal:theValue(AMAEventTypeStart)];
                });
                it(@"Should have valid value", ^{
                    [[((NSObject *)event.value) should] equal:binaryValue];
                });
            });
            it(@"Should be passed to composer", ^{
                [[eventComposerProvider should] receive:@selector(composerForType:) withArguments:theValue(AMAEventTypeStart)];
                [[eventComposer should] receive:@selector(compose:)];
                [builder eventStartWithData:data];
            });
        });
        context(@"EVENT_REVENUE", ^{
            NSData *const data = [@"REVENUE" dataUsingEncoding:NSUTF8StringEncoding];
            NSUInteger const bytesTruncated = 42;
            context(@"Event fields", ^{
                beforeEach(^{
                    valueSpy = [valueFactory captureArgument:@selector(binaryEventValue:gZipped:bytesTruncated:) atIndex:0];
                    event = [builder eventRevenue:data bytesTruncated:bytesTruncated];
                });
                it(@"Should construct event with empty name", ^{
                    [[event.name should] beEmpty];
                });
                it(@"Should construct event with valid data", ^{
                    [[valueSpy.argument should] equal:data];
                });
                it(@"Should construct event with valid bytesTruncated", ^{
                    [[theValue(event.bytesTruncated) should] equal:theValue(bytesTruncated)];
                });
                it(@"Should construct event with valid type", ^{
                    [[theValue(event.type) should] equal:theValue(AMAEventTypeRevenue)];
                });
                it(@"Should have valid value", ^{
                    [[((NSObject *)event.value) should] equal:binaryValue];
                });
            });
            it(@"Should be passed to composer", ^{
                [[eventComposerProvider should] receive:@selector(composerForType:) withArguments:theValue(AMAEventTypeRevenue)];
                [[eventComposer should] receive:@selector(compose:)];
                [builder eventRevenue:data bytesTruncated:bytesTruncated];
            });
        });
        context(@"EVENT_AD_REVENUE", ^{
            NSData *const data = [@"AD_REVENUE" dataUsingEncoding:NSUTF8StringEncoding];
            NSUInteger const bytesTruncated = 42;
            context(@"Event fields", ^{
                beforeEach(^{
                    valueSpy = [valueFactory captureArgument:@selector(binaryEventValue:gZipped:bytesTruncated:) atIndex:0];
                    event = [builder eventAdRevenue:data bytesTruncated:bytesTruncated];
                });
                it(@"Should construct event with empty name", ^{
                    [[event.name should] beEmpty];
                });
                it(@"Should construct event with valid data", ^{
                    [[valueSpy.argument should] equal:data];
                });
                it(@"Should construct event with valid bytesTruncated", ^{
                    [[theValue(event.bytesTruncated) should] equal:theValue(bytesTruncated)];
                });
                it(@"Should construct event with valid type", ^{
                    [[theValue(event.type) should] equal:theValue(AMAEventTypeAdRevenue)];
                });
                it(@"Should have valid value", ^{
                    [[((NSObject *)event.value) should] equal:binaryValue];
                });
            });
            it(@"Should be passed to composer", ^{
                [[eventComposerProvider should] receive:@selector(composerForType:) withArguments:theValue(AMAEventTypeAdRevenue)];
                [[eventComposer should] receive:@selector(compose:)];
                [builder eventAdRevenue:data bytesTruncated:bytesTruncated];
            });
        });
        context(@"Сustom event resolving", ^{
            NSUInteger const allowedEventType = 1234;
            NSUInteger const internalEventType = 1;
            beforeEach(^{
                [AMAEventTypeResolver stub:@selector(isEventTypeReserved:) withBlock:^id(NSArray *params) {
                    NSUInteger eventType = [params[0] unsignedIntegerValue];
                    switch (eventType) {
                        case allowedEventType:
                            return theValue(NO);
                        case internalEventType:
                            return theValue(YES);
                        default:
                            [NSException raise:@"Wrong event type" format:@""];
                            return nil;
                    }
                }];
            });
            context(@"Should not create event with internal type", ^{
                it(@"String event type", ^{
                    event = [builder eventWithType:internalEventType
                                              name:nil
                                             value:nil
                                  eventEnvironment:nil
                                    appEnvironment:nil
                                            extras:nil
                                             error:nil];
                    [[event should] beNil];
                });
                it(@"Binary event type", ^{
                    event = [builder binaryEventWithType:internalEventType
                                                    data:nil
                                                    name:nil
                                                 gZipped:YES
                                        eventEnvironment:nil
                                          appEnvironment:nil
                                                  extras:nil
                                          bytesTruncated:0
                                                   error:nil];
                    [[event should] beNil];
                });
                it(@"File event type", ^{
                    event = [builder fileEventWithType:internalEventType
                                                  data:nil
                                              fileName:nil
                                               gZipped:YES
                                             encrypted:YES
                                             truncated:YES
                                      eventEnvironment:nil
                                        appEnvironment:nil
                                                extras:nil
                                                 error:nil];
                    [[event should] beNil];
                });
            });
        });
        context(@"EVENT_ALIVE", ^{
            context(@"Event fields", ^{
                beforeEach(^{
                    event = [builder eventAlive];
                });
                it(@"Should have correct type", ^{
                    [[theValue(event.type) should] equal:theValue(AMAEventTypeAlive)];
                });
            });
            it(@"Should be passed to composer", ^{
                [[eventComposerProvider should] receive:@selector(composerForType:) withArguments:theValue(AMAEventTypeAlive)];
                [[eventComposer should] receive:@selector(compose:)];
                [builder eventAlive];
            });
        });
        context(@"JS event", ^{
            context(@"Fields", ^{
                beforeEach(^{
                    valueSpy = [valueFactory captureArgument:@selector(stringEventValue:bytesTruncated:) atIndex:0];
                    event = [builder jsEvent:@"name" value:@"value"];
                });
                it(@"Should have valid value", ^{
                    [[((NSObject *)event.value) should] equal:stringValue];
                });
                it(@"Should have valid name", ^{
                    [[event.name should] equal:@"name"];
                });
                it(@"Should have valid type", ^{
                    [[theValue(event.type) should] equal:theValue(AMAEventTypeClient)];
                });
                it(@"Should have JS source", ^{
                    [[theValue(event.source) should] equal:theValue(AMAEventSourceJs)];
                });
            });
            context(@"Empty parameters", ^{
                it(@"Should not create event with nil name", ^{
                    event = [builder jsEvent:nil value:@"value"];
                    [[event should] beNil];
                });
                it(@"Should not create event with empty name", ^{
                    event = [builder jsEvent:@"" value:@"value"];
                    [[event should] beNil];
                });
                it(@"Should create event with nil value", ^{
                    event = [builder jsEvent:@"name" value:nil];
                    [[event shouldNot] beNil];
                });
                it(@"Should create event with empty value", ^{
                    event = [builder jsEvent:@"name" value:@""];
                    [[event shouldNot] beNil];
                });
            });
            it(@"Should be passed to composer", ^{
                [[eventComposerProvider should] receive:@selector(composerForType:) withArguments:theValue(AMAEventTypeClient)];
                [[eventComposer should] receive:@selector(compose:)];
                [builder jsEvent:@"name" value:@"value"];
            });
        });
        context(@"JS init event", ^{
            context(@"Fields", ^{
                beforeEach(^{
                    valueSpy = [valueFactory captureArgument:@selector(stringEventValue:bytesTruncated:) atIndex:0];
                    event = [builder jsInitEvent:@"value"];
                });
                it(@"Should have valid value", ^{
                    [[((NSObject *)event.value) should] equal:stringValue];
                });
                it(@"Should have empty name", ^{
                    [[event.name should] equal:@""];
                });
                it(@"Should have valid type", ^{
                    [[theValue(event.type) should] equal:theValue(AMAEventTypeWebViewSync)];
                });
                it(@"Should have JS source", ^{
                    [[theValue(event.source) should] equal:theValue(AMAEventSourceJs)];
                });
            });
            context(@"Empty parameters", ^{
                it(@"Should not create event with nil value", ^{
                    event = [builder jsInitEvent:nil];
                    [[event should] beNil];
                });
                it(@"Should not create event with empty value", ^{
                    event = [builder jsInitEvent:@""];
                    [[event should] beNil];
                });
            });
            it(@"Should be passed to composer", ^{
                [[eventComposerProvider should] receive:@selector(composerForType:) withArguments:theValue(AMAEventTypeWebViewSync)];
                [[eventComposer should] receive:@selector(compose:)];
                [builder jsInitEvent:@"value"];
            });
        });
        context(@"Attribution event", ^{
            NSString *name = @"some name";
            NSDictionary *value = @{ @"some key" : @"some value" };
            beforeEach(^{
                event = [builder attributionEventWithName:name value:value];
            });
            it(@"Should fill type", ^{
                [[theValue(event.type) should] equal:theValue(AMAEventTypeAttribution)];
            });
            it(@"Should fill name", ^{
                [[event.name should] equal:name];
            });
            it(@"Should fill value", ^{
                [[((NSObject *)event.value) should] equal:stringValue];
            });
            it(@"Should create value from right parameters", ^{
                valueSpy = [valueFactory captureArgument:@selector(stringEventValue:bytesTruncated:) atIndex:0];
                [builder attributionEventWithName:name value:value];
                NSString *passedValue = valueSpy.argument;
                NSDictionary *dictionary = [AMAJSONSerialization dictionaryWithJSONString:passedValue error:nil];
                [[dictionary should] equal:value];
            });
        });
        context(@"EVENT_CLIENT_EXTERNAL_ATTRIBUTION", ^{
            NSData *const data = [@"SOME_DATA" dataUsingEncoding:NSUTF8StringEncoding];
            context(@"Event fields", ^{
                beforeEach(^{
                    valueSpy = [valueFactory captureArgument:@selector(binaryEventValue:gZipped:bytesTruncated:) atIndex:0];
                    event = [builder eventExternalAttribution:data];
                });
                it(@"Should construct event with empty name", ^{
                    [[event.name should] beEmpty];
                });
                it(@"Should construct event with valid data", ^{
                    [[valueSpy.argument should] equal:data];
                });
                it(@"Should construct event with valid type", ^{
                    [[theValue(event.type) should] equal:theValue(AMAEventTypeExternalAttribution)];
                });
                it(@"Should have valid value", ^{
                    [[((NSObject *)event.value) should] equal:binaryValue];
                });
            });
            it(@"Should be passed to composer", ^{
                [[eventComposerProvider should] receive:@selector(composerForType:)
                                          withArguments:theValue(AMAEventTypeExternalAttribution)];
                [[eventComposer should] receive:@selector(compose:)];
                [builder eventExternalAttribution:data];
            });
            context(@"When data is nil", ^{
                it(@"Should not be passed to composer", ^{
                    [[eventComposerProvider shouldNot] receive:@selector(composerForType:)];
                    [[eventComposer shouldNot] receive:@selector(compose:)];
                    [builder eventExternalAttribution:nil];
                });
                it(@"Should return nil", ^{
                    [[builder eventExternalAttribution:nil] shouldBeNil];
                });
            });
        });
    });
    context(@"Reporting custom events", ^{
        let(eventEnvironment, ^NSDictionary *{ return @{@"key" : @"value"}; });
        let(appEnvironment, ^NSDictionary *{ return @{@"key2" : @"value2"}; });
        let(extras, ^NSDictionary *{ return @{@"extraKey": [@"extraValue" dataUsingEncoding:NSUTF8StringEncoding]}; });
        AMAGZipDataEncoder *const encoder = [[AMAGZipDataEncoder alloc] init];
        AMAEventValueFactory *const eventValueFactory = [[AMAEventValueFactory alloc] init];
        
        beforeEach(^{
            builder = [[AMAEventBuilder alloc] initWithStateStorage:stateStorage
                                                        preloadInfo:nil
                                                  eventValueFactory:eventValueFactory
                                                        gZipEncoder:encoder
                                              eventComposerProvider:eventComposerProvider];
        });
        
        context(@"String events", ^{
            NSUInteger const eventType = 199;
            NSString *const name = @"event name";
            NSString *const value = @"event value";
            __block AMAEvent *event;
            __block NSError *error;
            beforeEach(^{
                event = [builder eventWithType:eventType
                                          name:name
                                         value:value
                              eventEnvironment:eventEnvironment
                                appEnvironment:appEnvironment
                                        extras:extras
                                         error:&error];
            });
            it(@"Should set event type", ^{
                [[error should] beNil];
                [[theValue(event.type) should] equal:theValue(eventType)];
            });
            it(@"Should set event name", ^{
                [[error should] beNil];
                [[event.name should] equal:name];
            });
            it(@"Should set event value", ^{
                [[error should] beNil];
                [[[event.value dataWithError:nil] should] equal:[value dataUsingEncoding:NSUTF8StringEncoding]];
            });
            it(@"Should set event enviromnent", ^{
                [[error should] beNil];
                [[event.eventEnvironment should] equal:eventEnvironment];
            });
            it(@"Should set app enviromnent", ^{
                [[error should] beNil];
                [[event.appEnvironment should] equal:appEnvironment];
            });
            it(@"Should set event extras", ^{
                [[error should] beNil];
                [[event.extras should] equal:extras];
            });
            it(@"Should be passed to composer", ^{
                [[eventComposerProvider should] receive:@selector(composerForType:) withArguments:theValue(eventType)];
                [[eventComposer should] receive:@selector(compose:)];
                [builder eventWithType:eventType
                                  name:name
                                 value:value
                      eventEnvironment:eventEnvironment
                        appEnvironment:appEnvironment
                                extras:extras
                                 error:&error];
            });
        });
        context(@"Binary events", ^{
            NSUInteger const eventType = 120;
            NSString *const eventName = @"name";
            NSData *__block data = [@"data" dataUsingEncoding:NSUTF8StringEncoding];
            __block AMAEvent *event;
            __block NSError *error;
            void(^buildEvent)(BOOL) = ^(BOOL gZipped) {
                event = [builder binaryEventWithType:eventType
                                                data:data
                                                name:eventName
                                             gZipped:gZipped
                                    eventEnvironment:eventEnvironment
                                      appEnvironment:appEnvironment
                                              extras:extras
                                      bytesTruncated:5
                                               error:&error];
            };
            beforeEach(^{
                buildEvent(YES);
            });
            
            it(@"Should set event type", ^{
                [[error should] beNil];
                [[theValue(event.type) should] equal:theValue(eventType)];
            });
            it(@"Should gzip event value", ^{
                [[error should] beNil];
                NSData *expected = [encoder encodeData:data error:nil];
                [[[event.value dataWithError:nil] should] equal:expected];
            });
            it(@"Should return gZipped value if gZipped is true", ^{
                [[error should] beNil];
                NSData *expected = [encoder encodeData:data error:nil];
                [[[event.value gzippedDataWithError:nil] should] equal:expected];
            });
            it(@"Should return nil if gZipped is false", ^{
                buildEvent(NO);
                [[error should] beNil];
                [[[event.value gzippedDataWithError:nil] should] beNil];
            });
            it(@"Should truncate data if gZipped is false", ^{
                int maxSize = 230 * 1024;
                int overLimit = maxSize + 100;
                void *bytes = malloc(overLimit);
                NSData *bigData = [NSData dataWithBytes:bytes length:overLimit];
                free(bytes);
                
                data = bigData;
                buildEvent(NO);
                
                [[error should] beNil];
                [[theValue([event.value dataWithError:nil].length) should] equal:theValue(maxSize)];
            });
            it(@"Should set event enviromnent", ^{
                [[error should] beNil];
                [[event.eventEnvironment should] equal:eventEnvironment];
            });
            it(@"Should set app enviromnent", ^{
                [[error should] beNil];
                [[event.appEnvironment should] equal:appEnvironment];
            });
            it(@"Should set event extras", ^{
                [[error should] beNil];
                [[event.extras should] equal:extras];
            });
            it(@"Should add bytes truncated", ^{
                [[error should] beNil];
                [[theValue(event.bytesTruncated) should] equal:theValue(5)];
            });
            it(@"Should set event name", ^{
                [[error should] beNil];
                [[event.name should] equal:eventName];
            });
            it(@"Should be passed to composer", ^{
                [[eventComposerProvider should] receive:@selector(composerForType:) withArguments:theValue(eventType)];
                [[eventComposer should] receive:@selector(compose:)];
                buildEvent(YES);
            });
            it(@"Should and fill the error when gZipEncoder fails", ^{
                NSError *expectedError = [NSError errorWithDomain:@"TestDomain" code:1234 userInfo:nil];
                
                [encoder stub:@selector(encodeData:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:expectedError];
                    return nil;
                }];
                
                NSError *actualError = nil;
                event = [builder binaryEventWithType:eventType
                                                data:data
                                                name:nil
                                             gZipped:YES
                                    eventEnvironment:eventEnvironment
                                      appEnvironment:appEnvironment
                                              extras:extras
                                      bytesTruncated:0
                                               error:&actualError];
                
                [[theValue(actualError.code) should] equal:theValue(expectedError.code)];
                [[actualError.domain should] equal:expectedError.domain];
            });
        });
        context(@"File events", ^{
            NSUInteger const eventType = 121;
            NSData *__block data = [@"data" dataUsingEncoding:NSUTF8StringEncoding];
            NSString *const fileName = @"file";
            __block AMAEvent *event;
            __block NSError *error;
            void(^buildEvent)(BOOL, BOOL, BOOL) = ^(BOOL encrypted,
                                                    BOOL truncated,
                                                    BOOL gZipped) {
                event = [builder fileEventWithType:eventType
                                              data:data
                                          fileName:fileName
                                           gZipped:gZipped
                                         encrypted:encrypted
                                         truncated:truncated
                                  eventEnvironment:eventEnvironment
                                    appEnvironment:appEnvironment
                                            extras:extras
                                             error:&error];
            };
            beforeEach(^{
                buildEvent(YES, YES, YES);
            });
            
            it(@"Should set event type", ^{
                [[error should] beNil];
                [[theValue(event.type) should] equal:theValue(eventType)];
            });
            it(@"Should set event enviromnent", ^{
                [[error should] beNil];
                [[event.eventEnvironment should] equal:eventEnvironment];
            });
            it(@"Should set app enviromnent", ^{
                [[error should] beNil];
                [[event.appEnvironment should] equal:appEnvironment];
            });
            it(@"Should set event extras", ^{
                [[error should] beNil];
                [[event.extras should] equal:extras];
            });
            it(@"Should set event file name", ^{
                [[error should] beNil];
                NSString *path = ((AMAFileEventValue *)event.value).relativeFilePath;
                [[path should] equal:fileName];
            });
            it(@"Should set event file encryption type if encrypted is true without gzip", ^{
                buildEvent(YES, YES, NO);
                
                [[error should] beNil];
                AMAEventEncryptionType encryption = ((AMAFileEventValue *)event.value).encryptionType;
                [[theValue(encryption) should] equal:theValue(AMAEventEncryptionTypeAESv1)];
            });
            it(@"Should set event file encryption type gzip if gzip is true", ^{
                [[error should] beNil];
                AMAEventEncryptionType encryption = ((AMAFileEventValue *)event.value).encryptionType;
                [[theValue(encryption) should] equal:theValue(AMAEventEncryptionTypeGZip)];
            });
            it(@"Should set event file encryption type if encrypted is false", ^{
                buildEvent(NO, YES, NO);
                [[error should] beNil];
                AMAEventEncryptionType encryption = ((AMAFileEventValue *)event.value).encryptionType;
                [[theValue(encryption) should] equal:theValue(AMAEventEncryptionTypeNoEncryption)];
            });
            it(@"Should use no encryption for file storage and gZip for file value", ^{
                buildEvent(YES, YES, YES);
                
                [[error should] beNil];
                NSData *expected = [encoder encodeData:data error:nil];
                
                [[[event.value gzippedDataWithError:nil] should] equal:expected];
                [[[event.value dataWithError:nil] should] equal:data];
            });
            it(@"Should be passed to composer", ^{
                [[eventComposerProvider should] receive:@selector(composerForType:) withArguments:theValue(eventType)];
                [[eventComposer should] receive:@selector(compose:)];
                buildEvent(YES, YES, YES);
            });
            it(@"Should set file name if passed empty", ^{
                KWCaptureSpy *fileNameSpy = [eventValueFactory captureArgument:@selector(fileEventValue:
                                                                                         fileName:
                                                                                         gZipped:
                                                                                         encryptionType:
                                                                                         truncationType:
                                                                                         bytesTruncated:
                                                                                         error:)
                                                                       atIndex:1];
                
                event = [builder fileEventWithType:eventType
                                              data:data
                                          fileName:@""
                                           gZipped:YES
                                         encrypted:YES
                                         truncated:YES
                                  eventEnvironment:eventEnvironment
                                    appEnvironment:appEnvironment
                                            extras:extras
                                             error:&error];
                [[fileNameSpy.argument should] containString:@".event"];
            });
            context(@"Truncation", ^{
                const int maxSize = 230 * 1024;
                NSData *(^createBigData)(int) = ^(int size) {
                    void *bytes = malloc(size);
                    NSData *bigData = [NSData dataWithBytes:bytes length:size];
                    free(bytes);
                    return bigData;
                };
                it(@"Should truncate value", ^{
                    data = createBigData(maxSize + 100);
                    buildEvent(YES, YES, NO);
                    
                    [[error should] beNil];
                    [[theValue([event.value dataWithError:nil].length) should] equal:theValue(maxSize)];
                });
                it(@"Should truncate value after gzip", ^{
                    data = createBigData(maxSize + 100);
                    [encoder stub:@selector(encodeData:error:) andReturn:data];
                    buildEvent(YES, YES, YES);
                    
                    [[error should] beNil];
                    NSData *truncated = [data subdataWithRange:NSMakeRange(0, maxSize)];
                    [[[event.value gzippedDataWithError:nil] should] equal:truncated];
                });
            });
        });
        
        context(@"Session extras", ^{
            NSString *const extrasKey1 = @"extrasKey1";
            NSString *const extrasKey2 = @"extrasKey2";
            NSData *const sessionExtras = [@"sessionExtras" dataUsingEncoding:NSUTF8StringEncoding];
            NSData *const eventExtras = [@"eventExtras" dataUsingEncoding:NSUTF8StringEncoding];
            __block AMAEvent *event;
            
            beforeEach(^{
                NSObject *extrasComposer = [KWMock nullMockForProtocol:@protocol(AMAExtrasComposer)];
                [eventComposer stub:@selector(compose:) withBlock:^id(NSArray *params) {
                    AMAEvent *eventToCompose = (AMAEvent *)params[0];
                    eventToCompose.extras = @{ extrasKey1 : sessionExtras,
                                               extrasKey2 : sessionExtras };
                    return nil;
                }];
                
                [eventComposer stub:@selector(extrasComposer) andReturn:extrasComposer];
            });
            
            it(@"Should ignore session extras for reserved event types", ^{
                event = [builder eventWithType:12
                                          name:@"name"
                                         value:@"value"
                              eventEnvironment:eventEnvironment
                                appEnvironment:appEnvironment
                                        extras:@{ extrasKey1 : eventExtras }
                                         error:nil];
                
                [[event.extras should] equal:@{ extrasKey1 : eventExtras,
                                                extrasKey2 : sessionExtras }];
            });
            
            it(@"Should merge session extras with event extras for non reserved event types", ^{
                NSArray *reservedEventTypes = @[@1, @12, @13];
                NSInteger randomEventType;
                do {
                    randomEventType = arc4random_uniform(41) + 1;
                } while ([reservedEventTypes containsObject:@(randomEventType)] == YES);
                
                event = [builder eventWithType:randomEventType
                                          name:@"name"
                                         value:@"value"
                              eventEnvironment:eventEnvironment
                                appEnvironment:appEnvironment
                                        extras:@{ extrasKey1 : eventExtras }
                                         error:nil];
                
                [[event.extras should] equal:@{ extrasKey1 : sessionExtras,
                                                extrasKey2 : sessionExtras }];
            });
        });
    });
});

SPEC_END
