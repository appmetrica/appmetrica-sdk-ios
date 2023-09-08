
#import "AMABundleProviderMocks.h"

@implementation LSApplicationWorkspaceMock

+ (instancetype)defaultWorkspace
{
    return nil;
}

- (instancetype)initWithAllInstalledApplications:(NSArray *)allInstalledApplications
                                installedPlugins:(NSArray *)installedPlugins
{
    self = [super init];
    if (self != nil) {
        _allInstalledApplications = [allInstalledApplications copy];
        _installedPlugins = [installedPlugins copy];
    }
    return self;
}

@end

@implementation LSApplicationBundleMock

- (instancetype)initWithApplicationIdentifier:(NSString *)applicationIdentifier
                                   bundleType:(NSString *)bundleType
                               registeredDate:(NSDate *)registeredDate
{
    self = [super init];
    if (self != nil) {
        _applicationIdentifier = [applicationIdentifier copy];
        _bundleType = [bundleType copy];
        _registeredDate = registeredDate;
    }
    return self;
}

@end

@implementation LSPluginKitBundleMock

- (instancetype)initWithContainingBundle:(LSApplicationBundleMock *)containingBundle
{
    self = [super init];
    if (self != nil) {
        _containingBundle = containingBundle;
    }
    return self;
}

@end

@implementation MCMAppDataContainerMock

+ (instancetype)containerWithIdentifier:(NSString *)identifier error:(NSError *)error
{
    return nil;
}

@end
