
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAFirstPartyDataTelegramLoginSha256Attribute.h"
#import "AMATelegramLoginNormalizer.h"
#import "AMAStringAttributeTruncationProvider.h"
#import "AMACompositeUserProfileUpdateProviding.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAFirstPartyDataTelegramLoginSha256AttributeTests)

describe(@"AMAFirstPartyDataTelegramLoginSha256Attribute", ^{

    NSObject<AMACompositeUserProfileUpdateProviding> *__block userProfileUpdateProvider = nil;
    AMAStringAttributeTruncationProvider *__block truncationProvider = nil;
    AMAFirstPartyDataTelegramLoginSha256Attribute *__block attribute = nil;

    beforeEach(^{
        userProfileUpdateProvider = [KWMock nullMockForProtocol:@protocol(AMACompositeUserProfileUpdateProviding)];
        truncationProvider = [AMAStringAttributeTruncationProvider nullMock];

        attribute = [[AMAFirstPartyDataTelegramLoginSha256Attribute alloc] initWithUserProfileUpdateProvider:userProfileUpdateProvider
                                                                                          truncationProvider:truncationProvider];
    });

    it(@"Should have correct attribute prefix", ^{
        [[[attribute attributePrefix] should] equal:@"appmetrica_1pd_telegram_sha256_"];
    });

    it(@"Should have correct max count", ^{
        [[theValue([attribute maxCount]) should] equal:theValue(10)];
    });

    it(@"Should have telegram login normalizer", ^{
        [[(NSObject *)attribute.normalizer should] beKindOfClass:[AMATelegramLoginNormalizer class]];
    });

});

SPEC_END
