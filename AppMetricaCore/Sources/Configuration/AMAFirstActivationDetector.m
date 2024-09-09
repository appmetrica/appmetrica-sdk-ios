
#import "AMAFirstActivationDetector.h"
#import "AMAMigrationTo500Utils.h"
#import "AMACore.h"
#import "AMAMetricaInMemoryConfiguration.h"
#import "AMADatabaseFactory.h"

@implementation AMAFirstActivationDetector

+ (BOOL)isFirstLibraryReporterActivation
{
    return [self isReporterUnavailable:kAMAMetricaLibraryApiKey];
}

+ (BOOL)isFirstMainReporterActivation
{
    return [self isReporterUnavailable:kAMAMainReporterDBPath];
}

+ (BOOL)isReporterUnavailable:(NSString *)path
{
    NSString *libraryReporterMigrationPath = [[AMAMigrationTo500Utils migrationPath] stringByAppendingPathComponent:path];
    NSString *libraryReporterPath = [AMAFileUtility persistentPathForApiKey:path];
    
    NSString *(^dbFilePath)(NSString *) = ^NSString *(NSString *basePath) {
        return [basePath stringByAppendingPathComponent:@"data.sqlite"];
    };
    
    return ![AMAFileUtility fileExistsAtPath:dbFilePath(libraryReporterMigrationPath)] &&
           ![AMAFileUtility fileExistsAtPath:dbFilePath(libraryReporterPath)];
}

@end
