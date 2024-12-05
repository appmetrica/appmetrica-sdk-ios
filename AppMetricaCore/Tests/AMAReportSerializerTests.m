
#import <Kiwi/Kiwi.h>
#import <CoreLocation/CoreLocation.h>
#import <AppMetricaProtobufUtils/AppMetricaProtobufUtils.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AppMetrica.pb-c.h"
#import "AMAAppStateManagerTestHelper.h"
#import "AMAApplicationStateManager.h"
#import "AMABinaryEventValue.h"
#import "AMADate.h"
#import "AMAEvent.h"
#import "AMAFileEventValue.h"
#import "AMAReportEventsBatch.h"
#import "AMAReportRequestModel.h"
#import "AMAReportSerializer.h"
#import "AMASession.h"
#import "AMAStringEventValue.h"
#import "AMAAppEnvironmentValidator.h"

SPEC_BEGIN(AMAReportSerializerTests)

describe(@"AMAReportSerializer", ^{

    double const EPSILON = 0.0001;

    NSString *const apiKey = @"API_KEY";
    NSString *const attributionID = @"ATTRIBUTION_ID";
    NSDictionary *const appEnvironment = @{ @"app": @"environment" };

    CLLocation *const location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(53.891059, 27.526119)
                                                               altitude:295.0
                                                     horizontalAccuracy:10.0
                                                       verticalAccuracy:23.0
                                                                 course:115.0
                                                                  speed:4.2
                                                              timestamp:[NSDate date]];

    AMAProtobufAllocator *__block allocator = nil;
    AMAAppStateManagerTestHelper *__block appStateHelper = nil;
    AMAApplicationState *__block appState = nil;
    NSObject<AMAReportSerializerDelegate> *__block delegate = nil;
    AMAReportSerializer *__block serializer = nil;
    AMAAppEnvironmentValidator *__block validator = nil;

    AMAReportRequestModel *__block model = nil;
    NSUInteger __block sizeLimit = 0;
    NSError *__block filledError = nil;
    Ama__ReportMessage *__block reportData = NULL;

    void (^__block fillReport)(void) = nil;

    beforeEach(^{
        allocator = [[AMAProtobufAllocator alloc] init];
        appStateHelper = [[AMAAppStateManagerTestHelper alloc] init];
        [appStateHelper stubApplicationState];
        appState = AMAApplicationStateManager.applicationState;
        delegate = [KWMock nullMockForProtocol:@protocol(AMAReportSerializerDelegate)];
        validator = [AMAAppEnvironmentValidator nullMock];

        serializer = [[AMAReportSerializer alloc] initWithAppEnvironmentValidator:validator];
        serializer.delegate = delegate;
        sizeLimit = NSUIntegerMax;
        filledError = nil;
        reportData = NULL;

        fillReport = ^{
            NSData *data = [serializer dataForRequestModel:model
                                                 sizeLimit:sizeLimit
                                                     error:&filledError];
            if (data != nil) {
                reportData = ama__report_message__unpack(allocator.protobufCAllocator, data.length, data.bytes);
            }
        };
    });

    NSString *(^convertString)(char *) = ^(char *cString) {
        return cString == NULL ? nil : [NSString stringWithUTF8String:cString];
    };

    AMAReportRequestModel *(^modelWithSessionAndEvent)(AMASession *, AMAEvent *) = ^(AMASession *session, AMAEvent *event) {
        AMAReportEventsBatch *batch = nil;
        if (session != nil) {
            NSArray *events = event != nil ? @[ event ] : @[];
            batch = [[AMAReportEventsBatch alloc] initWithSession:session
                                                   appEnvironment:appEnvironment
                                                           events:events];
        }
        NSArray *batches = batch != nil ? @[ batch ] : @[];
        return [AMAReportRequestModel reportRequestModelWithApiKey:apiKey
                                                     attributionID:attributionID
                                                    appEnvironment:appEnvironment
                                                          appState:appState
                                                  inMemoryDatabase:NO
                                                     eventsBatches:batches];
    };

    context(@"Valid", ^{
        AMASession *__block session = nil;
        AMAEvent *__block event = nil;
        beforeEach(^{
            session = [[AMASession alloc] init];
            session.appState = appState;
            event = [[AMAEvent alloc] init];

            dispatch_block_t baseFillReport = fillReport;
            fillReport = ^{
                model = modelWithSessionAndEvent(session, event);
                baseFillReport();
            };
        });
        it(@"Should fill data", ^{
            fillReport();
            [[thePointerValue(reportData) shouldNot] equal:thePointerValue(NULL)];
        });
        it(@"Should not fill error", ^{
            fillReport();
            [[filledError should] beNil];
        });
        context(@"Report", ^{
            context(@"Request parameters", ^{
                beforeEach(^{
                    fillReport();
                });
                it(@"Should contain valid UUID", ^{
                    [[convertString(reportData->report_request_parameters->uuid) should] equal:appState.UUID];
                });
                it(@"Should contain valid deviceID", ^{
                    [[convertString(reportData->report_request_parameters->device_id) should] equal:appState.deviceID];
                });
            });
            context(@"App Environment", ^{
                context(@"Valid", ^{
                    beforeEach(^{
                        [validator stub:@selector(validateAppEnvironmentKey:) andReturn:theValue(YES)];
                        [validator stub:@selector(validateAppEnvironmentValue:) andReturn:theValue(YES)];
                        
                        fillReport();
                    });
                    it(@"Should have valid count", ^{
                        [[theValue(reportData->n_app_environment) should] equal:theValue(1)];
                    });
                    it(@"Should have valid key", ^{
                        [[convertString(reportData->app_environment[0]->name) should] equal:appEnvironment.allKeys.firstObject];
                    });
                    it(@"Should have valid value", ^{
                        [[convertString(reportData->app_environment[0]->value) should] equal:appEnvironment.allValues.firstObject];
                    });
                });
                context(@"Invalid", ^{
                    beforeEach(^{
                        [validator stub:@selector(validateAppEnvironmentKey:) andReturn:theValue(NO)];
                        [validator stub:@selector(validateAppEnvironmentValue:) andReturn:theValue(NO)];
                        
                        fillReport();
                    });
                    it(@"Should have valid count", ^{
                        [[theValue(reportData->n_app_environment) should] equal:theValue(1)];
                    });
                    it(@"Should have valid key", ^{
                        [[convertString(reportData->app_environment[0]->name) should] beEmpty];
                    });
                    it(@"Should have valid value", ^{
                        [[convertString(reportData->app_environment[0]->value) should] beEmpty];
                    });
                });
            });
            it(@"Should have valid sessions count", ^{
                fillReport();
                [[theValue(reportData->n_sessions) should] equal:theValue(1)];
            });
            context(@"Session", ^{
                Ama__ReportMessage__Session *__block sessionData = NULL;
                beforeEach(^{
                    dispatch_block_t baseFillSimpleReport = fillReport;
                    fillReport = ^{
                        baseFillSimpleReport();
                        sessionData = reportData->sessions[0];
                    };
                });
                it(@"Should have valid ID", ^{
                    long long value = 10000000023;
                    session.sessionID = [NSNumber numberWithLongLong:value];
                    fillReport();
                    [[theValue(sessionData->id) should] equal:theValue(value)];
                });
                context(@"Start time", ^{
                    NSDate *const deviceDate = [NSDate date];
                    NSInteger const timeZoneOffset = 10800;
                    beforeEach(^{
                        session.startDate = [[AMADate alloc] init];
                        session.startDate.deviceDate = deviceDate;
                        NSTimeZone *systemTimeZone = [NSTimeZone nullMock];
                        [systemTimeZone stub:@selector(secondsFromGMT) andReturn:theValue(timeZoneOffset)];
                        [NSTimeZone stub:@selector(systemTimeZone) andReturn:systemTimeZone];
                        fillReport();
                    });
                    it(@"Should have valid timestamp", ^{
                        [[theValue(sessionData->session_desc->start_time->timestamp) should] equal:deviceDate.timeIntervalSince1970
                                                                                         withDelta:EPSILON];
                    });
                    it(@"Should have valid server time zone", ^{
                        [[theValue(sessionData->session_desc->start_time->time_zone) should] equal:theValue(timeZoneOffset)];
                    });
                });
                it(@"Should have valid locale", ^{
                    fillReport();
                    [[convertString(sessionData->session_desc->locale) should] equal:appState.locale];
                });
                context(@"Session type", ^{
                    it(@"Should be foreground", ^{
                        session.type = AMASessionTypeGeneral;
                        fillReport();
                        id expected =
                            theValue(AMA__REPORT_MESSAGE__SESSION__SESSION_DESC__SESSION_TYPE__SESSION_FOREGROUND);
                        [[theValue(sessionData->session_desc->session_type) should] equal:expected];
                    });
                    it(@"Should be background", ^{
                        session.type = AMASessionTypeBackground;
                        fillReport();
                        id expected =
                            theValue(AMA__REPORT_MESSAGE__SESSION__SESSION_DESC__SESSION_TYPE__SESSION_BACKGROUND);
                        [[theValue(sessionData->session_desc->session_type) should] equal:expected];
                    });
                });
                it(@"Should have valid events count", ^{
                    fillReport();
                    [[theValue(sessionData->n_events) should] equal:theValue(1)];
                });
                context(@"Event", ^{
                    Ama__ReportMessage__Session__Event *__block eventData = NULL;
                    beforeEach(^{
                        dispatch_block_t baseFillSimpleReport = fillReport;
                        fillReport = ^{
                            baseFillSimpleReport();
                            eventData = sessionData->events[0];
                        };
                    });
                    it(@"Should have valid number in session", ^{
                        NSUInteger value = 23;
                        event.sequenceNumber = value;
                        fillReport();
                        [[theValue(eventData->number_in_session) should] equal:theValue(value)];
                    });
                    it(@"Should have valid number of type", ^{
                        NSUInteger value = 42;
                        event.numberOfType = value;
                        fillReport();
                        [[theValue(eventData->number_of_type) should] equal:theValue(value)];
                    });
                    it(@"Should have valid global number", ^{
                        NSUInteger value = 108;
                        event.globalNumber = value;
                        fillReport();
                        [[theValue(eventData->global_number) should] equal:theValue(value)];
                    });
                    it(@"Should have valid time", ^{
                        NSTimeInterval value = 23.42;
                        event.timeSinceSession = value;
                        fillReport();
                        [[theValue(eventData->time) should] equal:theValue(23)];
                    });
                    context(@"Event source", ^{
                        it(@"Should have native source", ^{
                            event.source = AMAEventSourceNative;
                            fillReport();
                            [[theValue(eventData->source) should]
                                equal:theValue(AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_SOURCE__NATIVE)];
                        });
                        it(@"Should have JS source", ^{
                            event.source = AMAEventSourceJs;
                            fillReport();
                            [[theValue(eventData->source) should]
                                equal:theValue(AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_SOURCE__JS)];
                        });
                    });
                    context(@"Event attribution id changed", ^{
                        it(@"Should have true", ^{
                            event.attributionIDChanged = YES;
                            fillReport();
                            [[theValue(eventData->attribution_id_changed) should] equal:theValue(true)];
                        });
                        it(@"Should have false", ^{
                            event.source = NO;
                            fillReport();
                            [[theValue(eventData->attribution_id_changed) should] equal:theValue(false)];
                        });
                    });
                    context(@"Event open id", ^{
                        context(@"Nil", ^{
                            beforeEach(^{
                                event.openID = nil;
                                fillReport();
                            });
                            it(@"has_open_id should be true", ^{
                                [[theValue(eventData->has_open_id) should] beYes];
                            });
                            it(@"open_id should be 1", ^{
                                [[theValue(eventData->open_id) should] equal:theValue(1)];
                            });
                        });
                        context(@"Not nil", ^{
                            NSUInteger openID = 777888;
                            beforeEach(^{
                                event.openID = @(openID);
                                fillReport();
                            });
                            it(@"has_open_id should be true", ^{
                                [[theValue(eventData->has_open_id) should] beYes];
                            });
                            it(@"open_id should be correct", ^{
                                [[theValue(eventData->open_id) should] equal:theValue(openID)];
                            });
                        });
                    });
                    context(@"Event type", ^{
                        it(@"Should have EVENT_CLIENT", ^{
                            event.type = AMAEventTypeClient;
                            fillReport();
                            [[theValue(eventData->type) should] equal:theValue(AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_CLIENT)];
                        });
                        it(@"Should have EVENT_INIT", ^{
                            event.type = AMAEventTypeInit;
                            fillReport();
                            [[theValue(eventData->type) should] equal:theValue(AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_INIT)];
                        });
                        it(@"Should have custom type", ^{
                            NSUInteger value = 108;
                            event.type = value;
                            fillReport();
                            [[theValue(eventData->type) should] equal:theValue(value)];
                        });
                    });
                    it(@"Should have valid name", ^{
                        NSString *value = @"EVENT_NAME";
                        event.name = value;
                        fillReport();
                        [[convertString(eventData->name) should] equal:value];
                    });
                    context(@"Value", ^{
                        it(@"Should have string value", ^{
                            NSString *value = @"EVENT_VALUE";
                            AMAStringEventValue *eventValue = [[AMAStringEventValue alloc] initWithValue:value];
                            event.value = eventValue;
                            fillReport();
                            NSData *result = [AMAProtobufUtilities dataForBinaryData:&eventData->value
                                                                                 has:eventData->has_value];
                            [[result should] equal:[value dataUsingEncoding:NSUTF8StringEncoding]];
                        });
                        context(@"Binary", ^{
                            NSData *value = [@"EVENT_VALUE" dataUsingEncoding:NSUTF8StringEncoding];
                            context(@"Raw", ^{
                                beforeEach(^{
                                    AMABinaryEventValue *eventValue = [[AMABinaryEventValue alloc] initWithData:value
                                                                                                        gZipped:NO];
                                    event.value = eventValue;
                                    fillReport();
                                });
                                it(@"Should have value", ^{
                                    NSData *result = [AMAProtobufUtilities dataForBinaryData:&eventData->value
                                                                                         has:eventData->has_value];
                                    [[result should] equal:value];
                                });
                                it(@"Should have no encoding type", ^{
                                    id expected = theValue(AMA__REPORT_MESSAGE__SESSION__EVENT__ENCODING_TYPE__NONE);
                                    [[theValue(eventData->encoding_type) should] equal:expected];
                                });
                            });
                            context(@"GZipped", ^{
                                beforeEach(^{
                                    AMABinaryEventValue *eventValue = [[AMABinaryEventValue alloc] initWithData:value
                                                                                                        gZipped:YES];
                                    event.value = eventValue;
                                    fillReport();
                                });
                                it(@"Should have value", ^{
                                    NSData *result = [AMAProtobufUtilities dataForBinaryData:&eventData->value
                                                                                         has:eventData->has_value];
                                    [[result should] equal:value];
                                });
                                it(@"Should have no encoding type", ^{
                                    id expected = theValue(AMA__REPORT_MESSAGE__SESSION__EVENT__ENCODING_TYPE__GZIP);
                                    [[theValue(eventData->encoding_type) should] equal:expected];
                                });
                            });
                        });
                        context(@"File", ^{
                            NSData *const fileData = [@"EVENT_VALUE" dataUsingEncoding:NSUTF8StringEncoding];
                            AMAFileEventValue *__block eventValue = nil;
                            beforeEach(^{
                                NSString *const path = @"/path/to/file";
                                AMAEventEncryptionType const encryptionType = AMAEventEncryptionTypeNoEncryption;
                                eventValue = [[AMAFileEventValue alloc] initWithRelativeFilePath:path
                                                                                  encryptionType:encryptionType];
                                [eventValue stub:@selector(dataWithError:) andReturn:fileData];
                                [eventValue stub:@selector(empty) andReturn:theValue(NO)];
                                event.value = eventValue;
                            });
                            __auto_type stubGZipped = ^{
                                [eventValue stub:@selector(encryptionType)
                                       andReturn:theValue(AMAEventEncryptionTypeGZip)];
                                [eventValue stub:@selector(dataWithError:)
                                       andReturn:[@"OTHER" dataUsingEncoding:NSUTF8StringEncoding]];
                                [eventValue stub:@selector(gzippedDataWithError:) andReturn:fileData];
                            };
                            it(@"Should not call delegate", ^{
                                [[delegate shouldNot] receive:@selector(reportSerializer:didFailedToReadFileOfEvent:)];
                                fillReport();
                            });
                            it(@"Should have valid data", ^{
                                fillReport();
                                NSData *result = [AMAProtobufUtilities dataForBinaryData:&eventData->value
                                                                                     has:eventData->has_value];
                                [[result should] equal:fileData];
                            });
                            it(@"Should have valid gzipped", ^{
                                stubGZipped();
                                fillReport();
                                NSData *result = [AMAProtobufUtilities dataForBinaryData:&eventData->value
                                                                                     has:eventData->has_value];
                                [[result should] equal:fileData];
                            });
                            context(@"Encoding type", ^{
                                it(@"Should have no encoding for NoEncryption", ^{
                                    [eventValue stub:@selector(encryptionType)
                                           andReturn:theValue(AMAEventEncryptionTypeNoEncryption)];
                                    fillReport();
                                    [[theValue(eventData->has_encoding_type) should] beNo];
                                });
                                it(@"Should have valid encoding for GZip", ^{
                                    stubGZipped();
                                    fillReport();
                                    [[theValue(eventData->has_encoding_type) should] beYes];
                                    id expected =
                                        theValue(AMA__REPORT_MESSAGE__SESSION__EVENT__ENCODING_TYPE__GZIP);
                                    [[theValue(eventData->encoding_type) should] equal:expected];
                                });
                                it(@"Should have no encoding for AES", ^{
                                    [eventValue stub:@selector(encryptionType)
                                           andReturn:theValue(AMAEventEncryptionTypeAESv1)];
                                    fillReport();
                                    [[theValue(eventData->has_encoding_type) should] beNo];
                                });
                            });
                        });
                    });
                    context(@"Location", ^{
                        context(@"Full", ^{
                            beforeEach(^{
                                event.location = location;
                                fillReport();
                            });
                            it(@"Should have valid latitude", ^{
                                [[theValue(eventData->location->lat) should] equal:location.coordinate.latitude
                                                                         withDelta:EPSILON];
                            });
                            it(@"Should have valid latitude", ^{
                                [[theValue(eventData->location->lon) should] equal:location.coordinate.longitude
                                                                         withDelta:EPSILON];
                            });
                            it(@"Should have altitude", ^{
                                [[theValue(eventData->location->has_altitude) should] beYes];
                            });
                            it(@"Should have valid altitude", ^{
                                [[theValue(eventData->location->altitude) should] equal:location.altitude
                                                                              withDelta:EPSILON];
                            });
                            it(@"Should have precision", ^{
                                [[theValue(eventData->location->has_precision) should] beYes];
                            });
                            it(@"Should have valid precision", ^{
                                [[theValue(eventData->location->precision) should] equal:location.horizontalAccuracy
                                                                               withDelta:EPSILON];
                            });
                            
#if !TARGET_OS_TV
                            it(@"Should have timestamp", ^{
                                [[theValue(eventData->location->has_direction) should] beYes];
                            });
                            it(@"Should have valid direction", ^{
                                [[theValue(eventData->location->direction) should] equal:location.course withDelta:EPSILON];
                            });
                            it(@"Should have speed", ^{
                                [[theValue(eventData->location->has_speed) should] beYes];
                            });
                            it(@"Should have valid speed", ^{
                                [[theValue(eventData->location->speed) should] equal:location.speed withDelta:EPSILON];
                            });
#endif
                            
                            it(@"Should have timestamp", ^{
                                [[theValue(eventData->location->has_timestamp) should] beYes];
                            });
                            it(@"Should have valid timestamp", ^{
                                NSTimeInterval interval = location.timestamp.timeIntervalSince1970;
                                [[theValue(eventData->location->timestamp) should] equal:interval withDelta:EPSILON];
                            });
                        });
                        context(@"Minimal", ^{
                            beforeEach(^{
                                event.location = [[CLLocation alloc] initWithLatitude:location.coordinate.latitude
                                                                            longitude:location.coordinate.longitude];
                                fillReport();
                            });
                            it(@"Should have valid latitude", ^{
                                [[theValue(eventData->location->lat) should] equal:location.coordinate.latitude
                                                                         withDelta:EPSILON];
                            });
                            it(@"Should have valid latitude", ^{
                                [[theValue(eventData->location->lon) should] equal:location.coordinate.longitude
                                                                         withDelta:EPSILON];
                            });
                            it(@"Should not have altitude", ^{
                                [[theValue(eventData->location->has_altitude) should] beNo];
                            });
                            it(@"Should have precision", ^{
                                [[theValue(eventData->location->has_precision) should] beYes];
                            });
                            it(@"Should have zero precision", ^{
                                [[theValue(eventData->location->precision) should] equal:0 withDelta:EPSILON];
                            });
                            it(@"Should not have timestamp", ^{
                                [[theValue(eventData->location->has_direction) should] beNo];
                            });
                            it(@"Should not have speed", ^{
                                [[theValue(eventData->location->has_speed) should] beNo];
                            });
                            it(@"Should have timestamp", ^{
                                [[theValue(eventData->location->has_timestamp) should] beYes];
                            });
                            it(@"Should have valid timestamp", ^{
                                NSTimeInterval interval = event.location.timestamp.timeIntervalSince1970;
                                [[theValue(eventData->location->timestamp) should] equal:interval withDelta:EPSILON];
                            });
                        });
                    });
                    context(@"Location enabled", ^{
                        context(@"True", ^{
                            beforeEach(^{
                                event.locationEnabled = AMAOptionalBoolTrue;
                                fillReport();
                            });
                            it(@"Should have value", ^{
                                [[theValue(eventData->has_location_tracking_enabled) should] beYes];
                            });
                            it(@"Should have valid value", ^{
                                id expected = theValue(AMA__REPORT_MESSAGE__OPTIONAL_BOOL__OPTIONAL_BOOL_TRUE);
                                [[theValue(eventData->location_tracking_enabled) should] equal:expected];
                            });
                        });
                        context(@"False", ^{
                            beforeEach(^{
                                event.locationEnabled = AMAOptionalBoolFalse;
                                fillReport();
                            });
                            it(@"Should have value", ^{
                                [[theValue(eventData->has_location_tracking_enabled) should] beYes];
                            });
                            it(@"Should have valid value", ^{
                                id expected = theValue(AMA__REPORT_MESSAGE__OPTIONAL_BOOL__OPTIONAL_BOOL_FALSE);
                                [[theValue(eventData->location_tracking_enabled) should] equal:expected];
                            });
                        });
                        context(@"Undefined", ^{
                            beforeEach(^{
                                event.locationEnabled = AMAOptionalBoolUndefined;
                                fillReport();
                            });
                            it(@"Should have value", ^{
                                [[theValue(eventData->has_location_tracking_enabled) should] beYes];
                            });
                            it(@"Should have valid value", ^{
                                id expected = theValue(AMA__REPORT_MESSAGE__OPTIONAL_BOOL__OPTIONAL_BOOL_UNDEFINED);
                                [[theValue(eventData->location_tracking_enabled) should] equal:expected];
                            });
                        });
                    });
                    context(@"First occurrence", ^{
                        context(@"True", ^{
                            beforeEach(^{
                                event.firstOccurrence = AMAOptionalBoolTrue;
                                fillReport();
                            });
                            it(@"Should have value", ^{
                                [[theValue(eventData->has_first_occurrence) should] beYes];
                            });
                            it(@"Should have valid value", ^{
                                id expected = theValue(AMA__REPORT_MESSAGE__OPTIONAL_BOOL__OPTIONAL_BOOL_TRUE);
                                [[theValue(eventData->first_occurrence) should] equal:expected];
                            });
                        });
                        context(@"False", ^{
                            beforeEach(^{
                                event.firstOccurrence = AMAOptionalBoolFalse;
                                fillReport();
                            });
                            it(@"Should have value", ^{
                                [[theValue(eventData->has_first_occurrence) should] beYes];
                            });
                            it(@"Should have valid value", ^{
                                id expected = theValue(AMA__REPORT_MESSAGE__OPTIONAL_BOOL__OPTIONAL_BOOL_FALSE);
                                [[theValue(eventData->first_occurrence) should] equal:expected];
                            });
                        });
                        context(@"Undefined", ^{
                            beforeEach(^{
                                event.firstOccurrence = AMAOptionalBoolUndefined;
                                fillReport();
                            });
                            it(@"Should have value", ^{
                                [[theValue(eventData->has_first_occurrence) should] beYes];
                            });
                            it(@"Should have valid value", ^{
                                id expected = theValue(AMA__REPORT_MESSAGE__OPTIONAL_BOOL__OPTIONAL_BOOL_UNDEFINED);
                                [[theValue(eventData->first_occurrence) should] equal:expected];
                            });
                        });
                    });
                    context(@"Event environment", ^{
                        NSDictionary *const environment = @{ @"foo": @"bar" };
                        beforeEach(^{
                            event.eventEnvironment = environment;
                            fillReport();
                        });
                        it(@"Should have valid value", ^{
                            [[convertString(eventData->environment) should] equal:@"{\"foo\":\"bar\"}"];
                        });
                    });
                    context(@"Bytes Truncated", ^{
                        context(@"Non-zero", ^{
                            NSUInteger const value = 108;
                            beforeEach(^{
                                event.bytesTruncated = value;
                                fillReport();
                            });
                            it(@"Should have value", ^{
                                [[theValue(eventData->has_bytes_truncated) should] beYes];
                            });
                            it(@"Should have valid value", ^{
                                [[theValue(eventData->bytes_truncated) should] equal:theValue(value)];
                            });
                        });
                        context(@"Zero", ^{
                            beforeEach(^{
                                event.bytesTruncated = 0;
                                fillReport();
                            });
                            it(@"Should have value", ^{
                                [[theValue(eventData->has_bytes_truncated) should] beNo];
                            });
                        });
                    });
                    it(@"Should have valid profile ID", ^{
                        NSString *value = @"PROFILE_ID";
                        event.profileID = value;
                        fillReport();
                        NSString *result = [AMAProtobufUtilities stringForBinaryData:&eventData->profile_id
                                                                                 has:eventData->has_profile_id];
                        [[result should] equal:value];
                    });
                });
            });
        });
    });

    context(@"Invalid", ^{
        context(@"No events", ^{
            beforeEach(^{
                AMASession *session = [[AMASession alloc] init];
                session.appState = appState;

                dispatch_block_t baseFillReport = fillReport;
                fillReport = ^{
                    model = modelWithSessionAndEvent(session, nil);
                    baseFillReport();
                };
            });
            it(@"Should not fill data", ^{
                fillReport();
                [[thePointerValue(reportData) should] equal:thePointerValue(NULL)];
            });
            it(@"Should fill error", ^{
                fillReport();
                [[filledError should] equal:[NSError errorWithDomain:kAMAReportSerializerErrorDomain
                                                                code:AMAReportSerializerErrorEmpty
                                                            userInfo:nil]];
            });
        });
        context(@"No sessions", ^{
            beforeEach(^{
                dispatch_block_t baseFillReport = fillReport;
                fillReport = ^{
                    model = modelWithSessionAndEvent(nil, nil);
                    baseFillReport();
                };
            });
            it(@"Should not fill data", ^{
                fillReport();
                [[thePointerValue(reportData) should] equal:thePointerValue(NULL)];
            });
            it(@"Should fill error", ^{
                fillReport();
                [[filledError should] equal:[NSError errorWithDomain:kAMAReportSerializerErrorDomain
                                                                code:AMAReportSerializerErrorEmpty
                                                            userInfo:nil]];
            });
        });
        context(@"Single event with broken value", ^{
            AMAEvent *__block event = nil;
            beforeEach(^{
                AMASession *session = [[AMASession alloc] init];
                session.appState = appState;
                event = [[AMAEvent alloc] init];

                NSString *const path = @"/path/to/file";
                AMAEventEncryptionType const encryptionType = AMAEventEncryptionTypeNoEncryption;
                NSObject<AMAEventValueProtocol> *eventValue =
                    [[AMAFileEventValue alloc] initWithRelativeFilePath:path encryptionType:encryptionType];
                [eventValue stub:@selector(dataWithError:) andReturn:nil];
                [eventValue stub:@selector(empty) andReturn:theValue(NO)];
                event.value = eventValue;

                dispatch_block_t baseFillReport = fillReport;
                fillReport = ^{
                    model = modelWithSessionAndEvent(session, event);
                    baseFillReport();
                };
            });
            it(@"Should not fill data", ^{
                fillReport();
                [[thePointerValue(reportData) should] equal:thePointerValue(NULL)];
            });
            it(@"Should fill error", ^{
                fillReport();
                [[filledError should] equal:[NSError errorWithDomain:kAMAReportSerializerErrorDomain
                                                                code:AMAReportSerializerErrorEmpty
                                                            userInfo:nil]];
            });
            it(@"Should call delegate", ^{
                [[delegate should] receive:@selector(reportSerializer:didFailedToReadFileOfEvent:)
                             withArguments:serializer, event];
                fillReport();
            });
        });
        context(@"Allocation error", ^{
            beforeEach(^{
                AMASession *session = [[AMASession alloc] init];
                session.appState = appState;
                AMAEvent *event = [[AMAEvent alloc] init];

                dispatch_block_t baseFillReport = fillReport;
                fillReport = ^{
                    model = modelWithSessionAndEvent(session, event);
                    baseFillReport();
                };
            });
            context(@"Allocation tracker", ^{
                beforeEach(^{
                    NSObject<AMAAllocationsTracking> *tracker =
                        [KWMock nullMockForProtocol:@protocol(AMAAllocationsTracking)];
                    [tracker stub:@selector(allocateSize:) andReturn:nil];
                    [AMAAllocationsTrackerProvider stub:@selector(track:) withBlock:^id(NSArray *params) {
                        void (^block)(id<AMAAllocationsTracking> tracker) = params[0];
                        block(tracker);
                        return nil;
                    }];
                });
                it(@"Should not fill data", ^{
                    fillReport();
                    [[thePointerValue(reportData) should] equal:thePointerValue(NULL)];
                });
                it(@"Should fill error", ^{
                    fillReport();
                    [[filledError should] equal:[NSError errorWithDomain:kAMAReportSerializerErrorDomain
                                                                    code:AMAReportSerializerErrorAllocationError
                                                                userInfo:nil]];
                });
            });
            context(@"Protobuf string serialization", ^{
                beforeEach(^{
                    [AMAProtobufUtilities stub:@selector(addString:toTracker:) andReturn:nil];
                });
                it(@"Should not fill data", ^{
                    fillReport();
                    [[thePointerValue(reportData) should] equal:thePointerValue(NULL)];
                });
                it(@"Should fill error", ^{
                    fillReport();
                    [[filledError should] equal:[NSError errorWithDomain:kAMAReportSerializerErrorDomain
                                                                    code:AMAReportSerializerErrorAllocationError
                                                                userInfo:nil]];
                });
            });
        });
        context(@"Too large", ^{
            beforeEach(^{
                AMASession *session = [[AMASession alloc] init];
                session.appState = appState;
                AMAEvent *event = [[AMAEvent alloc] init];
                sizeLimit = 1;

                dispatch_block_t baseFillReport = fillReport;
                fillReport = ^{
                    model = modelWithSessionAndEvent(session, event);
                    baseFillReport();
                };
            });
            it(@"Should not fill data", ^{
                fillReport();
                [[thePointerValue(reportData) should] equal:thePointerValue(NULL)];
            });
            context(@"Error", ^{
                beforeEach(^{
                    fillReport();
                });
                it(@"Should have valid domain", ^{
                    [[filledError.domain should] equal:kAMAReportSerializerErrorDomain];
                });
                it(@"Should have valid code", ^{
                    [[theValue(filledError.code) should] equal:theValue(AMAReportSerializerErrorTooLarge)];
                });
                it(@"Should have size", ^{
                    NSInteger size = [filledError.userInfo[kAMAReportSerializerErrorKeyActualSize] integerValue];
                    [[theValue(size) should] beGreaterThan:theValue(100)];
                });
            });
        });
    });

});

SPEC_END
