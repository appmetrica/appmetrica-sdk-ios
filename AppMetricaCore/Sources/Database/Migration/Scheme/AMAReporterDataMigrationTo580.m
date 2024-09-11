
#import <AppMetricaLog/AppMetricaLog.h>
#import "AMAStorageKeys.h"
#import "AMAReporterDataMigrationTo580.h"
#import "AMADatabaseProtocol.h"
#import "AMADatabaseConstants.h"
#import <AppMetricaFMDB/AppMetricaFMDB.h>
#import "AMATableDescriptionProvider.h"
#import "AMAMigrationTo580Utils.h"
#import "AMADatabaseFactory.h"

@interface AMAReporterDataMigrationTo580 ()

@property (nonatomic, strong) NSString *apiKey;
@property (nonatomic, assign) BOOL main;

@end

@implementation AMAReporterDataMigrationTo580

- (instancetype)initWithApiKey:(NSString *)apiKey main:(BOOL)main
{
    self = [super init];
    if (self != nil) {
        self.apiKey = apiKey;
        self.main = main;
    }
    return self;
}

- (NSString *)migrationKey
{
    return AMAStorageStringKeyDidApplyDataMigrationFor580;
}

- (void)applyMigrationToDatabase:(id<AMADatabaseProtocol>)database
{
    NSString *reporterPath = [[AMAFileUtility persistentPathForApiKey:self.apiKey]
                              stringByAppendingPathComponent:@"data.sqlite"];
    @synchronized (self) {
        if ([AMAFileUtility fileExistsAtPath:reporterPath] == NO) {
            return;
        }
        if (self.main) {
            [self migrateReporterData:reporterPath database:database];
            [AMAMigrationTo580Utils migrateReporterEventHashes:self.apiKey];
            [self copyReporterBackup];
        }
    }
}

- (void)migrateReporterData:(NSString *)sourceDBPath
                   database:(id<AMADatabaseProtocol>)database
{
    AMAFMDatabase *sourceDB = [AMAFMDatabase databaseWithPath:sourceDBPath];
    
    if ([sourceDB open] == NO) {
        AMALogWarn(@"Failed to open database at path: %@", sourceDBPath);
        return;
    }
    
    NSDictionary *tables = @{
        kAMAKeyValueTableName : [AMATableDescriptionProvider binaryKVTableMetaInfo],
        kAMASessionTableName : [AMATableDescriptionProvider sessionsTableMetaInfo],
    };
    [database inDatabase:^(AMAFMDatabase *db) {
        for (NSString *table in tables) {
            [AMAMigrationTo580Utils migrateTable:table
                                     tableScheme:[tables objectForKey:table]
                                        sourceDB:sourceDB
                                   destinationDB:db];
        }
        [AMAMigrationTo580Utils migrateReporterEvents:sourceDB
                                        destinationDB:db
                                               apiKey:self.apiKey];
        
        [db close];
    }];
    [sourceDB close];
}

- (void)copyReporterBackup
{
    NSString *reporterBackPath = [[AMAFileUtility persistentPathForApiKey:self.apiKey] stringByAppendingPathComponent:@"data.bak"];
    NSString *newDirPath = [[AMAFileUtility persistentPathForApiKey:kAMAMainReporterDBPath] stringByAppendingPathComponent:@"data.bak"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (![fileManager fileExistsAtPath:reporterBackPath]) {
        return;
    }
    if ([fileManager fileExistsAtPath:newDirPath]) {
        return;
    }

    NSError *error;
    if (![fileManager copyItemAtPath:reporterBackPath toPath:newDirPath error:&error]) {
        AMALogWarn(@"Failed to copy reporter backup from %@ to %@: %@", reporterBackPath, newDirPath, error);
    } else {
        AMALogWarn(@"Successfully copied reporter backups from %@ to %@", reporterBackPath, newDirPath);
    }
}

@end
