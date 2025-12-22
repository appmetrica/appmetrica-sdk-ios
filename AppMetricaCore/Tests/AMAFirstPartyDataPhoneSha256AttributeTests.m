
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAFirstPartyDataPhoneSha256Attribute.h"
#import "AMAPhoneNormalizer.h"
#import "AMAStringAttributeTruncationProvider.h"
#import "AMACompositeUserProfileUpdateProviding.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAFirstPartyDataPhoneSha256AttributeTests)

describe(@"AMAFirstPartyDataPhoneSha256Attribute", ^{

    NSObject<AMACompositeUserProfileUpdateProviding> *__block userProfileUpdateProvider = nil;
    AMAStringAttributeTruncationProvider *__block truncationProvider = nil;
    AMAFirstPartyDataPhoneSha256Attribute *__block attribute = nil;

    beforeEach(^{
        userProfileUpdateProvider = [KWMock nullMockForProtocol:@protocol(AMACompositeUserProfileUpdateProviding)];
        truncationProvider = [AMAStringAttributeTruncationProvider nullMock];

        attribute = [[AMAFirstPartyDataPhoneSha256Attribute alloc] initWithUserProfileUpdateProvider:userProfileUpdateProvider
                                                                                   truncationProvider:truncationProvider];
    });

    it(@"Should have correct attribute prefix", ^{
        [[[attribute attributePrefix] should] equal:@"appmetrica_1pd_phone_sha256_"];
    });

    it(@"Should have correct max count", ^{
        [[theValue([attribute maxCount]) should] equal:theValue(10)];
    });

    it(@"Should have phone normalizer", ^{
        [[(NSObject *)attribute.normalizer should] beKindOfClass:[AMAPhoneNormalizer class]];
    });

});

SPEC_END
