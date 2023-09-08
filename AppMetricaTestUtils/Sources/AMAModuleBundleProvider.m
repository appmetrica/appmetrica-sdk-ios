
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

static NSString *const kAMABundleName = @"AppMetrica_AppMetricaCoreTests";

@implementation AMAModuleBundleProvider

+ (NSBundle *)moduleBundle
{
    return [[self class] moduleBundleForResource:kAMABundleName];
}

+ (NSBundle *)moduleBundleForResource:(NSString *)resource
{
    NSBundle *moduleBundle = [NSBundle bundleForClass:[self class]];
#ifdef SWIFT_PACKAGE
    NSBundle *testTargetBundle = [NSBundle bundleWithURL:[moduleBundle URLForResource:resource
                                                                        withExtension:@".bundle"
                                                                         subdirectory:nil]];
    if (testTargetBundle == nil) {
        @throw [NSException exceptionWithName:@"NoModuleBundle"
                                       reason:@"Can't locate test target module"
                                     userInfo:@{ NSURLErrorKey : testTargetBundle }];
    }
    return testTargetBundle;
#else
    return moduleBundle;
#endif
}

@end
