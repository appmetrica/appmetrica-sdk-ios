
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAStringAttributeTruncationProvider.h"
#import "AMAStringAttributeTruncator.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAStringAttributeTruncationProviderTests)

describe(@"AMAStringAttributeTruncationProvider", ^{

    NSString *const name = @"ATTRIBUTE_NAME";

    NSObject<AMAStringTruncating> *__block underlyingTruncator = nil;
    AMAStringAttributeTruncator *__block truncator = nil;
    AMAStringAttributeTruncationProvider *__block provider = nil;

    beforeEach(^{
        underlyingTruncator = [KWMock nullMockForProtocol:@protocol(AMAStringTruncating)];
        truncator =
            [AMAStringAttributeTruncator stubbedNullMockForInit:@selector(initWithAttributeName:underlyingTruncator:)];
        provider = [[AMAStringAttributeTruncationProvider alloc] initWithUnderlyingTruncator:underlyingTruncator];
    });
    it(@"Should create valid truncator", ^{
        [[truncator should] receive:@selector(initWithAttributeName:underlyingTruncator:)
                      withArguments:name, underlyingTruncator];
        [provider truncatorWithAttributeName:name];
    });
    it(@"Should return created truncator", ^{
        [[(NSObject *)[provider truncatorWithAttributeName:name] should] equal:truncator];
    });

});

SPEC_END
