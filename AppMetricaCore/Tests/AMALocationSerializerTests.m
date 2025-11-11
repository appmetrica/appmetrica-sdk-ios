
#import <CoreLocation/CoreLocation.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaProtobufUtils/AppMetricaProtobufUtils.h>
#import "LocationMessage.pb-c.h"
#import "AMALocationSerializer.h"
#import "AMALocation.h"
#import "AMAVisit.h"

SPEC_BEGIN(AMALocationSerializerTests)

describe(@"AMALocationSerializer", ^{

    double const EPSILON = 0.0000001;
            
    NSString *const base64Data = @"CiIIFxAqGBchAAAAAAAALkApAAAAAAAAMEAwBDggQFxICFAACh0IIBBsGCohP"
                                  "1OvWwTySkApI4PcRZiGO0BI/gFQARojCAoQGRgPIBgpAAAAAAAAGEAxA"
                                  "AAAAAAAHEA5mpmZmZmZuT8aFggUEC0pAAAAAAAAIEAxAAAAAAAAIkA=";
    NSData *const data = [[NSData alloc] initWithBase64EncodedString:base64Data options:0];
         
    NSArray *__block locations = nil;
    NSArray<AMAVisit *> *__block visits = nil;
         
    AMALocationSerializer *__block serializer = nil;

    beforeEach(^{
        CLLocation *firstSystemLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(15.0, 16.0)
                                                                        altitude:8.0
                                                              horizontalAccuracy:4.0
                                                                verticalAccuracy:23.0
                                                                          course:32.0
                                                                           speed:92.0
                                                                       timestamp:[NSDate dateWithTimeIntervalSince1970:23.0]];
        AMALocation *firstLocation = [[AMALocation alloc] initWithIdentifier:@23
                                                                 collectDate:[NSDate dateWithTimeIntervalSince1970:42.0]
                                                                    location:firstSystemLocation
                                                                    provider:AMALocationProviderUnknown];
        CLLocation *secondSystemLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(53.890758, 27.525761)
                                                                         altitude:254.0
                                                               horizontalAccuracy:-1.0
                                                                 verticalAccuracy:-1.0
                                                                           course:-1.0
                                                                            speed:-1.0
                                                                        timestamp:[NSDate dateWithTimeIntervalSince1970:42.0]];
        AMALocation *secondLocation = [[AMALocation alloc] initWithIdentifier:@32
                                                                  collectDate:[NSDate dateWithTimeIntervalSince1970:108.0]
                                                                     location:secondSystemLocation
                                                                     provider:AMALocationProviderGPS];
        locations = @[ firstLocation, secondLocation ];
    
        visits = @[
            [AMAVisit visitWithIdentifier:@10
                              collectDate:[NSDate dateWithTimeIntervalSince1970:25.0]
                              arrivalDate:[NSDate dateWithTimeIntervalSince1970:15.0]
                            departureDate:[NSDate dateWithTimeIntervalSince1970:24.0]
                                 latitude:6.0
                                longitude:7.0
                                precision:0.1],
            [AMAVisit visitWithIdentifier:@20
                              collectDate:[NSDate dateWithTimeIntervalSince1970:45.0]
                              arrivalDate:nil
                            departureDate:nil
                                 latitude:8.0
                                longitude:9.0
                                precision:-123.0],
        ];

        serializer = [[AMALocationSerializer alloc] init];
    });

    context(@"Visit serialization", ^{
        AMAProtobufAllocator *__block allocator = nil;
        Ama__LocationMessage *__block message = NULL;

        beforeEach(^{
            NSData *data = [serializer dataForLocations:@[ locations.firstObject ] visits:visits];
            message = ama__location_message__unpack([allocator protobufCAllocator], data.length, data.bytes);
            allocator = [[AMAProtobufAllocator alloc] init];
        });

        afterEach(^{
            allocator = nil;
        });
    
        it(@"Should serialize 2 visits", ^{
            [[theValue(message->n_visits) should] equal:@2];
        });
    
        it(@"Should serialize 1 location", ^{
            [[theValue(message->n_location) should] equal:@1];
        });
    
        context(@"First visit", ^{
            
            Ama__LocationMessage__Visit *__block visit = nil;
            
            beforeEach(^{
                visit = message->visits[0];
            });
            
            it(@"Should have valid id", ^{
                [[theValue(visit->incremental_id) should] equal:visits[0].identifier];
            });
            
            it(@"Should have valid collectDate", ^{
                [[theValue(visit->collect_timestamp) should] equal:theValue(visits[0].collectDate.timeIntervalSince1970)];
            });
            
            it(@"Should have arrivalDate", ^{
                [[theValue(visit->has_arrival_timestamp) should] beYes];
            });
            
            it(@"Should have valid arrivalDate", ^{
                [[theValue(visit->arrival_timestamp) should] equal:theValue(visits[0].arrivalDate.timeIntervalSince1970)];
            });
            
            it(@"Should have departureDate", ^{
                [[theValue(visit->has_departure_timestamp) should] beYes];
            });
            
            it(@"Should have valid departureDate", ^{
                [[theValue(visit->departure_timestamp) should] equal:theValue(visits[0].departureDate.timeIntervalSince1970)];
            });
            
            it(@"Should have valid latitude", ^{
                [[theValue(visit->latitude) should] equal:theValue(visits[0].latitude)];
            });
            
            it(@"Should have valid longitude", ^{
                [[theValue(visit->longitude) should] equal:theValue(visits[0].longitude)];
            });
            
            it(@"Should have precision", ^{
                [[theValue(visit->has_precision) should] beYes];
            });
            
            it(@"Should have valid precision", ^{
                [[theValue(visit->precision) should] equal:theValue(visits[0].precision)];
            });
        });
    
        context(@"Second visit", ^{
            
            Ama__LocationMessage__Visit *__block visit = nil;
            
            beforeEach(^{
                visit = message->visits[1];
            });
            
            it(@"Should have valid id", ^{
                [[theValue(visit->incremental_id) should] equal:visits[1].identifier];
            });
            
            it(@"Should have valid collectDate", ^{
                [[theValue(visit->collect_timestamp) should] equal:theValue(visits[1].collectDate.timeIntervalSince1970)];
            });
            
            it(@"Should not have arrivalDate", ^{
                [[theValue(visit->has_arrival_timestamp) should] beNo];
            });
            
            it(@"Should not have departureDate", ^{
                [[theValue(visit->has_departure_timestamp) should] beNo];
            });
            
            it(@"Should not have precision", ^{
                [[theValue(visit->has_precision) should] beNo];
            });
        });
    });
    
    context(@"Visit deserialization", ^{
        NSArray<AMAVisit *> *__block deserializedVisits = nil;

        beforeEach(^{
            deserializedVisits = [serializer visitsForData:data];
        });
    
        it(@"Should return nil for nil data", ^{
            [[[serializer visitsForData:nil] should] beNil];
        });

        it(@"Should return nil for empty data", ^{
            [[[serializer visitsForData:[NSData data]] should] beNil];
        });

        it(@"Should return nil for broken data", ^{
            [[[serializer visitsForData:[@"BROKEN" dataUsingEncoding:NSUTF8StringEncoding]] should] beNil];
        });

        it(@"Should deserialize 2 visits", ^{
            [[deserializedVisits should] haveCountOf:2];
        });
        
        context(@"First visit", ^{
            
            it(@"Should have valid id", ^{
                [[deserializedVisits[0].identifier should] equal:visits[0].identifier];
            });
            
            it(@"Should have valid collectDate", ^{
                [[deserializedVisits[0].collectDate should] equal:visits[0].collectDate];
            });
            
            it(@"Should have valid arrivalDate", ^{
                [[deserializedVisits[0].arrivalDate should] equal:visits[0].arrivalDate];
            });
            
            it(@"Should have valid departureDate", ^{
                [[deserializedVisits[0].departureDate should] equal:visits[0].departureDate];
            });
            
            it(@"Should have valid latitude", ^{
                [[theValue(deserializedVisits[0].latitude) should] equal:visits[0].latitude withDelta:EPSILON];
            });
            
            it(@"Should have valid longitude", ^{
                [[theValue(deserializedVisits[0].longitude) should] equal:visits[0].longitude withDelta:EPSILON];
            });
            
            it(@"Should have valid precision", ^{
                [[theValue(deserializedVisits[0].precision) should] equal:visits[0].precision withDelta:EPSILON];
            });
        });
    
        context(@"Second visit", ^{
            
            it(@"Should have valid id", ^{
                [[deserializedVisits[1].identifier should] equal:visits[1].identifier];
            });
            
            it(@"Should have valid collectDate", ^{
                [[deserializedVisits[1].collectDate should] equal:visits[1].collectDate];
            });
            
            it(@"Should have valid arrivalDate", ^{
                [[deserializedVisits[1].arrivalDate should] beNil];
            });
            
            it(@"Should have valid departureDate", ^{
                [[deserializedVisits[1].departureDate should] beNil];
            });
            
            it(@"Should have valid latitude", ^{
                [[theValue(deserializedVisits[1].latitude) should] equal:visits[1].latitude withDelta:EPSILON];
            });
            
            it(@"Should have valid longitude", ^{
                [[theValue(deserializedVisits[1].longitude) should] equal:visits[1].longitude withDelta:EPSILON];
            });
            
            it(@"Should have precision placeholder", ^{
                [[theValue(deserializedVisits[1].precision) should] beLessThan:theValue(0)];
            });
        });
    });
    
    context(@"Location serialization", ^{
        AMAProtobufAllocator *__block allocator = nil;
        Ama__LocationMessage *__block message = NULL;

        beforeEach(^{
            allocator = [[AMAProtobufAllocator alloc] init];

            NSData *data = [serializer dataForLocations:locations];
            message = ama__location_message__unpack([allocator protobufCAllocator], data.length, data.bytes);
        });

        afterEach(^{
            allocator = nil;
        });

        it(@"Should serialize 2 location", ^{
            [[theValue(message->n_location) should] equal:theValue(2)];
        });

        context(@"First location", ^{
            AMALocation *__block location = nil;
            Ama__LocationMessage__Location *__block locationMessage = NULL;
            beforeEach(^{
                location = locations[0];
                locationMessage = message->location[0];
            });

            it(@"Should have valid id", ^{
                [[theValue(locationMessage->incremental_id) should] equal:theValue(location.identifier.integerValue)];
            });
            it(@"Should have valid collect date", ^{
                [[theValue(locationMessage->collect_timestamp) should] equal:theValue((int)location.collectDate.timeIntervalSince1970)];
            });
            it(@"Should have valid latitude", ^{
                [[theValue(locationMessage->latitude) should] equal:location.location.coordinate.latitude withDelta:EPSILON];
            });
            it(@"Should have valid longitude", ^{
                [[theValue(locationMessage->longitude) should] equal:location.location.coordinate.longitude withDelta:EPSILON];
            });
            it(@"Should have date", ^{
                [[theValue(locationMessage->has_timestamp) should] beYes];
            });
            it(@"Should have valid date", ^{
                [[theValue(locationMessage->timestamp) should] equal:theValue((int)location.location.timestamp.timeIntervalSince1970)];
            });
            it(@"Should have altitude", ^{
                [[theValue(locationMessage->has_altitude) should] beYes];
            });
            it(@"Should have valid altitude", ^{
                [[theValue(locationMessage->altitude) should] equal:theValue((int)location.location.altitude)];
            });
            it(@"Should have precision", ^{
                [[theValue(locationMessage->has_precision) should] beYes];
            });
            it(@"Should have valid precision", ^{
                [[theValue(locationMessage->precision) should] equal:theValue((int)location.location.horizontalAccuracy)];
            });
#if !TARGET_OS_TV
            it(@"Should have precision", ^{
                [[theValue(locationMessage->has_direction) should] beYes];
            });
            it(@"Should have valid precision", ^{
                [[theValue(locationMessage->direction) should] equal:theValue((int)location.location.course)];
            });
            it(@"Should have precision", ^{
                [[theValue(locationMessage->has_speed) should] beYes];
            });
            it(@"Should have valid precision", ^{
                [[theValue(locationMessage->speed) should] equal:theValue((int)location.location.speed)];
            });
#endif
            it(@"Should have provider", ^{
                [[theValue(locationMessage->has_provider) should] beYes];
            });
            it(@"Should have valid provider", ^{
                [[theValue(locationMessage->provider) should] equal:theValue(AMA__LOCATION_PROVIDER__PROVIDER_UNKNOWN)];
            });
        });

        context(@"Second location", ^{
            AMALocation *__block location = nil;
            Ama__LocationMessage__Location *__block locationMessage = NULL;
            beforeEach(^{
                location = locations[1];
                locationMessage = message->location[1];
            });

            it(@"Should have valid id", ^{
                [[theValue(locationMessage->incremental_id) should] equal:theValue(location.identifier.integerValue)];
            });
            it(@"Should have valid collect date", ^{
                [[theValue(locationMessage->collect_timestamp) should] equal:theValue((int)location.collectDate.timeIntervalSince1970)];
            });
            it(@"Should have valid latitude", ^{
                [[theValue(locationMessage->latitude) should] equal:location.location.coordinate.latitude withDelta:EPSILON];
            });
            it(@"Should have valid longitude", ^{
                [[theValue(locationMessage->longitude) should] equal:location.location.coordinate.longitude withDelta:EPSILON];
            });
            it(@"Should have date", ^{
                [[theValue(locationMessage->has_timestamp) should] beYes];
            });
            it(@"Should have valid date", ^{
                [[theValue(locationMessage->timestamp) should] equal:theValue((int)location.location.timestamp.timeIntervalSince1970)];
            });
            it(@"Should have altitude", ^{
                [[theValue(locationMessage->has_altitude) should] beYes];
            });
            it(@"Should have valid altitude", ^{
                [[theValue(locationMessage->altitude) should] equal:theValue((int)location.location.altitude)];
            });
            it(@"Should not have precision", ^{
                [[theValue(locationMessage->has_precision) should] beNo];
            });
            it(@"Shouldnot  have direction", ^{
                [[theValue(locationMessage->has_direction) should] beNo];
            });
            it(@"Should not have speed", ^{
                [[theValue(locationMessage->has_speed) should] beNo];
            });
            it(@"Should have provider", ^{
                [[theValue(locationMessage->has_provider) should] beYes];
            });
            it(@"Should have valid provider", ^{
                [[theValue(locationMessage->provider) should] equal:theValue(AMA__LOCATION_PROVIDER__PROVIDER_GPS)];
            });
        });
    });

    context(@"Location Deserialization", ^{
        NSArray *__block deserializedLocations = nil;

        beforeEach(^{
            deserializedLocations = [serializer locationsForData:data];
        });

        it(@"Should return nil for nil data", ^{
            [[[serializer locationsForData:nil] should] beNil];
        });

        it(@"Should return nil for empty data", ^{
            [[[serializer locationsForData:[NSData data]] should] beNil];
        });

        it(@"Should return nil for broken data", ^{
            [[[serializer locationsForData:[@"BROKEN" dataUsingEncoding:NSUTF8StringEncoding]] should] beNil];
        });

        it(@"Should deserialize 2 location", ^{
            [[deserializedLocations should] haveCountOf:2];
        });

        context(@"First location", ^{
            AMALocation *__block expectedLocation = nil;
            AMALocation *__block location = nil;
            beforeEach(^{
                expectedLocation = locations[0];
                location = deserializedLocations[0];
            });
            it(@"Should have valid id", ^{
                [[location.identifier should] equal:expectedLocation.identifier];
            });
            it(@"Should have valid collectDate", ^{
                [[location.collectDate should] equal:expectedLocation.collectDate];
            });
            it(@"Should have valid latitude", ^{
                [[theValue(location.location.coordinate.latitude) should] equal:expectedLocation.location.coordinate.latitude
                                                                      withDelta:EPSILON];
            });
            it(@"Should have valid longitude", ^{
                [[theValue(location.location.coordinate.longitude) should] equal:expectedLocation.location.coordinate.longitude
                                                                       withDelta:EPSILON];
            });
            it(@"Should have valid date", ^{
                [[location.location.timestamp should] equal:expectedLocation.location.timestamp];
            });
            it(@"Should have valid altitude", ^{
                [[theValue((int)location.location.altitude) should] equal:theValue((int)expectedLocation.location.altitude)];
            });
            it(@"Should have valid precision", ^{
                [[theValue((int)location.location.horizontalAccuracy) should] equal:theValue((int)expectedLocation.location.horizontalAccuracy)];
            });
#if !TARGET_OS_TV
            it(@"Should have valid precision", ^{
                [[theValue((int)location.location.course) should] equal:theValue((int)expectedLocation.location.course)];
            });
            it(@"Should have valid precision", ^{
                [[theValue((int)location.location.speed) should] equal:theValue((int)expectedLocation.location.speed)];
            });
#endif
            it(@"Should have valid provider", ^{
                [[theValue(location.provider) should] equal:theValue(AMALocationProviderUnknown)];
            });
        });

        context(@"Second location", ^{
            AMALocation *__block expectedLocation = nil;
            AMALocation *__block location = nil;
            beforeEach(^{
                expectedLocation = locations[1];
                location = deserializedLocations[1];
            });
            it(@"Should have valid id", ^{
                [[location.identifier should] equal:expectedLocation.identifier];
            });
            it(@"Should have valid collectDate", ^{
                [[location.collectDate should] equal:expectedLocation.collectDate];
            });
            it(@"Should have valid latitude", ^{
                [[theValue(location.location.coordinate.latitude) should] equal:expectedLocation.location.coordinate.latitude
                                                                      withDelta:EPSILON];
            });
            it(@"Should have valid longitude", ^{
                [[theValue(location.location.coordinate.longitude) should] equal:expectedLocation.location.coordinate.longitude
                                                                       withDelta:EPSILON];
            });
            it(@"Should have valid date", ^{
                [[location.location.timestamp should] equal:expectedLocation.location.timestamp];
            });
            it(@"Should have valid altitude", ^{
                [[theValue((int)location.location.altitude) should] equal:theValue((int)expectedLocation.location.altitude)];
            });
            it(@"Should have valid precision", ^{
                [[theValue((int)location.location.horizontalAccuracy) should] beLessThan:theValue(0)];
            });
            it(@"Should have valid precision", ^{
                [[theValue((int)location.location.course) should] beLessThan:theValue(0)];
            });
            it(@"Should have valid precision", ^{
                [[theValue((int)location.location.speed) should] beLessThan:theValue(0)];
            });
            it(@"Should have valid provider", ^{
                [[theValue(location.provider) should] equal:theValue(AMALocationProviderGPS)];
            });
        });
    });


});

SPEC_END

