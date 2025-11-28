
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <CoreLocation/CoreLocation.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaProtobufUtils/AppMetricaProtobufUtils.h>
#import "AMAEventSerializer+Migration.h"
#import "AMADatabaseConstants.h"
#import "AMAEvent.h"
#import "AMAStringEventValue.h"
#import "AMABinaryEventValue.h"
#import "AMAFileEventValue.h"
#import "EventData.pb-c.h"
#import "AMAReporterDatabaseEncodersFactory.h"
#import "AMAReporterDatabaseMigrationTo500EncodersFactory.h"
#import "AMAReporterDatabaseMigrationTo5100EncodersFactory.h"

SPEC_BEGIN(AMAEventSerializerTests)

describe(@"AMAEventSerializer", ^{
    double const EPSILON = 0.0001;
    __auto_type *const encoderFactory = [[AMAReporterDatabaseEncodersFactory alloc] init];
    __auto_type *const encoderTo500Factory = [[AMAReporterDatabaseMigrationTo500EncodersFactory alloc] init];
    __auto_type *const encoderTo5100Factory = [[AMAReporterDatabaseMigrationTo5100EncodersFactory alloc] init];
    CLLocation *const location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(53.891059, 27.526119)
                                                               altitude:295.0
                                                     horizontalAccuracy:10.0
                                                       verticalAccuracy:23.0
                                                                 course:115.0
                                                                  speed:4.2
                                                              timestamp:[NSDate date]];

    id<AMADataEncoding> __block encoder = nil;
    AMAEvent *__block event = nil;
    AMAEventSerializer *__block serializer = nil;

    beforeEach(^{
        event = [[AMAEvent alloc] init];
        [AMAReporterDatabaseEncodersFactory stubInstance:encoderFactory forInit:@selector(init)];
        [AMAReporterDatabaseMigrationTo500EncodersFactory stubInstance:encoderTo500Factory forInit:@selector(init)];
        [AMAReporterDatabaseMigrationTo5100EncodersFactory stubInstance:encoderTo5100Factory forInit:@selector(init)];
        encoder = [encoderFactory encoderForEncryptionType:AMAReporterDatabaseEncryptionTypeGZipAES];
        serializer = [[AMAEventSerializer alloc] init];
    });
    afterEach(^{
        [AMAReporterDatabaseEncodersFactory clearStubs];
        [AMAReporterDatabaseMigrationTo500EncodersFactory clearStubs];
        [AMAReporterDatabaseMigrationTo5100EncodersFactory clearStubs];
    });

    context(@"Serialization", ^{

        NSObject *(^field)(NSString *) = ^(NSString *fieldKey) {
            return [serializer dictionaryForEvent:event error:nil][fieldKey];
        };

        context(@"DB fields", ^{
            it(@"Should store oid", ^{
                NSNumber *oid = @23;
                event.oid = oid;
                [[field(kAMACommonTableFieldOID) should] equal:oid];
            });
            it(@"Should store sessionOid", ^{
                NSNumber *sessionID = @42;
                event.sessionOid = sessionID;
                [[field(kAMAEventTableFieldSessionOID) should] equal:sessionID];
            });
            it(@"Should store createdAt", ^{
                NSDate *createdAt = [NSDate date];
                event.createdAt = createdAt;
                NSNumber *timeInterval = (NSNumber *)field(kAMAEventTableFieldCreatedAt);
                [[theValue([timeInterval doubleValue]) should] equal:createdAt.timeIntervalSinceReferenceDate
                                                           withDelta:EPSILON];
            });
            it(@"Should store sequenceNumber", ^{
                NSUInteger sequenceNumber = 108;
                event.sequenceNumber = sequenceNumber;
                [[field(kAMAEventTableFieldSequenceNumber) should] equal:@(sequenceNumber)];
            });
            it(@"Should have valid encryption type", ^{
                [[field(kAMACommonTableFieldDataEncryptionType) should] equal:@(AMAReporterDatabaseEncryptionTypeGZipAES)];
            });
            it(@"Should have non-empty data", ^{
                [[field(kAMACommonTableFieldData) shouldNot] beEmpty];
            });
        });
        context(@"Data", ^{
            AMAProtobufAllocator *__block allocator = nil;
            Ama__EventData *__block eventData = NULL;

            void (^fillEventData)(void) = ^{
                NSData *data = (NSData *)field(kAMACommonTableFieldData);
                NSData *decodedData = [encoder decodeData:data error:nil];
                eventData = ama__event_data__unpack(allocator.protobufCAllocator, decodedData.length, decodedData.bytes);
            };

            beforeEach(^{
                allocator = [[AMAProtobufAllocator alloc] init];
            });

            it(@"Should have valid name", ^{
                NSString *eventName = @"EVENT_NAME";
                event.name = eventName;
                fillEventData();
                NSString *name = [AMAProtobufUtilities stringForBinaryData:&eventData->payload->name
                                                                       has:eventData->payload->has_name];
                [[name should] equal:eventName];
            });
            context(@"Value", ^{
                context(@"Empty", ^{
                    beforeEach(^{
                        fillEventData();
                    });
                    it(@"Should have valid value type", ^{
                        [[theValue(eventData->payload->value_type) should] equal:theValue(AMA__EVENT_DATA__PAYLOAD__VALUE_TYPE__EMPTY)];
                    });
                    it(@"Should have no encryption", ^{
                        [[theValue(eventData->payload->encryption_type) should] equal:theValue(AMA__EVENT_DATA__PAYLOAD__ENCRYPTION_TYPE__NONE)];
                    });
                    it(@"Should have no data", ^{
                        NSData *data = [AMAProtobufUtilities dataForBinaryData:&eventData->payload->value_data
                                                                           has:eventData->payload->has_value_data];
                        [[data should] beNil];
                    });
                });
                context(@"String", ^{
                    NSString *const expectedValue = @"EVENT_VALUE";
                    beforeEach(^{
                        event.value = [[AMAStringEventValue alloc] initWithValue:expectedValue];
                        fillEventData();
                    });
                    it(@"Should have valid value type", ^{
                        [[theValue(eventData->payload->value_type) should] equal:theValue(AMA__EVENT_DATA__PAYLOAD__VALUE_TYPE__STRING)];
                    });
                    it(@"Should have no encryption", ^{
                        [[theValue(eventData->payload->encryption_type) should] equal:theValue(AMA__EVENT_DATA__PAYLOAD__ENCRYPTION_TYPE__NONE)];
                    });
                    it(@"Should have valid data", ^{
                        NSString *value = [AMAProtobufUtilities stringForBinaryData:&eventData->payload->value_data
                                                                                has:eventData->payload->has_value_data];
                        [[value should] equal:expectedValue];
                    });
                });
                context(@"Binary", ^{
                    NSData *const expectedValue = [@"EVENT_VALUE_DATA" dataUsingEncoding:NSUTF8StringEncoding];
                    context(@"Raw", ^{
                        beforeEach(^{
                            event.value = [[AMABinaryEventValue alloc] initWithData:expectedValue gZipped:NO];
                            fillEventData();
                        });
                        it(@"Should have valid value type", ^{
                            [[theValue(eventData->payload->value_type) should] equal:theValue(AMA__EVENT_DATA__PAYLOAD__VALUE_TYPE__BINARY)];
                        });
                        it(@"Should have no encryption", ^{
                            [[theValue(eventData->payload->encryption_type) should] equal:theValue(AMA__EVENT_DATA__PAYLOAD__ENCRYPTION_TYPE__NONE)];
                        });
                        it(@"Should have valid data", ^{
                            NSData *data = [AMAProtobufUtilities dataForBinaryData:&eventData->payload->value_data
                                                                               has:eventData->payload->has_value_data];
                            [[data should] equal:expectedValue];
                        });
                    });
                    context(@"GZipped", ^{
                        beforeEach(^{
                            event.value = [[AMABinaryEventValue alloc] initWithData:expectedValue gZipped:YES];
                            fillEventData();
                        });
                        it(@"Should have valid value type", ^{
                            [[theValue(eventData->payload->value_type) should] equal:theValue(AMA__EVENT_DATA__PAYLOAD__VALUE_TYPE__BINARY)];
                        });
                        it(@"Should have GZip encryption", ^{
                            [[theValue(eventData->payload->encryption_type) should] equal:theValue(AMA__EVENT_DATA__PAYLOAD__ENCRYPTION_TYPE__GZIP)];
                        });
                        it(@"Should have valid data", ^{
                            NSData *data = [AMAProtobufUtilities dataForBinaryData:&eventData->payload->value_data
                                                                               has:eventData->payload->has_value_data];
                            [[data should] equal:expectedValue];
                        });
                    });
                });
                context(@"File", ^{
                    NSString *const filePath = @"/path/to/file";
                    context(@"AES", ^{
                        beforeEach(^{
                            event.value = [[AMAFileEventValue alloc] initWithRelativeFilePath:filePath
                                                                               encryptionType:AMAEventEncryptionTypeAESv1];
                            fillEventData();
                        });
                        it(@"Should have valid value type", ^{
                            [[theValue(eventData->payload->value_type) should] equal:theValue(AMA__EVENT_DATA__PAYLOAD__VALUE_TYPE__FILE)];
                        });
                        it(@"Should have valid encryption", ^{
                            [[theValue(eventData->payload->encryption_type) should] equal:theValue(AMA__EVENT_DATA__PAYLOAD__ENCRYPTION_TYPE__AES)];
                        });
                        it(@"Should have valid data", ^{
                            NSString *value = [AMAProtobufUtilities stringForBinaryData:&eventData->payload->value_data
                                                                                    has:eventData->payload->has_value_data];
                            [[value should] equal:filePath];
                        });
                    });
                    it(@"Should serialize RSA_AES encryption type", ^{
                        event.value = [[AMAFileEventValue alloc] initWithRelativeFilePath:filePath
                                                                           encryptionType:AMAEventEncryptionTypeNoEncryption];
                        fillEventData();
                        [[theValue(eventData->payload->encryption_type) should] equal:theValue(AMA__EVENT_DATA__PAYLOAD__ENCRYPTION_TYPE__NONE)];
                    });
                    it(@"Should serialize RSA_AES encryption type", ^{
                        event.value = [[AMAFileEventValue alloc] initWithRelativeFilePath:filePath
                                                                           encryptionType:AMAEventEncryptionTypeGZip];
                        fillEventData();
                        [[theValue(eventData->payload->encryption_type) should] equal:theValue(AMA__EVENT_DATA__PAYLOAD__ENCRYPTION_TYPE__GZIP)];
                    });
                });
                context(@"Unknown", ^{
                    beforeEach(^{
                        event.value = [KWMock nullMockForProtocol:@protocol(AMAEventValueProtocol)];
                    });
                    it(@"Should have empty value type", ^{
                        [AMATestUtilities stubAssertions];
                        fillEventData();
                        [[theValue(eventData->payload->value_type) should] equal:theValue(AMA__EVENT_DATA__PAYLOAD__VALUE_TYPE__EMPTY)];
                    });
                });
            });
            it(@"Should have valid bytes truncated", ^{
                NSUInteger bytesTruncated = 108;
                event.bytesTruncated = bytesTruncated;
                fillEventData();
                [[theValue(eventData->payload->bytes_truncated) should] equal:theValue(bytesTruncated)];
            });
            it(@"Should have valid time offset", ^{
                NSTimeInterval offset = 23.42;
                event.timeSinceSession = offset;
                fillEventData();
                [[theValue(eventData->time_offset) should] equal:offset withDelta:EPSILON];
            });
            it(@"Should have valid global number", ^{
                NSUInteger number = 42;
                event.globalNumber = number;
                fillEventData();
                [[theValue(eventData->global_number) should] equal:theValue(number)];
            });
            it(@"Should have valid number of type", ^{
                NSUInteger number = 23;
                event.numberOfType = number;
                fillEventData();
                [[theValue(eventData->number_of_type) should] equal:theValue(number)];
            });
            context(@"Event source", ^{
                it(@"Should have native source", ^{
                    event.source = AMAEventSourceNative;
                    fillEventData();
                    [[theValue(eventData->source) should] equal:theValue(AMA__EVENT_DATA__EVENT_SOURCE__NATIVE)];
                });
                it(@"Should have JS source", ^{
                    event.source = AMAEventSourceJs;
                    fillEventData();
                    [[theValue(eventData->source) should] equal:theValue(AMA__EVENT_DATA__EVENT_SOURCE__JS)];
                });
                it(@"Should have SDK source", ^{
                    event.source = AMAEventSourceSDKSystem;
                    fillEventData();
                    [[theValue(eventData->source) should] equal:theValue(AMA__EVENT_DATA__EVENT_SOURCE__SDK_SYSTEM)];
                });
            });
            context(@"Attribution id changed", ^{
                it(@"Should have attribution_id_changed as true", ^{
                    event.attributionIDChanged = YES;
                    fillEventData();
                    [[theValue(eventData->attribution_id_changed) should] equal:theValue(true)];
                });
                it(@"Should have attribution_id_changed as false", ^{
                    event.attributionIDChanged = NO;
                    fillEventData();
                    [[theValue(eventData->attribution_id_changed) should] equal:theValue(false)];
                });
            });
            context(@"Open id", ^{
                context(@"Nil", ^{
                    beforeEach(^{
                        event.openID = nil;
                        fillEventData();
                    });
                    it(@"has_open_id should be true", ^{
                        [[theValue(eventData->has_open_id) should] beYes];
                    });
                    it(@"open_id should be 1", ^{
                        [[theValue(eventData->open_id) should] equal:theValue(1)];
                    });
                });
                context(@"Not nil", ^{
                    beforeEach(^{
                        event.openID = @555666;
                        fillEventData();
                    });
                    it(@"has_open_id should be true", ^{
                        [[theValue(eventData->has_open_id) should] beYes];
                    });
                    it(@"open_id should be 1", ^{
                        [[theValue(eventData->open_id) should] equal:theValue(555666)];
                    });
                });
                it(@"Should have attribution_id_changed as false", ^{
                    event.attributionIDChanged = NO;
                    fillEventData();
                    [[theValue(eventData->attribution_id_changed) should] equal:theValue(false)];
                });
            });
            context(@"First occurrence", ^{
                context(@"True", ^{
                    beforeEach(^{
                        event.firstOccurrence = AMAOptionalBoolTrue;
                        fillEventData();
                    });
                    it(@"Should have value", ^{
                        [[theValue(eventData->has_first_occurrence) should] beYes];
                    });
                    it(@"Should have valid value", ^{
                        [[theValue(eventData->first_occurrence) should] beYes];
                    });
                });
                context(@"False", ^{
                    beforeEach(^{
                        event.firstOccurrence = AMAOptionalBoolFalse;
                        fillEventData();
                    });
                    it(@"Should have value", ^{
                        [[theValue(eventData->has_first_occurrence) should] beYes];
                    });
                    it(@"Should have valid value", ^{
                        [[theValue(eventData->first_occurrence) should] beNo];
                    });
                });
                context(@"Undefined", ^{
                    beforeEach(^{
                        event.firstOccurrence = AMAOptionalBoolUndefined;
                        fillEventData();
                    });
                    it(@"Should not have value", ^{
                        [[theValue(eventData->has_first_occurrence) should] beNo];
                    });
                });
            });
            context(@"Location", ^{

                beforeEach(^{
                    event.location = location;
                    fillEventData();
                });
                it(@"Should have valid latitude", ^{
                    [[theValue(eventData->location->latitude) should] equal:location.coordinate.latitude
                                                                  withDelta:EPSILON];
                });
                it(@"Should have valid latitude", ^{
                    [[theValue(eventData->location->longitude) should] equal:location.coordinate.longitude
                                                                   withDelta:EPSILON];
                });
                it(@"Should have valid altitude", ^{
                    [[theValue(eventData->location->altitude) should] equal:location.altitude
                                                                  withDelta:EPSILON];
                });
                it(@"Should have valid horizontalAccuracy", ^{
                    [[theValue(eventData->location->horizontal_accuracy) should] equal:location.horizontalAccuracy
                                                                             withDelta:EPSILON];
                });
                it(@"Should have valid verticalAccuracy", ^{
                    [[theValue(eventData->location->vertical_accuracy) should] equal:location.verticalAccuracy
                                                                           withDelta:EPSILON];
                });
#if !TARGET_OS_TV
                it(@"Should have valid altitude", ^{
                    [[theValue(eventData->location->direction) should] equal:location.course withDelta:EPSILON];
                });
                it(@"Should have valid altitude", ^{
                    [[theValue(eventData->location->speed) should] equal:location.speed withDelta:EPSILON];
                });
#endif
                it(@"Should have valid timestamp", ^{
                    NSTimeInterval interval = location.timestamp.timeIntervalSinceReferenceDate;
                    [[theValue(eventData->location->timestamp) should] equal:interval withDelta:EPSILON];
                });
            });
            context(@"Location enabled", ^{
                context(@"True", ^{
                    beforeEach(^{
                        event.locationEnabled = AMAOptionalBoolTrue;
                        fillEventData();
                    });
                    it(@"Should have value", ^{
                        [[theValue(eventData->has_location_enabled) should] beYes];
                    });
                    it(@"Should have valid value", ^{
                        [[theValue(eventData->location_enabled) should] beYes];
                    });
                });
                context(@"False", ^{
                    beforeEach(^{
                        event.locationEnabled = AMAOptionalBoolFalse;
                        fillEventData();
                    });
                    it(@"Should have value", ^{
                        [[theValue(eventData->has_location_enabled) should] beYes];
                    });
                    it(@"Should have valid value", ^{
                        [[theValue(eventData->location_enabled) should] beNo];
                    });
                });
                context(@"Undefined", ^{
                    beforeEach(^{
                        event.locationEnabled = AMAOptionalBoolUndefined;
                        fillEventData();
                    });
                    it(@"Should not have value", ^{
                        [[theValue(eventData->has_location_enabled) should] beNo];
                    });
                });
            });
            it(@"Should have valid app environment", ^{
                event.appEnvironment = @{ @"foo": @"bar" };
                fillEventData();
                NSString *jsonString = [AMAProtobufUtilities stringForBinaryData:&eventData->app_environment
                                                                             has:eventData->has_app_environment];
                [[jsonString should] equal:@"{\"foo\":\"bar\"}"];
            });
            it(@"Should have valid event environment", ^{
                event.eventEnvironment = @{ @"foo": @"bar" };
                fillEventData();
                NSString *jsonString = [AMAProtobufUtilities stringForBinaryData:&eventData->event_environment
                                                                             has:eventData->has_event_environment];
                [[jsonString should] equal:@"{\"foo\":\"bar\"}"];
            });
            context(@"Extras", ^{
                NSString *const key1 = @"KEY_1";
                NSString *const value1raw = @"test value 1";
                NSData *const value1 = [value1raw dataUsingEncoding:NSUTF8StringEncoding];

                NSString *const key2 = @"KEY_EMPTY";
                NSData *const value2 = [NSData new];

                NSDictionary<NSString *, NSData *> *const extras = @{
                        key1: value1,
                        key2: value2,
                };

                beforeEach(^{
                    event.extras = extras;
                    fillEventData();
                });
                it(@"Should have extras", ^{
                    [[thePointerValue(eventData->extras) shouldNot] equal:thePointerValue(NULL)];
                    [[theValue(eventData->n_extras) should] equal:theValue(2)];

                    NSString *eventKey1 = [AMAProtobufUtilities stringForBinaryData:&eventData->extras[0]->key];
                    NSData *eventValue1 = [AMAProtobufUtilities dataForBinaryData:&eventData->extras[0]->value];

                    NSString *eventKey2 = [AMAProtobufUtilities stringForBinaryData:&eventData->extras[1]->key];
                    NSData *eventValue2 = [AMAProtobufUtilities dataForBinaryData:&eventData->extras[1]->value];

                    NSDictionary<NSString *, NSData *> *eventExtras = @{
                        eventKey1: eventValue1,
                        eventKey2: eventValue2,
                    };

                    [[eventExtras should] equal:extras];
                });
            });
            context(@"Empty extras", ^{
                beforeEach(^{
                    event.extras = [NSDictionary dictionary];
                    fillEventData();
                });
                it(@"Should have extras", ^{
                    [[thePointerValue(eventData->extras) should] equal:thePointerValue(NULL)];
                });
            });
            it(@"Should have valid profile ID", ^{
                NSString *expectedProfileID = @"PROFILE_ID";
                event.profileID = expectedProfileID;
                fillEventData();
                NSString *profileID = [AMAProtobufUtilities stringForBinaryData:&eventData->user_profile_id
                                                                            has:eventData->has_user_profile_id];
                [[profileID should] equal:expectedProfileID];
            });
        });
    });

    context(@"Deserialization", ^{
        id<AMAAllocationsTracking> __block tracker = nil;
        Ama__EventData *__block eventData = NULL;
        NSMutableDictionary *__block eventDictionary = nil;

        void (^prepareDictionary)(void) = ^{
            size_t dataSize = ama__event_data__get_packed_size(eventData);
            void *dataBytes = malloc(dataSize);
            dataSize = ama__event_data__pack(eventData, dataBytes);
            NSData *data = [NSData dataWithBytesNoCopy:dataBytes length:dataSize];
            NSData *encodedData = [encoder encodeData:data error:nil];
            eventDictionary[kAMACommonTableFieldData] = encodedData;
            eventDictionary[kAMACommonTableFieldDataEncryptionType] = @(AMAReporterDatabaseEncryptionTypeGZipAES);
        };

        void (^fillEvent)(void) = ^{
            prepareDictionary();
            event = [serializer eventForDictionary:eventDictionary error:nil];
        };

        beforeEach(^{
            tracker = [AMAAllocationsTrackerProvider manuallyHandledTracker];

            eventData = [tracker allocateSize:sizeof(Ama__EventData)];
            ama__event_data__init(eventData);
            eventData->payload = [tracker allocateSize:sizeof(Ama__EventData__Payload)];
            ama__event_data__payload__init(eventData->payload);

            eventDictionary = [NSMutableDictionary dictionary];
        });

        it(@"Should create different encoder", ^{
            [[encoderFactory should] receive:@selector(encoderForEncryptionType:)
                               withArguments:theValue(AMAReporterDatabaseEncryptionTypeAES)];
            prepareDictionary();
            eventDictionary[kAMACommonTableFieldDataEncryptionType] = @(AMAReporterDatabaseEncryptionTypeAES);
            [serializer eventForDictionary:eventDictionary error:nil];
        });
        
        it(@"Should create migration to 5.0.0 encoder", ^{
            AMAEventSerializer *__block migrationSerialzer = [[AMAEventSerializer alloc] migrationTo500Init];
            
            [[encoderTo500Factory should] receive:@selector(encoderForEncryptionType:)
                                    withArguments:theValue(AMAReporterDatabaseEncryptionTypeAES)];
            prepareDictionary();
            eventDictionary[kAMACommonTableFieldDataEncryptionType] = @(AMAReporterDatabaseEncryptionTypeAES);
            [migrationSerialzer eventForDictionary:eventDictionary error:nil];
        });
        
        it(@"Should create migration to 5.10.0 encoder", ^{
            AMAEventSerializer *__block migrationSerialzer = [[AMAEventSerializer alloc] migrationTo5100Init];
            
            [[encoderTo5100Factory should] receive:@selector(encoderForEncryptionType:)
                                     withArguments:theValue(AMAReporterDatabaseEncryptionTypeAES)];
            prepareDictionary();
            eventDictionary[kAMACommonTableFieldDataEncryptionType] = @(AMAReporterDatabaseEncryptionTypeAES);
            [migrationSerialzer eventForDictionary:eventDictionary error:nil];
        });
        
        it(@"Should return nil if data is empty", ^{
            prepareDictionary();
            NSData *encodedData = [encoder encodeData:[NSData data] error:nil];
            eventDictionary[kAMACommonTableFieldData] = encodedData;
            [[[serializer eventForDictionary:eventDictionary error:nil] should] beNil];
        });
        it(@"Should return nil if data is not a valid protobuf", ^{
            prepareDictionary();
            NSData *encodedData = [encoder encodeData:[@"NOT_A_PROTOBUF" dataUsingEncoding:NSUTF8StringEncoding]
                                                error:nil];
            eventDictionary[kAMACommonTableFieldData] = encodedData;
            [[[serializer eventForDictionary:eventDictionary error:nil] should] beNil];
        });
        it(@"Should return nil if sequenceNumber is data", ^{
            prepareDictionary();
            eventDictionary[kAMAEventTableFieldSequenceNumber] = [@"DATA" dataUsingEncoding:NSUTF8StringEncoding];
            [[[serializer eventForDictionary:eventDictionary error:nil] should] beNil];
        });

        it(@"Should have valid OID", ^{
            NSNumber *oid = @23;
            eventDictionary[kAMACommonTableFieldOID] = oid;
            fillEvent();
            [[event.oid should] equal:oid];
        });
        it(@"Should have valid sessionID", ^{
            NSNumber *sessionID = @42;
            eventDictionary[kAMAEventTableFieldSessionOID] = sessionID;
            fillEvent();
            [[event.sessionOid should] equal:sessionID];
        });
        context(@"Created at", ^{
            NSDate *__block now = nil;
            beforeEach(^{
                now = [NSDate date];
                [NSDate stub:@selector(date) andReturn:now];
            });
            afterEach(^{
                [NSDate clearStubs];
            });
            
            it(@"Should have valid value", ^{
                NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0.0];
                eventDictionary[kAMAEventTableFieldCreatedAt] = @(date.timeIntervalSinceReferenceDate);
                fillEvent();
                [[event.createdAt should] equal:date];
            });
            it(@"Should have current date if absent", ^{
                fillEvent();
                [[event.createdAt should] equal:now];
            });
            it(@"Should have current date if null", ^{
                eventDictionary[kAMAEventTableFieldCreatedAt] = [NSNull null];
                fillEvent();
                [[event.createdAt should] equal:now];
            });
        });
        it(@"Should have valid number in session", ^{
            NSInteger number = 108;
            eventDictionary[kAMAEventTableFieldSequenceNumber] = @(number);
            fillEvent();
            [[theValue(event.sequenceNumber) should] equal:theValue(number)];
        });
        it(@"Should have valid type", ^{
            NSInteger type = AMAEventTypeAlive;
            eventDictionary[kAMACommonTableFieldType] = @(type);
            fillEvent();
            [[theValue(event.type) should] equal:theValue(type)];
        });

        context(@"Data", ^{
            it(@"Should have valid name", ^{
                NSString *name = @"EVENT_NAME";
                eventData->payload->has_name = [AMAProtobufUtilities fillBinaryData:&eventData->payload->name
                                                                         withString:name
                                                                            tracker:tracker];
                fillEvent();
                [[event.name should] equal:name];
            });
            context(@"Value", ^{
                context(@"Empty", ^{
                    beforeEach(^{
                        eventData->payload->value_type = AMA__EVENT_DATA__PAYLOAD__VALUE_TYPE__EMPTY;
                        fillEvent();
                    });
                    it(@"Should have nil value", ^{
                        [[((NSObject *)event.value) should] beNil];
                    });
                });
                context(@"String", ^{
                    NSString *const value = @"EVENT_VALUE";
                    beforeEach(^{
                        eventData->payload->value_type = AMA__EVENT_DATA__PAYLOAD__VALUE_TYPE__STRING;
                        eventData->payload->has_value_data =
                            [AMAProtobufUtilities fillBinaryData:&eventData->payload->value_data
                                                      withString:value
                                                         tracker:tracker];
                        fillEvent();
                    });
                    it(@"Should have valid class for value", ^{
                        [[((NSObject *)event.value) should] beKindOfClass:[AMAStringEventValue class]];
                    });
                    it(@"Should have valid value", ^{
                        [[((AMAStringEventValue *)event.value).value should] equal:value];
                    });
                });
                context(@"Binary", ^{
                    NSData *const data = [@"EVENT_DATA" dataUsingEncoding:NSUTF8StringEncoding];
                    beforeEach(^{
                        eventData->payload->value_type = AMA__EVENT_DATA__PAYLOAD__VALUE_TYPE__BINARY;
                        eventData->payload->has_value_data =
                            [AMAProtobufUtilities fillBinaryData:&eventData->payload->value_data
                                                        withData:data
                                                         tracker:tracker];
                        fillEvent();
                    });
                    it(@"Should have valid class for value", ^{
                        [[((NSObject *)event.value) should] beKindOfClass:[AMABinaryEventValue class]];
                    });
                    it(@"Should have valid data", ^{
                        [[((AMABinaryEventValue *)event.value).data should] equal:data];
                    });
                });
                context(@"File", ^{
                    NSString *const filePath = @"/path/to/file";
                    beforeEach(^{
                        eventData->payload->value_type = AMA__EVENT_DATA__PAYLOAD__VALUE_TYPE__FILE;
                        eventData->payload->has_value_data =
                            [AMAProtobufUtilities fillBinaryData:&eventData->payload->value_data
                                                      withString:filePath
                                                         tracker:tracker];
                    });
                    context(@"AES", ^{
                        beforeEach(^{
                            eventData->payload->encryption_type = AMA__EVENT_DATA__PAYLOAD__ENCRYPTION_TYPE__AES;
                            fillEvent();
                        });
                        it(@"Should have valid class for value", ^{
                            [[((NSObject *)event.value) should] beKindOfClass:[AMAFileEventValue class]];
                        });
                        it(@"Should have valid path", ^{
                            [[((AMAFileEventValue *)event.value).relativeFilePath should] equal:filePath];
                        });
                        it(@"Should have valid encryption type", ^{
                            AMAEventEncryptionType expected = AMAEventEncryptionTypeAESv1;
                            [[theValue(((AMAFileEventValue *)event.value).encryptionType) should] equal:theValue(expected)];
                        });
                    });
                    context(@"GZip", ^{
                        beforeEach(^{
                            eventData->payload->encryption_type = AMA__EVENT_DATA__PAYLOAD__ENCRYPTION_TYPE__GZIP;
                            fillEvent();
                        });
                        it(@"Should have valid encryption type", ^{
                            AMAEventEncryptionType expected = AMAEventEncryptionTypeGZip;
                            [[theValue(((AMAFileEventValue *)event.value).encryptionType) should] equal:theValue(expected)];
                        });
                    });
                    context(@"RSA-AES", ^{
                        beforeEach(^{
                            eventData->payload->encryption_type = AMA__EVENT_DATA__PAYLOAD__ENCRYPTION_TYPE__NONE;
                            fillEvent();
                        });
                        it(@"Should have valid encryption type", ^{
                            AMAEventEncryptionType expected = AMAEventEncryptionTypeNoEncryption;
                            [[theValue(((AMAFileEventValue *)event.value).encryptionType) should] equal:theValue(expected)];
                        });
                    });
                });
            });
            it(@"Should have valid bytes truncated", ^{
                uint32_t bytesTruncated = 23;
                eventData->payload->bytes_truncated = bytesTruncated;
                fillEvent();
                [[theValue(event.bytesTruncated) should] equal:theValue(bytesTruncated)];
            });
            it(@"Should have valid time since session", ^{
                NSTimeInterval interval = 42;
                eventData->time_offset = interval;
                fillEvent();
                [[theValue(event.timeSinceSession) should] equal:interval withDelta:EPSILON];
            });
            it(@"Should have valid global number", ^{
                uint32_t number = 108;
                eventData->global_number = number;
                fillEvent();
                [[theValue(event.globalNumber) should] equal:theValue(number)];
            });
            it(@"Should have valid number of type", ^{
                uint32_t number = 15;
                eventData->number_of_type = number;
                fillEvent();
                [[theValue(event.numberOfType) should] equal:theValue(number)];
            });
            context(@"Event source", ^{
                it(@"Should have native source", ^{
                    eventData->has_source = true;
                    eventData->source = AMA__EVENT_DATA__EVENT_SOURCE__NATIVE;
                    fillEvent();
                    [[theValue(event.source) should] equal:theValue(AMAEventSourceNative)];
                });
                it(@"Should have JS source", ^{
                    eventData->has_source = true;
                    eventData->source = AMA__EVENT_DATA__EVENT_SOURCE__JS;
                    fillEvent();
                    [[theValue(event.source) should] equal:theValue(AMAEventSourceJs)];
                });
                it(@"Should have SDK system source", ^{
                    eventData->has_source = true;
                    eventData->source = AMA__EVENT_DATA__EVENT_SOURCE__SDK_SYSTEM;
                    fillEvent();
                    [[theValue(event.source) should] equal:theValue(AMAEventSourceSDKSystem)];
                });
            });
            context(@"First occurrence", ^{
                it(@"Should be true", ^{
                    eventData->has_first_occurrence = true;
                    eventData->first_occurrence = true;
                    fillEvent();
                    [[theValue(event.firstOccurrence) should] equal:theValue(AMAOptionalBoolTrue)];
                });
                it(@"Should be false", ^{
                    eventData->has_first_occurrence = true;
                    eventData->first_occurrence = false;
                    fillEvent();
                    [[theValue(event.firstOccurrence) should] equal:theValue(AMAOptionalBoolFalse)];
                });
                it(@"Should be undefined", ^{
                    eventData->has_first_occurrence = false;
                    fillEvent();
                    [[theValue(event.firstOccurrence) should] equal:theValue(AMAOptionalBoolUndefined)];
                });
            });
            context(@"Location", ^{
                context(@"No location", ^{
                    beforeEach(^{
                        fillEvent();
                    });
                    it(@"Should have no location", ^{
                        [[event.location should] beNil];
                    });
                });
                context(@"Non-empty location", ^{
                    Ama__EventData__Location *__block locationData = NULL;
                    beforeEach(^{
                        locationData = [tracker allocateSize:sizeof(Ama__EventData__Location)];
                        ama__event_data__location__init(locationData);
                        eventData->location = locationData;
                        locationData->latitude = location.coordinate.latitude;
                        locationData->longitude = location.coordinate.longitude;
                        locationData->altitude = location.altitude;
                        locationData->horizontal_accuracy = location.horizontalAccuracy;
                        locationData->vertical_accuracy = location.verticalAccuracy;
                        locationData->direction = location.course;
                        locationData->speed = location.speed;
                    });
                    context(@"Without timestamp", ^{
                        it(@"Should have nil value", ^{
                            [AMATestUtilities stubAssertions];
                            fillEvent();
                            [[event.location should] beNil];
                        });
                    });
                    context(@"With timestamp", ^{
                        beforeEach(^{
                            locationData->has_timestamp = true;
                            locationData->timestamp = location.timestamp.timeIntervalSinceReferenceDate;
                            fillEvent();
                        });
                        it(@"Should valid latitude", ^{
                            [[theValue(event.location.coordinate.latitude) should] equal:location.coordinate.latitude
                                                                               withDelta:EPSILON];
                        });
                        it(@"Should valid longitude", ^{
                            [[theValue(event.location.coordinate.longitude) should] equal:location.coordinate.longitude
                                                                                withDelta:EPSILON];
                        });
                        it(@"Should have valid altitude", ^{
                            [[theValue(event.location.altitude) should] equal:location.altitude
                                                                    withDelta:EPSILON];
                        });
                        it(@"Should have valid horizontalAccuracy", ^{
                            [[theValue(event.location.horizontalAccuracy) should] equal:location.horizontalAccuracy
                                                                              withDelta:EPSILON];
                        });
                        it(@"Should have valid verticalAccuracy", ^{
                            [[theValue(event.location.verticalAccuracy) should] equal:location.verticalAccuracy
                                                                            withDelta:EPSILON];
                        });
#if !TARGET_OS_TV
                        it(@"Should have valid altitude", ^{
                            [[theValue(event.location.course) should] equal:location.course withDelta:EPSILON];
                        });
                        it(@"Should have valid altitude", ^{
                            [[theValue(event.location.speed) should] equal:location.speed withDelta:EPSILON];
                        });
#endif
                        it(@"Should have valid timestamp", ^{
                            [[event.location.timestamp should] equal:location.timestamp];
                        });
                    });
                });
            });
            context(@"Location enabled", ^{
                it(@"Should be true", ^{
                    eventData->has_location_enabled = true;
                    eventData->location_enabled = true;
                    fillEvent();
                    [[theValue(event.locationEnabled) should] equal:theValue(AMAOptionalBoolTrue)];
                });
                it(@"Should be false", ^{
                    eventData->has_location_enabled = true;
                    eventData->location_enabled = false;
                    fillEvent();
                    [[theValue(event.locationEnabled) should] equal:theValue(AMAOptionalBoolFalse)];
                });
                it(@"Should be undefined", ^{
                    eventData->has_location_enabled = false;
                    fillEvent();
                    [[theValue(event.locationEnabled) should] equal:theValue(AMAOptionalBoolUndefined)];
                });
            });
            context(@"Application environment", ^{
                context(@"Empty", ^{
                    beforeEach(^{
                        fillEvent();
                    });
                    it(@"Should have nil value", ^{
                        [[event.appEnvironment should] beNil];
                    });
                });
                context(@"Non-empty", ^{
                    beforeEach(^{
                        eventData->has_app_environment =
                            [AMAProtobufUtilities fillBinaryData:&eventData->app_environment
                                                      withString:@"{\"foo\":\"bar\",\"a\":\"A\"}"
                                                         tracker:tracker];
                        fillEvent();
                    });
                    it(@"Should have valid value", ^{
                        [[event.appEnvironment should] equal:@{ @"foo": @"bar", @"a": @"A" }];
                    });
                });
            });
            context(@"Error environment", ^{
                context(@"Empty", ^{
                    beforeEach(^{
                        fillEvent();
                    });
                    it(@"Should have nil value", ^{
                        [[event.eventEnvironment should] beNil];
                    });
                });
                context(@"Non-empty", ^{
                    beforeEach(^{
                        eventData->has_event_environment =
                            [AMAProtobufUtilities fillBinaryData:&eventData->event_environment
                                                      withString:@"{\"foo\":\"bar\",\"b\":\"B\"}"
                                                         tracker:tracker];

                        fillEvent();
                    });
                    it(@"Should have valid value", ^{
                        [[event.eventEnvironment should] equal:@{ @"foo": @"bar", @"b": @"B" }];
                    });
                });
            });
            context(@"Extras", ^{
                NSString *const key1 = @"KEY_1";
                NSData *const value1 = [@"test value 1" dataUsingEncoding:NSUTF8StringEncoding];

                NSString *const key2 = @"KEY_EMPTY";
                NSData *const value2 = [NSData new];

                NSString *const rawJSON = [NSString stringWithFormat:@"{\"KEY_1\":\"%@\"\n\"KEY_EMPTY\":\"%@\"}",
                        [value1 base64EncodedStringWithOptions: 0], [value2 base64EncodedStringWithOptions:0]
                ];

                NSDictionary<NSString *, NSData *> *const extras = @{
                        key1: value1,
                        key2: value2,
                };


                beforeEach(^{
                    Ama__EventData__ExtraEntry *extra1 = [tracker allocateSize:sizeof(Ama__EventData__ExtraEntry)];
                    ama__event_data__extra_entry__init(extra1);
                    [AMAProtobufUtilities fillBinaryData:&extra1->key
                                              withString:key1
                                                 tracker:tracker];
                    [AMAProtobufUtilities fillBinaryData:&extra1->value
                                                withData:value1
                                                 tracker:tracker];

                    Ama__EventData__ExtraEntry *extra2 = [tracker allocateSize:sizeof(Ama__EventData__ExtraEntry)];
                    ama__event_data__extra_entry__init(extra2);
                    [AMAProtobufUtilities fillBinaryData:&extra2->key
                                              withString:key2
                                                 tracker:tracker];
                    [AMAProtobufUtilities fillBinaryData:&extra2->value
                                                withData:value2
                                                 tracker:tracker];

                    Ama__EventData__ExtraEntry **extras = [tracker allocateSize:sizeof(Ama__EventData__ExtraEntry *) * 2];
                    extras[0] = extra1;
                    extras[1] = extra2;

                    eventData->n_extras = 2;
                    eventData->extras = extras;

                    fillEvent();
                });

                context(@"Should have keys", ^{
                    [[theValue(event.extras.count) should] equal:theValue(2)];
                    [[event.extras[key1] should] equal: value1];
                    [[event.extras[key2] should] equal: value2];
                });

            });
            context(@"Profile ID", ^{
                it(@"Should have valid value", ^{
                    NSString *profileID = @"PROFILE_ID";
                    eventData->has_user_profile_id = [AMAProtobufUtilities fillBinaryData:&eventData->user_profile_id
                                                                               withString:profileID
                                                                                  tracker:tracker];
                    fillEvent();
                    [[event.profileID should] equal:profileID];
                });
                it(@"Should be nil", ^{
                    fillEvent();
                    [[event.profileID should] beNil];
                });
            });
        });
    });

});

SPEC_END
