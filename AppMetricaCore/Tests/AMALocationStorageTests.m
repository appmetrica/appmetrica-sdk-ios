
#import <Kiwi/Kiwi.h>
#import "AMALocationStorage.h"
#import "AMALocationCollectingConfiguration.h"
#import "AMALocationSerializer.h"
#import "AMADatabaseProtocol.h"
@import FMDB;
#import <CoreLocation/CoreLocation.h>
#import "AMALocation.h"
#import "AMAMockDatabase.h"
#import "AMAVisit.h"

SPEC_BEGIN(AMALocationStorageTests)

describe(@"AMALocationStorage", ^{
    
    double const EPSILON = 0.0000001;
         
    AMALocation *__block firstLocation = nil;
    AMALocation *__block secondLocation = nil;
    AMAVisit *__block firstVisit = nil;
    AMAVisit *__block secondVisit = nil;

    AMALocationCollectingConfiguration *__block configuration = nil;
    AMAMockDatabase *__block database = nil;;
    AMALocationStorage *__block storage = nil;

    beforeEach(^{
        CLLocation *firstSystemLocation = [[CLLocation alloc] initWithLatitude:15.0 longitude:16.0];
        firstLocation = [[AMALocation alloc] initWithIdentifier:@23
                                                    collectDate:[NSDate dateWithTimeIntervalSince1970:42.0]
                                                       location:firstSystemLocation
                                                       provider:AMALocationProviderUnknown];
        CLLocation *secondSystemLocation = [[CLLocation alloc] initWithLatitude:53.890758 longitude:27.525761];
        secondLocation = [[AMALocation alloc] initWithIdentifier:@32
                                                     collectDate:[NSDate dateWithTimeIntervalSince1970:108.0]
                                                        location:secondSystemLocation
                                                        provider:AMALocationProviderGPS];
    
        firstVisit = [AMAVisit visitWithIdentifier:@123
                                       collectDate:[NSDate dateWithTimeIntervalSince1970:65.0]
                                       arrivalDate:[NSDate dateWithTimeIntervalSince1970:45.0]
                                     departureDate:[NSDate dateWithTimeIntervalSince1970:55.0]
                                          latitude:25.0
                                         longitude:26.0
                                         precision:0.1];
        
        secondVisit = [AMAVisit visitWithIdentifier:@10
                                        collectDate:[NSDate dateWithTimeIntervalSince1970:165.0]
                                        arrivalDate:[NSDate dateWithTimeIntervalSince1970:145.0]
                                      departureDate:[NSDate dateWithTimeIntervalSince1970:155.0]
                                           latitude:125.0
                                          longitude:126.0
                                          precision:0.5];

        database = [AMAMockDatabase locationDatabase];
        AMALocationSerializer *serializer = [[AMALocationSerializer alloc] init];
        NSObject<AMADataEncoding> *crypter = [KWMock nullMockForProtocol:@protocol(AMADataEncoding)];
        [crypter stub:@selector(encodeData:error:) withBlock:^id(NSArray *params) {
            return params[0];
        }];
        [crypter stub:@selector(decodeData:error:) withBlock:^id(NSArray *params) {
            return params[0];
        }];
        configuration = [AMALocationCollectingConfiguration nullMock];
        [configuration stub:@selector(maxRecordsToStoreLocally) andReturn:theValue(2)];
        storage = [[AMALocationStorage alloc] initWithConfiguration:configuration
                                                         serializer:serializer
                                                           database:database
                                                            crypter:crypter];
    });

    it(@"Should add nessesary backup keys", ^{
        NSSet *__block actualKeys = nil;
        [((NSObject *)database.storageProvider) stub:@selector(addBackingKeys:) withBlock:^id(NSArray *params) {
            actualKeys = [NSSet setWithArray:params[0]];
            return nil;
        }];
        (void)[[AMALocationStorage alloc] initWithConfiguration:nil
                                                     serializer:nil
                                                       database:database
                                                        crypter:nil];
        [[actualKeys should] equal:[NSSet setWithArray:@[
            @"next.item.id",
            @"next.visit.id",
            @"next.request.id",
        ]]];
    });
    
    it(@"Should return empty locations array", ^{
        [[[storage locationsWithLimit:1] should] beEmpty];
    });

    context(@"Independent identifiers", ^{
        
        it(@"Should have separate identifiers with locations", ^{
            [storage addLocations:@[ firstLocation, secondLocation ]];
            [storage addVisit:firstVisit];
            [[[storage visitsWithLimit:10].firstObject.identifier should] beZero];
        });
        
        it(@"Should have separate identifiers with visits", ^{
            [storage addVisit:firstVisit];
            [storage addVisit:secondVisit];
            [storage addLocations:@[ firstLocation ]];
            [[[storage locationsWithLimit:10].firstObject.identifier should] beZero];
        });
    
        context(@"Existing identifier", ^{
            
            beforeEach(^{
                [storage addLocations:@[ firstLocation ]];
                [storage addVisit:firstVisit];
            });
            
            it(@"Should have separate identifiers with locations", ^{
                [storage addLocations:@[ secondLocation ]];
                [storage addVisit:secondVisit];
                [[[storage visitsWithLimit:10][1].identifier should] equal:theValue(1)];
            });
            
            it(@"Should have separate identifiers with visits", ^{
                [storage addVisit:secondVisit];
                [storage addLocations:@[ secondLocation ]];
                [[[storage locationsWithLimit:10][1].identifier should] equal:theValue(1)];
            });
            
        });
    });
         
    context(@"One visit", ^{

        beforeEach(^{
            [storage addVisit:firstVisit];
        });

        context(@"Fetch visit", ^{

            NSArray<AMAVisit *> *__block visits = nil;

            beforeEach(^{
                visits = [storage visitsWithLimit:10];
            });

            it(@"Should return one visit", ^{
                [[visits should] haveCountOf:1];
            });
            it(@"Should return visit with fixed identifier", ^{
                [[visits.firstObject.identifier should] beZero];
            });
            it(@"Should return visit with valid collect date", ^{
                [[visits.firstObject.collectDate should] equal:firstVisit.collectDate];
            });
            it(@"Should return visit with valid latitude", ^{
                double latitude = visits.firstObject.latitude;
                [[theValue(latitude) should] equal:firstVisit.latitude withDelta:EPSILON];
            });
        });
    
        context(@"Purge visit", ^{
            it(@"Should remove visit with fixed id", ^{
                [storage purgeVisitsWithIdentifiers:@[ @0 ]];
                [[[storage visitsWithLimit:10] should] beEmpty];
            });
            it(@"Should not remove visit with original id", ^{
                [storage purgeVisitsWithIdentifiers:@[ firstVisit.identifier ]];
                [[[storage visitsWithLimit:10] should] haveCountOf:1];
            });
            it(@"Should not remove visit with no id", ^{
                [storage purgeVisitsWithIdentifiers:@[]];
                [[[storage visitsWithLimit:10] should] haveCountOf:1];
            });
        });
    });
         
    context(@"Two visits", ^{

        beforeEach(^{
            [storage addVisit:firstVisit];
            [storage addVisit:secondVisit];
        });

        context(@"Fetch visits", ^{

            NSArray<AMAVisit *> *__block visits = nil;

            beforeEach(^{
                visits = [storage visitsWithLimit:10];
            });

            it(@"Should return two visits", ^{
                [[visits should] haveCountOf:2];
            });
            it(@"Should return first visit with fixed identifier", ^{
                [[visits.firstObject.identifier should] beZero];
            });
            it(@"Should return second visit with fixed identifier", ^{
                [[visits.lastObject.identifier should] equal:@1];
            });
            it(@"Should return first visit with valid collect date", ^{
                [[visits.firstObject.collectDate should] equal:firstVisit.collectDate];
            });
            it(@"Should return second visit with valid collect date", ^{
                [[visits.lastObject.collectDate should] equal:secondVisit.collectDate];
            });
            it(@"Should return visit with valid latitude", ^{
                double latitude = visits.firstObject.latitude;
                [[theValue(latitude) should] equal:firstVisit.latitude withDelta:EPSILON];
            });
            it(@"Should return visit with valid latitude", ^{
                double latitude = visits.lastObject.latitude;
                [[theValue(latitude) should] equal:secondVisit.latitude withDelta:EPSILON];
            });
            context(@"Limit", ^{
                beforeEach(^{
                    visits = [storage visitsWithLimit:1];
                });

                it(@"Should return one visit", ^{
                    [[visits should] haveCountOf:1];
                });
                it(@"Should return visit with fixed identifier", ^{
                    [[visits.firstObject.identifier should] equal:@0];
                });
            });
        });
    
        context(@"Purge visit", ^{
            it(@"Should remove visit with fixed id", ^{
                [storage purgeVisitsWithIdentifiers:@[ @0 ]];
                [[[storage visitsWithLimit:10] should] haveCountOf:1];
            });
            it(@"Should not remove visit with original id", ^{
                [storage purgeVisitsWithIdentifiers:@[ firstVisit.identifier ]];
                [[[storage visitsWithLimit:10] should] haveCountOf:2];
            });
            it(@"Should not remove visit with no id", ^{
                [storage purgeVisitsWithIdentifiers:@[]];
                [[[storage visitsWithLimit:10] should] haveCountOf:2];
            });
        });
    });
         
    context(@"One location", ^{
        beforeEach(^{
            [storage addLocations:@[ firstLocation ]];
        });

        context(@"Fetch locations", ^{
            NSArray<AMALocation *> *__block locations = nil;
            beforeEach(^{
                locations = [storage locationsWithLimit:10];
            });

            it(@"Should return one location", ^{
                [[locations should] haveCountOf:1];
            });
            it(@"Should return location with fixed identifier", ^{
                [[locations.firstObject.identifier should] equal:@0];
            });
            it(@"Should return location with valid collect date", ^{
                [[locations.firstObject.collectDate should] equal:firstLocation.collectDate];
            });
            it(@"Should return location with valid latitude", ^{
                double latitude = locations.firstObject.location.coordinate.latitude;
                [[theValue(latitude) should] equal:firstLocation.location.coordinate.latitude withDelta:EPSILON];
            });
        });
        context(@"Purge locations", ^{
            it(@"Should remove location with fixed id", ^{
                [storage purgeLocationsWithIdentifiers:@[ @0 ]];
                [[[storage locationsWithLimit:10] should] beEmpty];
            });
            it(@"Should not remove location with original id", ^{
                [storage purgeLocationsWithIdentifiers:@[ firstLocation.identifier ]];
                [[[storage locationsWithLimit:10] should] haveCountOf:1];
            });
            it(@"Should not remove location with no id", ^{
                [storage purgeLocationsWithIdentifiers:@[]];
                [[[storage locationsWithLimit:10] should] haveCountOf:1];
            });
        });
    });

    context(@"Two locations", ^{
        beforeEach(^{
            [storage addLocations:@[ firstLocation, secondLocation ]];
        });

        context(@"Fetch locations", ^{
            NSArray<AMALocation *> *__block locations = nil;
            beforeEach(^{
                locations = [storage locationsWithLimit:10];
            });

            it(@"Should return 2 locations", ^{
                [[locations should] haveCountOf:2];
            });
            it(@"Should return first location with fixed identifier", ^{
                [[locations.firstObject.identifier should] equal:@0];
            });
            it(@"Should return second location with fixed identifier", ^{
                [[locations.lastObject.identifier should] equal:@1];
            });
            context(@"Limit", ^{
                beforeEach(^{
                    locations = [storage locationsWithLimit:1];
                });

                it(@"Should return one location", ^{
                    [[locations should] haveCountOf:1];
                });
                it(@"Should return location with fixed identifier", ^{
                    [[locations.firstObject.identifier should] equal:@0];
                });
            });
        });
        context(@"Purge locations", ^{
            it(@"Should remove location with first fixed id", ^{
                [storage purgeLocationsWithIdentifiers:@[ @0 ]];
                [[[storage locationsWithLimit:10] should] haveCountOf:1];
            });
            it(@"Should remove location with second fixed id", ^{
                [storage purgeLocationsWithIdentifiers:@[ @1 ]];
                [[[storage locationsWithLimit:10] should] haveCountOf:1];
            });
            it(@"Should remove location with both ids", ^{
                [storage purgeLocationsWithIdentifiers:@[ @0, @1 ]];
                [[[storage locationsWithLimit:10] should] beEmpty];
            });
        });
    });

    context(@"State", ^{
        id<AMALSSLocationsProviding, AMALSSVisitsProviding> __block state = nil;

        context(@"Initial", ^{
            beforeAll(^{
                state = [storage locationStorageState];
            });

            it(@"Should return non-nil state", ^{
                [[(NSObject *)state should] beNonNil];
            });
            it(@"Should have no locations", ^{
                [[theValue(state.locationsCount) should] beZero];
            });
            it(@"Should have no visits", ^{
                [[theValue(state.visitsCount) should] beZero];
            });
            it(@"Should have no first location", ^{
                [[state.firstLocationDate should] beNil];
            });
            it(@"Should have zero next request identifier", ^{
                [[theValue(state.requestIdentifier) should] beZero];
            });
        });
        context(@"Existing state", ^{
            beforeEach(^{
                [database inDatabase:^(FMDatabase *db) {
                    [db executeUpdate:@"INSERT OR REPLACE INTO kv (k, v) VALUES (?, ?)"
                               values:@[ @"next.request.id", @"2" ]
                                error:NULL];
                    NSArray *values = @[
                        @"0",
                        @(firstLocation.collectDate.timeIntervalSince1970),
                        [@"FIRST_LOCATION" dataUsingEncoding:NSUTF8StringEncoding],

                        @"1",
                        @(secondLocation.collectDate.timeIntervalSince1970),
                        [@"SECOND_LOCATION" dataUsingEncoding:NSUTF8StringEncoding],
                    ];
                    [db executeUpdate:@"INSERT INTO items (id, timestamp, data) VALUES (?, ?, ?), (?, ?, ?)"
                               values:values
                                error:NULL];
                    
                    
                    [db executeUpdate:@"INSERT OR REPLACE INTO kv (k, v) VALUES (?, ?)"
                               values:@[ @"next.visit.id", @"4" ]
                                error:NULL];
                    [db executeUpdate:@"INSERT OR REPLACE INTO kv (k, v) VALUES (?, ?)"
                               values:@[ @"next.item.id", @"10" ]
                                error:NULL];
                    
                    values = @[
                        @"0",
                        @(firstLocation.collectDate.timeIntervalSince1970),
                        [@"FIRST_VISIT" dataUsingEncoding:NSUTF8StringEncoding],

                        @"1",
                        @(secondLocation.collectDate.timeIntervalSince1970),
                        [@"SECOND_VISIT" dataUsingEncoding:NSUTF8StringEncoding],
                    ];
                    [db executeUpdate:@"INSERT INTO visits (id, timestamp, data) VALUES (?, ?, ?), (?, ?, ?)"
                               values:values
                                error:NULL];
                }];
                
                state = [storage locationStorageState];
            });
            it(@"Should have 2 events", ^{
                [[theValue(state.locationsCount) should] equal:theValue(2)];
            });
            it(@"Should have 2 visits", ^{
                [[theValue(state.visitsCount) should] equal:theValue(2)];
            });
            it(@"Should have first location", ^{
                [[state.firstLocationDate should] equal:firstLocation.collectDate];
            });
            it(@"Should have next request identifier equal 2", ^{
                [[theValue(state.requestIdentifier) should] equal:theValue(2)];
            });
            it(@"Should set next visit identifier", ^{
                [storage addVisit:firstVisit];
                NSArray<AMAVisit *> *visits = [storage visitsWithLimit:10];
                [[visits.lastObject.identifier should] equal:@4];
            });
            it(@"Should set next location identifier", ^{
                [storage addLocations:@[ firstLocation ]];
                NSArray<AMALocation *> *locations = [storage locationsWithLimit:10];
                [[locations.lastObject.identifier should] equal:@10];
            });
        });
        context(@"Add location", ^{
            beforeAll(^{
                [storage addLocations:@[ firstLocation ]];
                state = [storage locationStorageState];
            });

            it(@"Should have 1 event", ^{
                [[theValue(state.locationsCount) should] equal:theValue(1)];
            });
            it(@"Should have first location", ^{
                [[state.firstLocationDate should] equal:firstLocation.collectDate];
            });
        });
        context(@"Add visit", ^{
            beforeAll(^{
                [storage addVisit:firstVisit];
                state = [storage locationStorageState];
            });

            it(@"Should have 1 visit", ^{
                [[theValue(state.visitsCount) should] equal:theValue(1)];
            });
        });
        context(@"Locations overflow", ^{
            beforeAll(^{
                [configuration stub:@selector(maxRecordsToStoreLocally) andReturn:theValue(1)];
                [storage addLocations:@[ firstLocation ]];
                [storage addLocations:@[ secondLocation ]];
                state = [storage locationStorageState];
            });

            it(@"Should have 1 event", ^{
                [[theValue(state.locationsCount) should] equal:theValue(1)];
            });
            it(@"Should have first location", ^{
                [[state.firstLocationDate should] equal:secondLocation.collectDate];
            });
        });
        context(@"Increment identifier", ^{
            it(@"Should have next request identifier equal 1", ^{
                [storage incrementRequestIdentifier];
                state = [storage locationStorageState];
                [[theValue(state.requestIdentifier) should] equal:theValue(1)];
            });
            it(@"Should have next request identifier equal 2 after next increment", ^{
                [storage incrementRequestIdentifier];
                [storage incrementRequestIdentifier];
                state = [storage locationStorageState];
                [[theValue(state.requestIdentifier) should] equal:theValue(2)];
            });
        });
        context(@"Purge locations", ^{
            beforeAll(^{
                [storage addLocations:@[ firstLocation, secondLocation ]];
                [storage purgeLocationsWithIdentifiers:@[ @0 ]];
                state = [storage locationStorageState];
            });

            it(@"Should have 1 event", ^{
                [[theValue(state.locationsCount) should] equal:theValue(1)];
            });
            it(@"Should have first location", ^{
                [[state.firstLocationDate should] equal:secondLocation.collectDate];
            });
        });
        context(@"Purge visits", ^{
            beforeAll(^{
                [storage addVisit:firstVisit];
                [storage addVisit:secondVisit];
                [storage purgeVisitsWithIdentifiers:@[ @0 ]];
                state = [storage locationStorageState];
            });

            it(@"Should have 1 visit", ^{
                [[theValue(state.visitsCount) should] equal:theValue(1)];
            });
        });
        context(@"Mixed actions", ^{
            beforeAll(^{
                [storage addLocations:@[ firstLocation ]];
                [storage incrementRequestIdentifier];
                [storage addVisit:firstVisit];
                [storage addLocations:@[ secondLocation ]];
                [storage addVisit:secondVisit];
                [storage incrementRequestIdentifier];
                [storage purgeVisitsWithIdentifiers:@[ @0 ]];
                [storage incrementRequestIdentifier];
                [storage purgeLocationsWithIdentifiers:@[ @1 ]];
                state = [storage locationStorageState];
            });

            it(@"Should have 1 event", ^{
                [[theValue(state.locationsCount) should] equal:theValue(1)];
            });
            it(@"Should have 1 visit", ^{
                [[theValue(state.visitsCount) should] equal:theValue(1)];
            });
            it(@"Should have first location", ^{
                [[state.firstLocationDate should] equal:firstLocation.collectDate];
            });
            it(@"Should have next request identifier equal 3", ^{
                [[theValue(state.requestIdentifier) should] equal:theValue(3)];
            });
        });
    });

});

SPEC_END

