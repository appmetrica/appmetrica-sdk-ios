
#import "AMACrashReporterFactory.h"
#import "AMACrashReporting.h"
#import "AMAExceptionFormatting.h"
#import "AMAExecutablesUUIDProviding.h"

static NSString *const kAMADefaultCrashReporterClassName = @"AMACrashReporter";
static NSString *const kAMAExceptionFormatterClassName = @"AMAExceptionFormatter";
static NSString *const kAMAUserImagesUUIDProvider = @"AMAUserImagesUUIDProvider";

@implementation AMACrashReporterFactory

+ (id<AMACrashReporting>)crashReporterWithExecutor:(id<AMAExecuting>)executor
                                 hostStateProvider:(AMAHostStateProvider *)hostStateProvider
{
    Class crashReportingClass = [self crashReporterClass];
    return [[crashReportingClass alloc] initWithExecutor:executor];
}

+ (Class<AMACrashReporting>)crashReporterClass
{
    static Class reportingClass = Nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //TODO: Fix AMAManglingUtility with Crashes
        NSString *reporterName = kAMADefaultCrashReporterClassName;//[AMAManglingUtility mangledClassName:kAMADefaultCrashReporterClassName];
        reportingClass = NSClassFromString(reporterName);
    });
    return reportingClass;
}

+ (id<AMAExceptionFormatting>)exceptionFormatter
{
    Class formatterClass = [self exceptionFormatterClass];
    return (id<AMAExceptionFormatting>)[[formatterClass alloc] init];
}

+ (Class<AMAExceptionFormatting>)exceptionFormatterClass
{
    static Class formatterClass = Nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *reporterName = kAMADefaultCrashReporterClassName;//[AMAManglingUtility mangledClassName:kAMAExceptionFormatterClassName];
        formatterClass = NSClassFromString(reporterName);
    });
    return formatterClass;
}

+ (Class<AMAExecutablesUUIDProviding>)executablesUUIDProviderClass
{
    static Class providerClass = Nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *providerName = kAMADefaultCrashReporterClassName;//[AMAManglingUtility mangledClassName:kAMAUserImagesUUIDProvider];
        providerClass = NSClassFromString(providerName);
    });
    return providerClass;
}

+ (id<AMAExecutablesUUIDProviding>)executablesUUIDProvider
{
    Class providerClass = [self executablesUUIDProviderClass];
    return (id<AMAExecutablesUUIDProviding>)[[providerClass alloc] init];
}

@end
