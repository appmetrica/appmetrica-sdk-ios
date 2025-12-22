
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAFirstPartyDataEmailSha256Attribute.h"
#import "AMAEmailNormalizer.h"
#import "AMAStringAttributeTruncationProvider.h"
#import "AMACompositeUserProfileUpdateProviding.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAFirstPartyDataEmailSha256AttributeTests)

describe(@"AMAFirstPartyDataEmailSha256Attribute", ^{

    NSObject<AMACompositeUserProfileUpdateProviding> *__block userProfileUpdateProvider = nil;
    AMAStringAttributeTruncationProvider *__block truncationProvider = nil;
    AMAFirstPartyDataEmailSha256Attribute *__block attribute = nil;

    beforeEach(^{
        userProfileUpdateProvider = [KWMock nullMockForProtocol:@protocol(AMACompositeUserProfileUpdateProviding)];
        truncationProvider = [AMAStringAttributeTruncationProvider nullMock];

        attribute = [[AMAFirstPartyDataEmailSha256Attribute alloc] initWithUserProfileUpdateProvider:userProfileUpdateProvider
                                                                                   truncationProvider:truncationProvider];
    });

    it(@"Should have correct attribute prefix", ^{
        [[[attribute attributePrefix] should] equal:@"appmetrica_1pd_email_sha256_"];
    });

    it(@"Should have correct max count", ^{
        [[theValue([attribute maxCount]) should] equal:theValue(10)];
    });

    it(@"Should have email normalizer", ^{
        [[(NSObject *)attribute.normalizer should] beKindOfClass:[AMAEmailNormalizer class]];
    });

});

SPEC_END
