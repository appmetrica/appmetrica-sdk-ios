
#import "AMACrashLogging.h"
#import "AMAKSCrash.h"
#import "AMAKSCrashImports.h"
#import <objc/runtime.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>

static NSString *const kAMAAppMetricaCrashReportsDirectoryNamePostfix = @".CrashReports";

@implementation AMAKSCrash

+ (KSCrash *)sharedInstance
{
    static KSCrash *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Crash reports path: $APP_HOME/Library/Caches/io.appmetrica.CrashReports/
        instance = [[KSCrash alloc] initWithBasePath:[self crashesPath]];
        instance.introspectMemory = NO; // hot fix on arm64
        instance.demangleLanguages = KSCrashDemangleLanguageCPlusPlus;
        instance.searchQueueNames = NO;

        // Prevent KSCrash calling its own shared instance
        [self swizzleOriginalSharedInstance];
    });
    return instance;
}

+ (void)swizzleOriginalSharedInstance
{
    SEL selector = @selector(sharedInstance);
    Method oldMethod = class_getClassMethod([KSCrash class], selector);
    Method newMethod = class_getClassMethod([self class], selector);
    IMP newMethodImplementation = method_getImplementation(newMethod);

    method_setImplementation(oldMethod, newMethodImplementation);
}

+ (NSString *)crashesPath
{
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [cachePaths firstObject];
    NSString *bundleName = [AMAPlatformDescription SDKBundleName];
    NSString *directoryName = [bundleName stringByAppendingString:kAMAAppMetricaCrashReportsDirectoryNamePostfix];
    return [cachePath stringByAppendingPathComponent:directoryName];
}

@end
