
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMACore.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaProtobufUtils/AppMetricaProtobufUtils.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMASessionSerializer.h"
#import "AMAAppStateManagerTestHelper.h"
#import "AMADatabaseConstants.h"
#import "AMASession.h"
#import "AMADate.h"
#import "SessionData.pb-c.h"
#import "AMAReporterDatabaseEncodersFactory.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAReporterDatabaseMigrationTo500EncodersFactory.h"
#import "AMAReporterDatabaseMigrationTo5100EncodersFactory.h"
#import "AMASessionSerializer+Migration.h"

SPEC_BEGIN(AMASessionSerializerTests)

describe(@"AMASessionSerializer", ^{

    double const EPSILON = 0.0001;

    AMASession *__block session = nil;
    NSObject<AMADataEncoding> *__block encoder = nil;
    AMAAppStateManagerTestHelper *__block stateHelper = nil;
    AMASessionSerializer *__block serializer = nil;
    
    __auto_type *const encoderFactory = [[AMAReporterDatabaseEncodersFactory alloc] init];
    __auto_type *const encoderTo500Factory = [[AMAReporterDatabaseMigrationTo500EncodersFactory alloc] init];
    __auto_type *const encoderTo5100Factory = [[AMAReporterDatabaseMigrationTo5100EncodersFactory alloc] init];

    beforeEach(^{
        [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];
        
        stateHelper = [[AMAAppStateManagerTestHelper alloc] init];
        [stateHelper stubApplicationState];
        session = [[AMASession alloc] init];
        [AMAReporterDatabaseEncodersFactory stubInstance:encoderFactory forInit:@selector(init)];
        [AMAReporterDatabaseMigrationTo500EncodersFactory stubInstance:encoderTo500Factory forInit:@selector(init)];
        [AMAReporterDatabaseMigrationTo5100EncodersFactory stubInstance:encoderTo5100Factory forInit:@selector(init)];
        encoder = (NSObject<AMADataEncoding> *)[encoderFactory encoderForEncryptionType:AMAReporterDatabaseEncryptionTypeAES];
        serializer = [[AMASessionSerializer alloc] init];
    });

    context(@"Serialization", ^{

        NSObject *(^field)(NSString *) = ^(NSString *fieldKey) {
            return [serializer dictionaryForSession:session error:nil][fieldKey];
        };

        context(@"DB fields", ^{
            it(@"Should store oid", ^{
                NSNumber *oid = @23;
                session.oid = oid;
                [[field(kAMACommonTableFieldOID) should] equal:oid];
            });
            it(@"Should store createdAt", ^{
                NSDate *createdAt = [NSDate date];
                session.startDate = [[AMADate alloc] init];
                session.startDate.deviceDate = createdAt;
                NSNumber *timeInterval = (NSNumber *)field(kAMASessionTableFieldStartTime);
                [[theValue([timeInterval doubleValue]) should] equal:createdAt.timeIntervalSinceReferenceDate
                                                           withDelta:EPSILON];
            });
            context(@"Finished", ^{
                it(@"Should store NO", ^{
                    session.finished = NO;
                    [[field(kAMASessionTableFieldFinished) should] equal:@NO];
                });
                it(@"Should store YES", ^{
                    session.finished = YES;
                    [[field(kAMASessionTableFieldFinished) should] equal:@YES];
                });
            });
            it(@"Should store lastEventTime", ^{
                NSDate *date = [NSDate date];
                session.lastEventTime = date;
                NSNumber *timeInterval = (NSNumber *)field(kAMASessionTableFieldLastEventTime);
                [[theValue([timeInterval doubleValue]) should] equal:date.timeIntervalSinceReferenceDate
                                                           withDelta:EPSILON];
            });
            it(@"Should store pauseTime", ^{
                NSDate *date = [NSDate date];
                session.pauseTime = date;
                NSNumber *timeInterval = (NSNumber *)field(kAMASessionTableFieldPauseTime);
                [[theValue([timeInterval doubleValue]) should] equal:date.timeIntervalSinceReferenceDate
                                                           withDelta:EPSILON];
            });
            it(@"Should store eventSeq", ^{
                NSUInteger sequenceNumber = 108;
                session.eventSeq = sequenceNumber;
                [[field(kAMASessionTableFieldEventSeq) should] equal:@(sequenceNumber)];
            });
            it(@"Should store session type", ^{
                AMASessionType type = AMASessionTypeBackground;
                session.type = type;
                [[field(kAMACommonTableFieldType) should] equal:@(type)];
            });
            it(@"Should have valid encryption type", ^{
                [[field(kAMACommonTableFieldDataEncryptionType) should] equal:@(AMAReporterDatabaseEncryptionTypeAES)];
            });
            it(@"Should have non-empty data", ^{
                [[field(kAMACommonTableFieldData) shouldNot] beEmpty];
            });
        });

        context(@"Data", ^{
            AMAProtobufAllocator *__block allocator = nil;
            Ama__SessionData *__block sessionData = NULL;

            void (^fillSessionData)(void) = ^{
                NSData *data = (NSData *)field(kAMACommonTableFieldData);
                NSData *decodedData = [encoder decodeData:data error:nil];
                sessionData = ama__session_data__unpack(allocator.protobufCAllocator, decodedData.length, decodedData.bytes);
            };

            beforeEach(^{
                allocator = [[AMAProtobufAllocator alloc] init];
            });

            it(@"Should have valid session id", ^{
                NSNumber *sessionID = @108;
                session.sessionID = sessionID;
                fillSessionData();
                [[theValue(sessionData->session_id) should] equal:theValue(sessionID.integerValue)];
            });
            it(@"Should have valid attribution ID", ^{
                NSString *attributionID = @"ATTRIBUTION_ID";
                session.attributionID = attributionID;
                fillSessionData();
                NSString *value = [AMAProtobufUtilities stringForBinaryData:&sessionData->attribution_id
                                                                        has:sessionData->has_attribution_id];
                [[value should] equal:attributionID];
            });
            context(@"Server time offset", ^{
                context(@"With value", ^{
                    NSNumber *offset = @23;
                    beforeEach(^{
                        session.startDate = [[AMADate alloc] init];
                        session.startDate.serverTimeOffset = offset;
                        fillSessionData();
                    });
                    it(@"Should have value", ^{
                        [[theValue(sessionData->has_server_time_offset) should] beYes];
                    });
                    it(@"Should have valid value", ^{
                        [[theValue(sessionData->server_time_offset) should] equal:theValue(offset.integerValue)];
                    });
                });
                context(@"Without value", ^{
                    beforeEach(^{
                        fillSessionData();
                    });
                    it(@"Should not have value", ^{
                        [[theValue(sessionData->has_server_time_offset) should] beNo];
                    });
                });
            });
            context(@"App state", ^{
                Ama__SessionData__AppState *__block appStateData = NULL;
                beforeEach(^{
                    session.appState = AMAApplicationStateManager.applicationState;
                    fillSessionData();
                    appStateData = sessionData->app_state;
                });
                it(@"Should have valid locale", ^{
                    NSString *value = [AMAProtobufUtilities stringForBinaryData:&appStateData->locale
                                                                            has:appStateData->has_locale];
                    [[value should] equal:stateHelper.locale];
                });
                it(@"Should have valid app version name", ^{
                    NSString *value = [AMAProtobufUtilities stringForBinaryData:&appStateData->app_version_name
                                                                            has:appStateData->has_app_version_name];
                    [[value should] equal:stateHelper.appVersionName];
                });
                it(@"Should have valid app build number", ^{
                    NSString *value = [AMAProtobufUtilities stringForBinaryData:&appStateData->app_build_number
                                                                            has:appStateData->has_app_build_number];
                    [[value should] equal:[@(stateHelper.appBuildNumber) stringValue]];
                });
                it(@"Should have valid app debugable", ^{
                    [[theValue(appStateData->app_debuggable) should] beYes];
                });
                it(@"Should have no kit version", ^{
                    NSString *value = [AMAProtobufUtilities stringForBinaryData:&appStateData->kit_version
                                                                            has:appStateData->has_kit_version];
                    [[value should] beNil];
                });
                it(@"Should have valid kit version name", ^{
                    NSString *value = [AMAProtobufUtilities stringForBinaryData:&appStateData->kit_version_name
                                                                            has:appStateData->has_kit_version_name];
                    [[value should] equal:stateHelper.kitVersionName];
                });
                it(@"Should have valid kit build type", ^{
                    NSString *value = [AMAProtobufUtilities stringForBinaryData:&appStateData->kit_build_type
                                                                            has:appStateData->has_kit_build_type];
                    [[value should] equal:stateHelper.kitBuildType];
                });
                it(@"Should have valid kit build number", ^{
                    [[theValue(appStateData->kit_build_number) should] equal:theValue(stateHelper.kitBuildNumber)];
                });
                it(@"Should have valid OS version", ^{
                    NSString *value = [AMAProtobufUtilities stringForBinaryData:&appStateData->os_version
                                                                            has:appStateData->has_os_version];
                    [[value should] equal:stateHelper.OSVersion];
                });
                it(@"Should have valid OS API level", ^{
                    [[theValue(appStateData->os_api_level) should] equal:theValue(stateHelper.OSAPILevel)];
                });
                it(@"Should have valid rooted flag", ^{
                    [[theValue(appStateData->is_rooted) should] beNo];
                });
                it(@"Should have valid UUID", ^{
                    NSString *value = [AMAProtobufUtilities stringForBinaryData:&appStateData->uuid
                                                                            has:appStateData->has_uuid];
                    [[value should] equal:stateHelper.UUID];
                });
                it(@"Should have valid device ID", ^{
                    NSString *value = [AMAProtobufUtilities stringForBinaryData:&appStateData->device_id
                                                                            has:appStateData->has_device_id];
                    [[value should] equal:stateHelper.deviceID];
                });
                it(@"Should have valid IFV", ^{
                    NSString *value = [AMAProtobufUtilities stringForBinaryData:&appStateData->ifv
                                                                            has:appStateData->has_ifv];
                    [[value should] equal:stateHelper.IFV];
                });
                it(@"Should have valid IFA", ^{
                    NSString *value = [AMAProtobufUtilities stringForBinaryData:&appStateData->ifa
                                                                            has:appStateData->has_ifa];
                    [[value should] equal:stateHelper.IFA];
                });
                it(@"Should have valid LAT flag", ^{
                    [[theValue(appStateData->lat) should] beNo];
                });
            });
        });
    });

    context(@"Deserialization", ^{
        id<AMAAllocationsTracking> __block tracker = nil;
        Ama__SessionData *__block sessionData = NULL;
        NSMutableDictionary *__block sessionDictionary = nil;

        void (^prepareDictionary)(void) = ^{
            size_t dataSize = ama__session_data__get_packed_size(sessionData);
            void *dataBytes = malloc(dataSize);
            dataSize = ama__session_data__pack(sessionData, dataBytes);
            NSData *data = [NSData dataWithBytesNoCopy:dataBytes length:dataSize];
            NSData *encodedData = [encoder encodeData:data error:nil];
            sessionDictionary[kAMACommonTableFieldData] = encodedData;
            sessionDictionary[kAMACommonTableFieldDataEncryptionType] = @(AMAReporterDatabaseEncryptionTypeAES);
        };

        void (^fillSession)(void) = ^{
            prepareDictionary();
            session = [serializer sessionForDictionary:sessionDictionary error:nil];
        };

        beforeEach(^{
            tracker = [AMAAllocationsTrackerProvider manuallyHandledTracker];

            sessionData = [tracker allocateSize:sizeof(Ama__SessionData)];
            ama__session_data__init(sessionData);
            sessionData->app_state = [tracker allocateSize:sizeof(Ama__SessionData__AppState)];
            ama__session_data__app_state__init(sessionData->app_state);

            sessionDictionary = [NSMutableDictionary dictionary];
        });
        
        it(@"Should create different encoder", ^{
            [[encoderFactory should] receive:@selector(encoderForEncryptionType:)
                               withArguments:theValue(AMAReporterDatabaseEncryptionTypeGZipAES)];
            prepareDictionary();
            sessionDictionary[kAMACommonTableFieldDataEncryptionType] = @(AMAReporterDatabaseEncryptionTypeGZipAES);
            [serializer sessionForDictionary:sessionDictionary error:nil];
        });
        it(@"Should create migration to 5.0.0 encoder", ^{
            AMASessionSerializer *__block migrationSerialzer = [[AMASessionSerializer alloc] migrationTo500Init];
            
            [[encoderTo500Factory should] receive:@selector(encoderForEncryptionType:)
                                    withArguments:theValue(AMAReporterDatabaseEncryptionTypeGZipAES)];
            prepareDictionary();
            sessionDictionary[kAMACommonTableFieldDataEncryptionType] = @(AMAReporterDatabaseEncryptionTypeGZipAES);
            [migrationSerialzer sessionForDictionary:sessionDictionary error:nil];
        });
        it(@"Should create migration to 5.10.0 encoder", ^{
            AMASessionSerializer *__block migrationSerialzer = [[AMASessionSerializer alloc] migrationTo5100Init];
            
            [[encoderTo5100Factory should] receive:@selector(encoderForEncryptionType:)
                                     withArguments:theValue(AMAReporterDatabaseEncryptionTypeGZipAES)];
            prepareDictionary();
            sessionDictionary[kAMACommonTableFieldDataEncryptionType] = @(AMAReporterDatabaseEncryptionTypeGZipAES);
            [migrationSerialzer sessionForDictionary:sessionDictionary error:nil];
        });
        it(@"Should return nil if data is empty", ^{
            prepareDictionary();
            NSData *encodedData = [encoder encodeData:[NSData data] error:nil];
            sessionDictionary[kAMACommonTableFieldData] = encodedData;
            [[[serializer sessionForDictionary:sessionDictionary error:nil] should] beNil];
        });
        it(@"Should return nil if data is not a valid protobuf", ^{
            prepareDictionary();
            NSData *encodedData = [encoder encodeData:[@"NOT_A_PROTOBUF" dataUsingEncoding:NSUTF8StringEncoding]
                                                error:nil];
            sessionDictionary[kAMACommonTableFieldData] = encodedData;
            [[[serializer sessionForDictionary:sessionDictionary error:nil] should] beNil];
        });
        it(@"Should return nil if eventSeq is data", ^{
            prepareDictionary();
            sessionDictionary[kAMASessionTableFieldEventSeq] = [@"DATA" dataUsingEncoding:NSUTF8StringEncoding];
            [[[serializer sessionForDictionary:sessionDictionary error:nil] should] beNil];
        });

        it(@"Should have valid OID", ^{
            NSNumber *oid = @23;
            sessionDictionary[kAMACommonTableFieldOID] = oid;
            fillSession();
            [[session.oid should] equal:oid];
        });
        it(@"Should have valid type", ^{
            AMASessionType type = AMASessionTypeGeneral;
            sessionDictionary[kAMACommonTableFieldType] = @(type);
            fillSession();
            [[theValue(session.type) should] equal:theValue(type)];
        });
        it(@"Should have valid start time", ^{
            NSDate *date = [NSDate date];
            sessionDictionary[kAMASessionTableFieldStartTime] = @(date.timeIntervalSinceReferenceDate);
            fillSession();
            [[theValue(session.startDate.deviceDate.timeIntervalSinceReferenceDate) should] equal:date.timeIntervalSinceReferenceDate
                                                                                        withDelta:EPSILON];
        });
        it(@"Should have valid last event time", ^{
            NSDate *date = [NSDate date];
            sessionDictionary[kAMASessionTableFieldLastEventTime] = @(date.timeIntervalSinceReferenceDate);
            fillSession();
            [[theValue(session.lastEventTime.timeIntervalSinceReferenceDate) should] equal:date.timeIntervalSinceReferenceDate
                                                                                 withDelta:EPSILON];
        });
        it(@"Should have valid pause time", ^{
            NSDate *date = [NSDate date];
            sessionDictionary[kAMASessionTableFieldPauseTime] = @(date.timeIntervalSinceReferenceDate);
            fillSession();
            [[theValue(session.pauseTime.timeIntervalSinceReferenceDate) should] equal:date.timeIntervalSinceReferenceDate
                                                                             withDelta:EPSILON];
        });
        it(@"Should have valid eventSeq", ^{
            NSNumber *number = @42;
            sessionDictionary[kAMASessionTableFieldEventSeq] = number;
            fillSession();
            [[theValue(session.eventSeq) should] equal:theValue(number.integerValue)];
        });
        context(@"Finished", ^{
            it(@"Should be YES", ^{
                sessionDictionary[kAMASessionTableFieldFinished] = @YES;
                fillSession();
                [[theValue(session.finished) should] beYes];
            });
            it(@"Should be NO", ^{
                sessionDictionary[kAMASessionTableFieldFinished] = @NO;
                fillSession();
                [[theValue(session.finished) should] beNo];
            });
        });
        context(@"Data", ^{
            it(@"Should have valid session ID", ^{
                NSNumber *sessionID = @108;
                sessionData->session_id = (int64_t)sessionID.integerValue;
                fillSession();
                [[session.sessionID should] equal:sessionID];
            });
            it(@"Should have valid attribution ID", ^{
                NSString *attributionID = @"ATTRIBUTION_ID";
                sessionData->has_attribution_id = [AMAProtobufUtilities fillBinaryData:&sessionData->attribution_id
                                                                            withString:attributionID
                                                                               tracker:tracker];
                fillSession();
                [[session.attributionID should] equal:attributionID];
            });
            context(@"Server time offset", ^{
                it(@"Should be nil", ^{
                    sessionData->has_server_time_offset = false;
                    fillSession();
                    [[session.startDate.serverTimeOffset should] beNil];
                });
                it(@"Should have valid value", ^{
                    NSInteger offset = 23;
                    sessionData->has_server_time_offset = true;
                    sessionData->server_time_offset = (int32_t)offset;
                    fillSession();
                    [[session.startDate.serverTimeOffset should] equal:@(offset)];
                });
            });
            context(@"App state", ^{
                Ama__SessionData__AppState *__block appStateData = NULL;
                beforeEach(^{
                    appStateData = sessionData->app_state;
                });
                it(@"Should have valid locale", ^{
                    NSString *value = @"LOCALE";
                    appStateData->has_locale = [AMAProtobufUtilities fillBinaryData:&appStateData->locale
                                                                         withString:value
                                                                            tracker:tracker];
                    fillSession();
                    [[session.appState.locale should] equal:value];
                });
                it(@"Should have valid app version name", ^{
                    NSString *value = @"APP_VERSION_NAME";
                    appStateData->has_app_version_name = [AMAProtobufUtilities fillBinaryData:&appStateData->app_version_name
                                                                                   withString:value
                                                                                      tracker:tracker];
                    fillSession();
                    [[session.appState.appVersionName should] equal:value];
                });
                it(@"Should have valid app build number", ^{
                    NSString *value = @"123";
                    appStateData->has_app_build_number = [AMAProtobufUtilities fillBinaryData:&appStateData->app_build_number
                                                                                   withString:value
                                                                                      tracker:tracker];
                    fillSession();
                    [[session.appState.appBuildNumber should] equal:value];
                });
                context(@"App debuggable", ^{
                    it(@"Should be YES", ^{
                        appStateData->app_debuggable = true;
                        fillSession();
                        [[theValue(session.appState.appDebuggable) should] beYes];
                    });
                    it(@"Should be NO", ^{
                        appStateData->app_debuggable = false;
                        fillSession();
                        [[theValue(session.appState.appDebuggable) should] beNo];
                    });
                });
                it(@"Should have no kit version", ^{
                    NSString *value = @"999";
                    appStateData->has_kit_version = [AMAProtobufUtilities fillBinaryData:&appStateData->kit_version
                                                                              withString:value
                                                                                 tracker:tracker];
                    fillSession();
                    [[session.appState.kitVersion should] equal:value];
                });
                it(@"Should have valid kit version name", ^{
                    NSString *value = @"9.9.9";
                    appStateData->has_kit_version_name = [AMAProtobufUtilities fillBinaryData:&appStateData->kit_version_name
                                                                                   withString:value
                                                                                      tracker:tracker];
                    fillSession();
                    [[session.appState.kitVersionName should] equal:value];
                });
                it(@"Should have valid kit build type", ^{
                    NSString *value = @"KIT_BUILD_TYPE";
                    appStateData->has_kit_build_type = [AMAProtobufUtilities fillBinaryData:&appStateData->kit_build_type
                                                                                 withString:value
                                                                                    tracker:tracker];
                    fillSession();
                    [[session.appState.kitBuildType should] equal:value];
                });
                it(@"Should have valid kit build number", ^{
                    NSUInteger number = 12345;
                    appStateData->kit_build_number = (uint32_t)number;
                    fillSession();
                    [[theValue(session.appState.kitBuildNumber) should] equal:theValue(number)];
                });
                it(@"Should have valid OS version", ^{
                    NSString *value = @"OS_VERSION";
                    appStateData->has_os_version = [AMAProtobufUtilities fillBinaryData:&appStateData->os_version
                                                                             withString:value
                                                                                tracker:tracker];
                    fillSession();
                    [[session.appState.OSVersion should] equal:value];
                });
                it(@"Should have valid OS API level", ^{
                    NSUInteger number = 99;
                    appStateData->os_api_level = (int32_t)number;
                    fillSession();
                    [[theValue(session.appState.OSAPILevel) should] equal:theValue(number)];
                });
                context(@"Rooted", ^{
                    it(@"Should be YES", ^{
                        appStateData->is_rooted = true;
                        fillSession();
                        [[theValue(session.appState.isRooted) should] beYes];
                    });
                    it(@"Should be NO", ^{
                        appStateData->is_rooted = false;
                        fillSession();
                        [[theValue(session.appState.isRooted) should] beNo];
                    });
                });
                it(@"Should have valid UUID", ^{
                    NSString *value = @"UUID";
                    appStateData->has_uuid = [AMAProtobufUtilities fillBinaryData:&appStateData->uuid
                                                                       withString:value
                                                                          tracker:tracker];
                    fillSession();
                    [[session.appState.UUID should] equal:value];
                });
                it(@"Should have valid device ID", ^{
                    NSString *value = @"DEVICE_ID";
                    appStateData->has_device_id = [AMAProtobufUtilities fillBinaryData:&appStateData->device_id
                                                                            withString:value
                                                                               tracker:tracker];
                    fillSession();
                    [[session.appState.deviceID should] equal:value];
                });
                it(@"Should have valid IFV", ^{
                    NSString *value = @"IFV";
                    appStateData->has_ifv = [AMAProtobufUtilities fillBinaryData:&appStateData->ifv
                                                                      withString:value
                                                                         tracker:tracker];
                    fillSession();
                    [[session.appState.IFV should] equal:value];
                });
                it(@"Should have valid IFA", ^{
                    NSString *value = @"IFA";
                    appStateData->has_ifa = [AMAProtobufUtilities fillBinaryData:&appStateData->ifa
                                                                      withString:value
                                                                         tracker:tracker];
                    fillSession();
                    [[session.appState.IFA should] equal:value];
                });
                context(@"LAT", ^{
                    it(@"Should be YES", ^{
                        appStateData->lat = true;
                        fillSession();
                        [[theValue(session.appState.LAT) should] beYes];
                    });
                    it(@"Should be NO", ^{
                        appStateData->lat = false;
                        fillSession();
                        [[theValue(session.appState.LAT) should] beNo];
                    });
                });
            });
        });
    });

});

SPEC_END
