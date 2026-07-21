
#import "AMAAppLovinMaxModuleEntryPoint.h"
#import "AMAAppLovinAdRevenuePolicy.h"
#import "AMAAppLovinManager.h"
#import "AMAAppLovinLog.h"
#import <objc/message.h>

typedef NSString *(*AMAAppLovinVersionIMP)(Class, SEL);

@interface AMAAppLovinMaxModuleEntryPoint ()
@property (nonatomic, strong) AMAInfoPlistPolicy *policy;
@property (nonatomic) BOOL prepared;
@end

@implementation AMAAppLovinMaxModuleEntryPoint

- (instancetype)init
{
    return [self initWithPolicy:[AMAAppLovinAdRevenuePolicy sharedInstance]];
}

- (instancetype)initWithPolicy:(AMAInfoPlistPolicy *)policy
{
    self = [super init];
    if (self) {
        _policy = policy;
    }
    return self;
}

- (void)registerComponentsWithRegistrar:(id<AMAModuleRegistrar>)registrar
{
    if (self.policy.isEnabled == NO) {
        AMAAppLovinLog(@"autocollection disabled via Info.plist, skipping");
        return;
    }

    Class alcClass = NSClassFromString(@"ALCCommunicator");
    if (alcClass == nil || [alcClass respondsToSelector:NSSelectorFromString(@"defaultCommunicator")] == NO) {
        AMAAppLovinLog(@"ALCCommunicator not found, skipping");
        return;
    }

    NSString *sdkVersion = [self sdkVersion];
    AMAAppLovinLog(@"AppLovin MAX detected (version=%@), registering", sdkVersion ?: @"unknown");

    [self registerNativeSource];
    AMAAppLovinManager *manager = [AMAAppLovinManager sharedInstance];
    AMAServiceConfiguration *config = [[AMAServiceConfiguration alloc]
        initWithStartupObserver:manager
       reporterStorageController:nil];
    [registrar registerPreActivationHandler:self];
    [registrar registerServiceConfiguration:config];
    [registrar registerActivationDelegate:[AMAAppLovinManager class]];
}

- (void)handlePreActivationWithConfiguration:(AMAModuleActivationConfiguration *)configuration
{
    if (self.prepared) {
        return;
    }
    self.prepared = YES;
    [self setupManager];
}

// MARK: - Private

- (void)registerNativeSource
{
    [AMAAppMetrica registerAdRevenueNativeSource:@"applovin"];
}

- (void)setupManager
{
    [[AMAAppLovinManager sharedInstance] setup];
}

- (nullable NSString *)sdkVersion
{
    Class alkSdk = NSClassFromString(@"ALSdk");
    SEL versionSel = NSSelectorFromString(@"version");
    if ([alkSdk respondsToSelector:versionSel]) {
        return ((AMAAppLovinVersionIMP)objc_msgSend)(alkSdk, versionSel);
    }
    return nil;
}

@end
