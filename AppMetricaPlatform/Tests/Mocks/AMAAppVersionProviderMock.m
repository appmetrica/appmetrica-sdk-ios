
#import "AMAAppVersionProviderMock.h"

@implementation AMAAppVersionProviderMock

- (NSString *)appID
{
    return @"appID";
}

- (NSString *)appBuildNumber
{
    return @"appBuildNumber";
}

- (NSString *)appVersion
{
    return @"appVersion";
}

- (NSString *)appVersionName
{
    return @"appVersionName";
}

@end
