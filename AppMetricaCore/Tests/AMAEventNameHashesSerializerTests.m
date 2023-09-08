
#import <Kiwi/Kiwi.h>
#import "AMAEventNameHashesSerializer.h"
#import "AMAEventNameHashesCollection.h"

SPEC_BEGIN(AMAEventNameHashesSerializerTests)

describe(@"AMAEventNameHashesSerializer", ^{

    NSData *const expectedData = [[NSData alloc] initWithBase64EncodedString:@"CgdWRVJTSU9OEBcYASAqICA=" options:0];

    AMAEventNameHashesSerializer *__block serializer = nil;

    beforeEach(^{
        serializer = [[AMAEventNameHashesSerializer alloc] init];
    });

    it(@"Should serialize", ^{
        AMAEventNameHashesCollection *collection =
            [[AMAEventNameHashesCollection alloc] initWithCurrentVersion:@"VERSION"
                                           hashesCountFromCurrentVersion:23
                                                handleNewEventsAsUnknown:YES
                                                         eventNameHashes:[NSMutableSet setWithArray:@[ @32, @42 ]]];

        NSData *data = [serializer dataForCollection:collection];
        [[data should] equal:expectedData];
    });

    context(@"Deserialize", ^{
        AMAEventNameHashesCollection *__block collection = nil;
        beforeAll(^{
            collection = [serializer collectionForData:expectedData];
        });
        it(@"Should have valid version", ^{
            [[collection.currentVersion should] equal:@"VERSION"];
        });
        it(@"Should have valid hashes", ^{
            [[collection.eventNameHashes should] equal:[NSMutableSet setWithArray:@[ @32, @42 ]]];
        });
        it(@"Should have valid hashes count", ^{
            [[theValue(collection.hashesCountFromCurrentVersion) should] equal:theValue(23)];
        });
        it(@"Should have handleNewEventsAsUnknown", ^{
            [[theValue(collection.handleNewEventsAsUnknown) should] beYes];
        });
    });

});

SPEC_END
