#import "AMAActivationTypeResolver.h"
#import "AMADefaultAnonymousConfigProvider.h"
#import "AMAAppMetricaConfiguration.h"

@implementation AMAActivationTypeResolver

+ (BOOL)isAnonymousConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    NSString *anonymousApiKey = AMADefaultAnonymousConfigProvider.anonymousAPIKey;
    return [configuration.APIKey isEqualToString:anonymousApiKey];
}

@end
