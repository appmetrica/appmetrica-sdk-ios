
#import <Kiwi/Kiwi.h>
#import "AMACore.h"
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

    // TODO(bamx23): Add more tests. Especially to cover truncation

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
        context(@"EVENT_AUTO_APP_OPEN", ^{
            context(@"Value", ^{
                beforeEach(^{
                    valueSpy = [valueFactory captureArgument:@selector(stringEventValue:bytesTruncated:) atIndex:0];
                    event = [builder autoAppOpenEvent:@{@"link":@"l"} error:nil];
                });
                it(@"Should contain valid value", ^{
                    [[valueSpy.argument should] equal:@"{\"link\":\"l\"}"];
                });
                it(@"Should have valid value", ^{
                    [[((NSObject *)event.value) should] equal:stringValue];
                    [[event.name should] equal:@"auto_app_open"];
                });
            });
            it(@"Should be passed to composer", ^{
                [[eventComposerProvider should] receive:@selector(composerForType:) withArguments:theValue(AMAEventTypeStatboxExp)];
                [[eventComposer should] receive:@selector(compose:)];
                [builder autoAppOpenEvent:@{@"link":@"l"} error:nil];
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
        context(@"Сustom event", ^{
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
            it(@"Should not create event with internal type", ^{
                event = [builder eventWithType:internalEventType
                                          name:nil
                                         value:nil
                              eventEnvironment:nil
                                        extras:nil
                                         error:nil];
                [[event should] beNil];
            });
            context(@"Allowed type", ^{
                NSString *name = @"NAME";
                NSString *value = @"VALUE";
                NSDictionary *eventEnvironment = @{ @"foo": @"bar" };
                context(@"Event fields", ^{
                    beforeEach(^{
                        valueSpy = [valueFactory captureArgument:@selector(stringEventValue:bytesTruncated:) atIndex:0];
                        event = [builder eventWithType:allowedEventType
                                                  name:name
                                                 value:value
                                      eventEnvironment:eventEnvironment
                                                extras:nil
                                                 error:nil];
                    });
                    it(@"Should construct event", ^{
                        [[event should] beNonNil];
                    });
                    it(@"Should construct event with type", ^{
                        [[theValue(event.type) should] equal:theValue(allowedEventType)];
                    });
                    it(@"Should construct event with name", ^{
                        [[event.name should] equal:name];
                    });
                    it(@"Should construct event with value", ^{
                        [[valueSpy.argument should] equal:value];
                    });
                    it(@"Should construct event with event environment", ^{
                        [[event.errorEnvironment should] equal:eventEnvironment];
                    });
                });
                it(@"Should be passed to composer", ^{
                    [[eventComposerProvider should] receive:@selector(composerForType:) withArguments:theValue(allowedEventType)];
                    [[eventComposer should] receive:@selector(compose:)];
                    [builder eventWithType:allowedEventType
                                      name:name
                                     value:value
                          eventEnvironment:eventEnvironment
                                    extras:nil
                                     error:nil];
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
        context(@"When building an event with internal parameters", ^{
            __block AMACustomEventParameters *parameters = nil;

            beforeEach(^{
                parameters = [[AMACustomEventParameters alloc] initWithEventType:1];
                parameters.name = @"TestEvent";
                parameters.data = [@"TestData" dataUsingEncoding:NSUTF8StringEncoding];
                parameters.valueType = AMAEventValueTypeFile;
                parameters.GZipped = YES;
                parameters.appEnvironment = @{@"Key": @"Value"};
                parameters.errorEnvironment = @{@"ErrorKey": @"ErrorValue"};
                parameters.bytesTruncated = 5;
                parameters.extras = @{@"extraKey": [@"extraValue" dataUsingEncoding:NSUTF8StringEncoding]};
                parameters.appState = [[AMAApplicationState alloc] init];
                parameters.isPast = YES;
            });

            it(@"should call gZipEncoder when useGZip is YES", ^{
                [[gZipEncoder should] receive:@selector(encodeData:error:) andReturn:[@"GZippedTestData" dataUsingEncoding:NSUTF8StringEncoding]];
                [builder eventWithInternalParameters:parameters error:nil];
            });

            it(@"should call fileEventWithValue when valueType is AMAEventValueTypeFile", ^{
                [[valueFactory should] receive:@selector(fileEventValue:fileName:encryptionType:truncationType:bytesTruncated:error:)];
                [builder eventWithInternalParameters:parameters error:nil];
            });

            it(@"should call binaryEventValue when valueType is AMAEventValueTypeBinary", ^{
                parameters.valueType = AMAEventValueTypeBinary;
                [[valueFactory should] receive:@selector(binaryEventValue:gZipped:bytesTruncated:)];
                [builder eventWithInternalParameters:parameters error:nil];
            });

            it(@"Should raise when valueType is invalid", ^{
                parameters.valueType = 999; // Invalid value type
                [[theBlock(^{
                    AMAEvent *event = [builder eventWithInternalParameters:parameters error:nil];
                }) should] raise];
            });
            
            it(@"should log a warning and fill the error when gZipEncoder fails", ^{
                NSError *expectedError = [NSError errorWithDomain:@"TestDomain" code:1234 userInfo:nil];
                
                [gZipEncoder stub:@selector(encodeData:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:expectedError];
                    return nil;
                }];
                
                NSError *actualError = nil;
                [builder eventWithInternalParameters:parameters error:&actualError];
                
                [[theValue(actualError.code) should] equal:theValue(expectedError.code)];
                [[actualError.domain should] equal:expectedError.domain];
            });
            
            context(@"When building an event with internal parameters", ^{
                let(eventValueMock, ^id{ return [KWMock mockForProtocol:@protocol(AMAEventValueProtocol)]; });
                let(parameters, ^{
                    AMACustomEventParameters *parameters = [[AMACustomEventParameters alloc] initWithEventType:1];
                    parameters.name = @"TestEvent";
                    parameters.data = [@"TestData" dataUsingEncoding:NSUTF8StringEncoding];
                    parameters.valueType = AMAEventValueTypeFile;
                    parameters.GZipped = YES;
                    parameters.appEnvironment = @{@"Key": @"Value"};
                    parameters.errorEnvironment = @{@"ErrorKey": @"ErrorValue"};
                    parameters.extras = @{@"ExtraKey": [@"ExtraValue" dataUsingEncoding:NSUTF8StringEncoding]};
                    parameters.bytesTruncated = 5;
                    parameters.appState = [AMAApplicationState objectWithDictionaryRepresentation:
                                           @{@"appVersionName": @"1.0", @"appDebuggable": @NO}];
                    parameters.isPast = NO;
                    return parameters;
                });
                
                beforeEach(^{
                    [valueFactory stub:@selector(fileEventValue:fileName:encryptionType:truncationType:bytesTruncated:error:) andReturn:eventValueMock];
                    [valueFactory stub:@selector(binaryEventValue:gZipped:bytesTruncated:) andReturn:eventValueMock];
                    [valueFactory stub:@selector(stringEventValue:bytesTruncated:) andReturn:eventValueMock];
                });

                it(@"should correctly fill the created event with the given parameters", ^{
                    AMAEvent *event = [builder eventWithInternalParameters:parameters error:nil];
                    
                    [[theValue(event.type) should] equal:theValue(parameters.eventType)];
                    [[event.name should] equal:parameters.name];
                    [[(NSObject *)event.value should] equal:eventValueMock];
                    [[event.appEnvironment should] equal:parameters.appEnvironment];
                    [[event.errorEnvironment should] equal:parameters.errorEnvironment];
                    [[event.extras should] equal:parameters.extras];
                    [[theValue(event.bytesTruncated) should] equal:theValue(parameters.bytesTruncated)];
                });
                
                it(@"should set event date from parameters only when event is in the past", ^{
                    NSDate *pastDate = [[NSDate date] dateByAddingTimeInterval: -3600]; // 1 hour ago
                    parameters.creationDate = pastDate;
                    parameters.isPast = YES;
                    
                    AMAEvent *event = [builder eventWithInternalParameters:parameters error:nil];
                    [[event.createdAt should] equal:pastDate];
                });
                
                it(@"should use current time when event is not in the past", ^{
                    // Set a future date in parameters, but since isInThePast is NO, current date will be used
                    NSDate *futureDate = [[NSDate date] dateByAddingTimeInterval: 3600]; // 1 hour from now
                    parameters.creationDate = futureDate;
                    parameters.isPast = NO;
                    
                    AMAEvent *event = [builder eventWithInternalParameters:parameters error:nil];
                    
                    // Check if event.createdAt is close to the current date within a 1-second tolerance
                    [[theValue(event.createdAt.timeIntervalSince1970) should] equal:NSDate.date.timeIntervalSince1970
                                                                          withDelta:1.0];
                });
            });
        });
    });
});

SPEC_END
