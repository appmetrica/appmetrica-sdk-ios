
#import "AMAIronSourceModuleEntryPoint.h"
#import "AMAIronSourceAdRevenuePolicy.h"
#import "AMAIronSourceManager.h"
#import "AMAIronSourceLog.h"
#import <objc/message.h>

typedef NSString *(*AMAIronSourceSDKVersionIMP)(Class, SEL);

@interface AMAIronSourceModuleEntryPoint ()
@property (nonatomic, strong) AMAInfoPlistPolicy *policy;
@end

@implementation AMAIronSourceModuleEntryPoint

- (instancetype)init
{
    return [self initWithPolicy:[AMAIronSourceAdRevenuePolicy sharedInstance]];
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
        AMAIronSourceLog(@"autocollection disabled via Info.plist, skipping");
        return;
    }

    NSString *versionString = [self sdkVersionString];
    NSInteger major = [self majorVersionFromString:versionString];

    if (major < 8) {
        AMAIronSourceLog(@"SDK not found or version < 8 (version='%@'), skipping", versionString ?: @"nil");
        return;
    }

    AMAIronSourceLog(@"IronSource SDK v%ld detected, registering", (long)major);
    [AMAAppMetrica registerAdRevenueNativeSource:@"ironsource"];

    [[AMAIronSourceManager sharedInstance] setupWithMajorVersion:major];
    [context addActivationDelegate:[AMAIronSourceManager class]];
}

// MARK: - Private

- (nullable NSString *)sdkVersionString
{
    SEL sdkVersionSel = NSSelectorFromString(@"sdkVersion");

    Class ironSource = NSClassFromString(@"IronSource");
    if ([ironSource respondsToSelector:sdkVersionSel]) {
        return ((AMAIronSourceSDKVersionIMP)objc_msgSend)(ironSource, sdkVersionSel);
    }

    Class levelPlay = NSClassFromString(@"LevelPlay");
    if ([levelPlay respondsToSelector:sdkVersionSel]) {
        return ((AMAIronSourceSDKVersionIMP)objc_msgSend)(levelPlay, sdkVersionSel);
    }

    return nil;
}

- (NSInteger)majorVersionFromString:(nullable NSString *)version
{
    if (version.length == 0) {
        return -1;
    }
    NSArray<NSString *> *parts = [version componentsSeparatedByString:@"."];
    NSString *majorStr = parts.firstObject;
    if (majorStr.length == 0) {
        return -1;
    }
    NSInteger major = [majorStr integerValue];
    if (major == 0 && [majorStr isEqualToString:@"0"] == NO) {
        return -1;
    }
    return major;
}

@end
