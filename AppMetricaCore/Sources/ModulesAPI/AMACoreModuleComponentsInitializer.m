
#import "AMACoreModuleComponentsInitializer.h"
#import "AMAModulesController.h"
#import "AMACore.h"

@implementation AMACoreModuleComponentsInitializer

static NSArray<NSString *> *knownEntryPointClassNames(void) {
    return @[
        @"AMAAdSupportModuleEntryPoint",
        @"AMAAppMetricaCrashesEntryPoint",
        @"AMAIDSyncModuleEntryPoint",
        @"AMAScreenshotModuleEntryPoint",
        @"AMAIronSourceModuleEntryPoint",
    ];
}

+ (NSArray<NSString *> *)allEntryPointClassNames
{
    NSMutableArray<NSString *> *names = [knownEntryPointClassNames() mutableCopy];
    Class provider = NSClassFromString(@"AMAInternalEntryPointProvider");
    SEL selector = NSSelectorFromString(@"entryPointClassNames");
    if ([provider respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [names addObjectsFromArray:[provider performSelector:selector]];
#pragma clang diagnostic pop
    }
    return names;
}

+ (void)discoverAndRegisterInController:(AMAModulesController *)controller
                            classLookup:(nullable Class (^)(NSString *))classLookup
{
    for (NSString *className in [self allEntryPointClassNames]) {
        Class cls = classLookup ? classLookup(className) : NSClassFromString(className);
        if (cls == Nil) {
            continue;
        }
        if ([cls conformsToProtocol:@protocol(AMAModuleEntryPoint)] == NO) {
            AMALogInfo(@"[AMACoreModuleComponentsInitializer] Class %@ does not conform to AMAModuleEntryPoint", className);
            continue;
        }
        id<AMAModuleEntryPoint> module = [[cls alloc] init];
        [controller registerModule:module];
    }
}

@end
