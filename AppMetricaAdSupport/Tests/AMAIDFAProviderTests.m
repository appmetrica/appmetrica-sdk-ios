
#import <Kiwi/Kiwi.h>
#import <AdSupport/AdSupport.h>
#import "AMAIDFAProvider.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAIDFAProviderTests)

describe(@"AMAIDFAProvider", ^{
    
    let(idfaProvider, ^id{
        return [[AMAIDFAProvider alloc] init];
    });

    it(@"Should return idfa", ^{
        NSUUID *uuid = [NSUUID nullMock];
        ASIdentifierManager *manager = [ASIdentifierManager stubbedNullMockForDefaultInit];
        [manager stub:@selector(advertisingIdentifier) andReturn:uuid];

        [[[idfaProvider advertisingIdentifier] should] equal:uuid];
    });
});

SPEC_END
