#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@implementation AMAModuleBundleProvider

+ (NSBundle *)moduleBundle
{
    NSBundle *moduleBundle = [NSBundle bundleForClass:[self class]];
#ifdef SWIFT_PACKAGE
    // Extract the name of the test executable or framework.
    NSString *xctestName = [[moduleBundle bundlePath] lastPathComponent];
    NSString *baseName = [xctestName stringByDeletingPathExtension];
    
    // Search for the bundle corresponding to this test executable in SPM.
    NSArray *allURLs = [moduleBundle URLsForResourcesWithExtension:@".bundle" subdirectory:nil];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastPathComponent ENDSWITH %@",
                                [NSString stringWithFormat:@"_%@.bundle", baseName]];
    NSURL *bundleURL = [[allURLs filteredArrayUsingPredicate:predicate] firstObject];

    if (bundleURL == nil) {
        @throw [NSException exceptionWithName:@"NoModuleBundle"
                                       reason:@"Can't locate test target module"
                                     userInfo:@{@"FailedURL": bundleURL ?: [NSNull null],
                                                @"ExecutableName": xctestName ?: [NSNull null],
                                                @"AllSearchedURLs": allURLs ?: [NSNull null],
                                                @"FilterPredicate": predicate ?: [NSNull null]}];
    }
    
    return [NSBundle bundleWithURL:bundleURL];
#else
    // In a non-SPM environment, assume the module bundle is the same as the test executable.
    return moduleBundle;
#endif
}

@end
