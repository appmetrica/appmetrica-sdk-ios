
#import "AMAAppLovinMaxModuleEntryPoint.h"
#import "AMAAppLovinAdRevenuePolicy.h"
#import "AMAAppLovinManager.h"
#import "AMAAppLovinLog.h"
#import <objc/message.h>

typedef NSString *(*AMAAppLovinVersionIMP)(Class, SEL);

@interface AMAAppLovinMaxModuleEntryPoint ()
@property (nonatomic, strong) AMAInfoPlistPolicy *policy;
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

- (void)initModuleWithContext:(id<AMAModuleContext>)context
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
    [AMAAppMetrica registerAdRevenueNativeSource:@"applovin"];

    AMAAppLovinManager *manager = [AMAAppLovinManager sharedInstance];
    [manager setup];
    AMAServiceConfiguration *config = [[AMAServiceConfiguration alloc]
        initWithStartupObserver:manager
       reporterStorageController:nil];
    [context registerExternalService:config];
    [context addActivationDelegate:[AMAAppLovinManager class]];
}

// MARK: - Private

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
