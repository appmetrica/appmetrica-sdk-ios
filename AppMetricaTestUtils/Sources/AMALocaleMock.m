
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@implementation AMALocaleMock

- (instancetype)initWithLanguageCode:(NSString *)languageCode
{
    self = [super init];
    if (self != nil) {
        _scriptCode = @"Hant";
        _countryCode = @"BY";
        _languageCode = languageCode;
    }

    return self;
}

- (nullable id)objectForKey:(id)key
{
    id result = nil;

    if ([key isEqualToString:NSLocaleCountryCode]) {
        result = self.countryCode;
    }

    else if ([key isEqualToString:NSLocaleScriptCode]) {
        result = self.scriptCode;
    }

    return result;
}

@end
