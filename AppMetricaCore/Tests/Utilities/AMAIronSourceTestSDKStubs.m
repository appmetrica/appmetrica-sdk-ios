
#import "AMAIronSourceTestSDKStubs.h"

NSString *gIronSourceSDKVersion = nil;
NSString *gLevelPlaySDKVersion = nil;
NSMutableArray *gIronSourceRegisteredDelegates = nil;
NSMutableArray *gLevelPlayRegisteredDelegates = nil;

void AMAIronSourceTestSDKStubsReset(void) {
    gIronSourceSDKVersion = nil;
    gLevelPlaySDKVersion = nil;
    gIronSourceRegisteredDelegates = [NSMutableArray array];
    gLevelPlayRegisteredDelegates = [NSMutableArray array];
}

// Fake IronSource SDK class — found by NSClassFromString(@"IronSource").
// Conditionally responds to SDK methods based on gIronSourceSDKVersion,
// so tests that only set gLevelPlaySDKVersion skip IronSource entirely.
@interface IronSource : NSObject
@end
@implementation IronSource
+ (BOOL)respondsToSelector:(SEL)selector
{
    if (selector == NSSelectorFromString(@"sdkVersion")) {
        return gIronSourceSDKVersion != nil;
    }
    return [super respondsToSelector:selector];
}
+ (NSString *)sdkVersion { return gIronSourceSDKVersion; }
+ (void)addImpressionDataDelegate:(id)delegate { [gIronSourceRegisteredDelegates addObject:delegate]; }
@end

// Fake LevelPlay SDK class — found by NSClassFromString(@"LevelPlay").
// Conditionally responds to SDK methods based on gLevelPlaySDKVersion.
@interface LevelPlay : NSObject
@end
@implementation LevelPlay
+ (BOOL)respondsToSelector:(SEL)selector
{
    if (selector == NSSelectorFromString(@"sdkVersion")) {
        return gLevelPlaySDKVersion != nil;
    }
    return [super respondsToSelector:selector];
}
+ (NSString *)sdkVersion { return gLevelPlaySDKVersion; }
+ (void)addImpressionDataDelegate:(id)delegate { [gLevelPlayRegisteredDelegates addObject:delegate]; }
@end
