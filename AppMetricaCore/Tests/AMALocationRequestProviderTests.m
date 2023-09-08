
#import <Kiwi/Kiwi.h>
#import "AMALocationRequestProvider.h"
#import "AMALocationStorage.h"
#import "AMALocationCollectingConfiguration.h"
#import "AMALocationSerializer.h"
#import "AMALocation.h"
#import "AMALocationRequest.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAVisit.h"

SPEC_BEGIN(AMALocationRequestProviderTests)

describe(@"AMALocationRequestProvider", ^{

    NSData *const rawData = [@"RAW_DATA" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *const encryptedData = [@"ENCRYPTED_DATA" dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger const limit = 108;
    unsigned long long requestIdentifier = 23;

    NSArray *__block locations = nil;
    NSArray *__block locationIdentifiers = nil;

    NSArray *__block visits = nil;
    NSArray *__block visitIdentifiers = nil;

    AMALocationRequest *__block locationRequest = nil;
    AMALocationStorage *__block storage = nil;
    AMALocationCollectingConfiguration *__block configuration = nil;
    AMALocationSerializer *__block serializer = nil;
    NSObject<AMADataEncoding> *__block encoder = nil;

    AMALocationRequestProvider *__block provider = nil;

    beforeEach(^{
        locations = @[ [AMALocation nullMock], [AMALocation nullMock] ];
        locationIdentifiers = @[ @1, @2 ];
        [locations[0] stub:@selector(identifier) andReturn:locationIdentifiers[0]];
        [locations[1] stub:@selector(identifier) andReturn:locationIdentifiers[1]];

        visits = @[ [AMAVisit nullMock], [AMAVisit nullMock] ];
        visitIdentifiers = @[ @3, @4 ];
        [visits[0] stub:@selector(identifier) andReturn:visitIdentifiers[0]];
        [visits[1] stub:@selector(identifier) andReturn:visitIdentifiers[1]];

        locationRequest = [AMALocationRequest stubbedNullMockForInit:@selector(initWithRequestIdentifier:
                                                                               locationIdentifiers:
                                                                               visitIdentifiers:
                                                                               data:)];

        storage = [AMALocationStorage nullMock];
        [storage stub:@selector(locationsWithLimit:) andReturn:locations];
        [storage stub:@selector(visitsWithLimit:) andReturn:visits];
        NSObject<AMALSSLocationsProviding> *storageState =
            [KWMock nullMockForProtocol:@protocol(AMALSSLocationsProviding)];
        [storageState stub:@selector(requestIdentifier) andReturn:theValue(requestIdentifier)];
        [storage stub:@selector(locationStorageState) andReturn:storageState];
        configuration = [AMALocationCollectingConfiguration nullMock];
        [configuration stub:@selector(maxRecordsCountInBatch) andReturn:theValue(limit)];
        serializer = [AMALocationSerializer nullMock];
        [serializer stub:@selector(dataForLocations:visits:) andReturn:rawData];
        encoder = [KWMock nullMockForProtocol:@protocol(AMADataEncoding)];
        [encoder stub:@selector(encodeData:error:) andReturn:encryptedData];
        provider = [[AMALocationRequestProvider alloc] initWithStorage:storage
                                                         configuration:configuration
                                                            serializer:serializer
                                                               encoder:encoder];
    });

    it(@"Should request locations", ^{
        [[storage should] receive:@selector(locationsWithLimit:) withArguments:theValue(limit)];
        [provider nextLocationsRequest];
    });

    it(@"Should request visits", ^{
        [[storage should] receive:@selector(visitsWithLimit:) withArguments:theValue(limit)];
        [provider nextVisitsRequest];
    });

    it(@"Should request visits if there is space left in locations request batch", ^{
        const NSUInteger expectedVists = 1;
        const NSUInteger localLimit = locations.count + expectedVists;
        [configuration stub:@selector(maxRecordsCountInBatch) andReturn:theValue(localLimit)];
        [[storage should] receive:@selector(visitsWithLimit:) withArguments:theValue(expectedVists)];
        [provider nextLocationsRequest];
    });

    it(@"Should not request visits if there is no space left in locations request batch", ^{
        [configuration stub:@selector(maxRecordsCountInBatch) andReturn:theValue(locations.count)];
        [[storage shouldNot] receive:@selector(visitsWithLimit:)];
        [provider nextLocationsRequest];
    });

    it(@"Should not request locations in visits request", ^{
        [[storage shouldNot] receive:@selector(locationsWithLimit:)];
        [provider nextVisitsRequest];
    });

    it(@"Should serialize locations", ^{
        [[serializer should] receive:@selector(dataForLocations:visits:) withArguments:locations, kw_any()];
        [provider nextLocationsRequest];
    });

    it(@"Should serialize visits in location request if there is space left", ^{
        [[serializer should] receive:@selector(dataForLocations:visits:) withArguments:locations, visits];
        [provider nextLocationsRequest];
    });

    it(@"Should not serialize visits in location request if there is no space left", ^{
        [configuration stub:@selector(maxRecordsCountInBatch) andReturn:theValue(locations.count)];
        [[serializer should] receive:@selector(dataForLocations:visits:) withArguments:locations, [KWNull null]];
        [provider nextLocationsRequest];
    });

    it(@"Should serialize visits", ^{
        [[serializer should] receive:@selector(dataForLocations:visits:) withArguments:[KWNull null], visits];
        [provider nextVisitsRequest];
    });

    it(@"Should encrypt data in location request", ^{
        [[encoder should] receive:@selector(encodeData:error:) withArguments:rawData, kw_any()];
        [provider nextLocationsRequest];
    });
         
    it(@"Should encrypt data in visit request", ^{
        [[encoder should] receive:@selector(encodeData:error:) withArguments:rawData, kw_any()];
        [provider nextVisitsRequest];
    });
    
    it(@"Should create valid location request with visits identifiers if there is space left", ^{
        [[locationRequest should] receive:@selector(initWithRequestIdentifier:
                                                    locationIdentifiers:
                                                    visitIdentifiers:
                                                    data:)
                            withArguments:@(requestIdentifier), locationIdentifiers, visitIdentifiers, encryptedData];
        [provider nextLocationsRequest];
    });
         
    it(@"Should create valid location request with no visits identifiers if there is no space left", ^{
        [configuration stub:@selector(maxRecordsCountInBatch) andReturn:theValue(locations.count)];
        [[locationRequest should] receive:@selector(initWithRequestIdentifier:
                                                    locationIdentifiers:
                                                    visitIdentifiers:
                                                    data:)
                            withArguments:@(requestIdentifier), locationIdentifiers, @[], encryptedData];
        [provider nextLocationsRequest];
    });
         
    it(@"Should create valid visit request", ^{
        [[locationRequest should] receive:@selector(initWithRequestIdentifier:
                                                    locationIdentifiers:
                                                    visitIdentifiers:
                                                    data:)
                            withArguments:@(requestIdentifier), @[], visitIdentifiers, encryptedData];
        [provider nextVisitsRequest];
    });

    it(@"Should return valid request", ^{
        [[[provider nextLocationsRequest] should] equal:locationRequest];
    });

    context(@"Invalid location", ^{
        beforeEach(^{
            [locations[0] stub:@selector(identifier) andReturn:nil];
        });
        it(@"Should create request with only second identifier", ^{
            [[locationRequest should] receive:@selector(initWithRequestIdentifier:
                                                        locationIdentifiers:
                                                        visitIdentifiers:
                                                        data:)
                                withArguments:kw_any(), @[ locationIdentifiers[1] ], kw_any(), kw_any()];
            [provider nextLocationsRequest];
        });
    });
         
    context(@"Invalid visit", ^{
        beforeEach(^{
            [visits[0] stub:@selector(identifier) andReturn:nil];
        });
        it(@"Should create request with only second identifier", ^{
            [[locationRequest should] receive:@selector(initWithRequestIdentifier:
                                                        locationIdentifiers:
                                                        visitIdentifiers:
                                                        data:)
                                withArguments:kw_any(), kw_any(), @[ visitIdentifiers[1] ], kw_any()];
            [provider nextVisitsRequest];
        });
        it(@"Should create request with only second identifier in location request", ^{
            [[locationRequest should] receive:@selector(initWithRequestIdentifier:
                                                        locationIdentifiers:
                                                        visitIdentifiers:
                                                        data:)
                                withArguments:kw_any(), kw_any(), @[ visitIdentifiers[1] ], kw_any()];
            [provider nextLocationsRequest];
        });
    });

});

SPEC_END

