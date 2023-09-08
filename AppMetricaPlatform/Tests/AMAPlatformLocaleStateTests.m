
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>

SPEC_BEGIN(AMAPlatformLocaleStateTests)

describe(@"AMAPlatformLocaleState", ^{

    __block AMALocaleMock *localeMock = nil;
    NSString *languageCode = @"zh";
    NSString *languageSubgroupCode = @"HK";
    NSString *languageAsReturnedByPrefferedLanguages = [NSString stringWithFormat:@"%@-%@",
                                                        languageCode,
                                                        languageSubgroupCode];

    beforeEach(^{
        localeMock = [[AMALocaleMock alloc] initWithLanguageCode:languageCode];
        
        [NSLocale stub:@selector(currentLocale) andReturn:localeMock];
        [NSLocale stub:@selector(preferredLanguages) andReturn:@[languageAsReturnedByPrefferedLanguages]];
    });

    it(@"Should return lng-script_region pattern", ^{
        NSString *expectedValue = [NSString stringWithFormat:@"%@-%@_%@",
                                   localeMock.languageCode,
                                   localeMock.scriptCode,
                                   localeMock.countryCode];
        NSString *actualValue = [AMAPlatformLocaleState fullLocaleIdentifier];

        [[actualValue should] equal:expectedValue];
    });

    it(@"Should return lng_region pattern", ^{
        localeMock.scriptCode = nil;

        NSString *expectedValue =
            [NSString stringWithFormat:@"%@_%@", localeMock.languageCode, localeMock.countryCode];
        NSString *actualValue = [AMAPlatformLocaleState fullLocaleIdentifier];

        [[actualValue should] equal:expectedValue];
    });

    it(@"Should return lng-script pattern", ^{
        localeMock.countryCode = nil;

        NSString *expectedValue =
            [NSString stringWithFormat:@"%@-%@",localeMock.languageCode, localeMock.scriptCode];
        NSString *actualValue = [AMAPlatformLocaleState fullLocaleIdentifier];

        [[actualValue should] equal:expectedValue];
    });

    it(@"Should return lng pattern", ^{
        localeMock.scriptCode = nil;
        localeMock.countryCode = nil;

        NSString *expectedValue = localeMock.languageCode;
        NSString *actualValue = [AMAPlatformLocaleState fullLocaleIdentifier];

        [[actualValue should] equal:expectedValue];
    });
});

SPEC_END

