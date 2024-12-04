
#import "AMABundleInfoProviderMock.h"

@implementation AMABundleInfoProviderMock

- (instancetype)initWithAppID:(NSString*)appID
               appBuildNumber:(NSString*)appBuildNumber
                   appVersion:(NSString*)appVersion
               appVersionName:(NSString*)appVersionName
{
    self = [super init];
    if (self) {
        self.appID = [appID copy];
        self.appBuildNumber = [appBuildNumber copy];
        self.appVersion = [appVersion copy];
        self.appVersionName = [appVersionName copy];
    }
    return self;
}

- (instancetype)initWithAppID:(NSString*)appID
      copyOtherPropertiesFrom:(id<AMABundleInfoProvider>)otherProp
{
    return [self initWithAppID:appID
                appBuildNumber:otherProp.appBuildNumber
                    appVersion:otherProp.appVersion
                appVersionName:otherProp.appVersionName];
}

@end
