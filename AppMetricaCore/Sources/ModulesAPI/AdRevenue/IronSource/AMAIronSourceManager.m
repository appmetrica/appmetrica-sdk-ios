
#import "AMAIronSourceManager.h"
#import "AMAIronSourceImpressionDelegate.h"
#import "AMAIronSourceLog.h"
#import <objc/message.h>

typedef void (*AMAIronSourceRegisterDelegateIMP)(Class, SEL, id);

@interface AMAIronSourceManager ()
@property (nonatomic, strong) AMAIronSourceImpressionDelegate *impressionDelegate;
@end

@implementation AMAIronSourceManager

+ (instancetype)sharedInstance
{
    static AMAIronSourceManager *instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)setupWithMajorVersion:(NSInteger)majorVersion
{
    self.impressionDelegate = [[AMAIronSourceImpressionDelegate alloc] initWithMajorVersion:majorVersion];

    if (majorVersion == 8) {
        [self registerV8];
    } else {
        [self registerV9];
    }
}

// MARK: - AMAModuleActivationDelegate

+ (void)willActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration
{
}

+ (void)didActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration
{
    [[self sharedInstance].impressionDelegate processQueuedImpressionData];
}

// MARK: - Private

- (void)registerV8
{
    Class ironSource = NSClassFromString(@"IronSource");
    SEL addSel = NSSelectorFromString(@"addImpressionDataDelegate:");
    if ([ironSource respondsToSelector:addSel]) {
        ((AMAIronSourceRegisterDelegateIMP)objc_msgSend)(ironSource, addSel, self.impressionDelegate);
        AMAIronSourceLog(@"v8: registered as ISImpressionDataDelegate");
    } else {
        AMAIronSourceLog(@"v8: IronSource does not respond to +addImpressionDataDelegate:");
    }
}

- (void)registerV9
{
    Class levelPlay = NSClassFromString(@"LevelPlay");
    SEL addSel = NSSelectorFromString(@"addImpressionDataDelegate:");
    if ([levelPlay respondsToSelector:addSel]) {
        ((AMAIronSourceRegisterDelegateIMP)objc_msgSend)(levelPlay, addSel, self.impressionDelegate);
        AMAIronSourceLog(@"v9: registered as LPMImpressionDataDelegate");
    } else {
        AMAIronSourceLog(@"v9: LevelPlay does not respond to +addImpressionDataDelegate:");
    }
}

@end
