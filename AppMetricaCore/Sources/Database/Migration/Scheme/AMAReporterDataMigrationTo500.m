
#import <AppMetricaLog/AppMetricaLog.h>
#import "AMAStorageKeys.h"
#import "AMAReporterDataMigrationTo500.h"
#import "AMADatabaseProtocol.h"
#import "AMADatabaseConstants.h"
#import <AppMetricaFMDB/AppMetricaFMDB.h>
#import "AMATableDescriptionProvider.h"
#import "AMAMigrationTo500Utils.h"
#import "AMAReporterStorage.h"

@interface AMAReporterDataMigrationTo500 ()

@property (nonatomic, strong) NSString *apiKey;
@property (nonatomic, assign) BOOL main;

@end

@implementation AMAReporterDataMigrationTo500

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
    return AMAStorageStringKeyDidApplyDataMigrationFor500;
}

- (void)applyMigrationToDatabase:(id<AMADatabaseProtocol>)database
{
    NSString *oldDirPath = [[AMAMigrationTo500Utils migrationPath] stringByAppendingPathComponent:self.apiKey];
    NSString *oldDBPath = [oldDirPath stringByAppendingPathComponent:@"data.sqlite"];
    
    if ([AMAFileUtility fileExistsAtPath:oldDBPath] == NO) {
        return;
    }
    
    NSString *newAPIKeyDirPath = [AMAFileUtility persistentPathForApiKey:self.apiKey];
    NSString *newAPIKeyDBPath = [newAPIKeyDirPath stringByAppendingPathComponent:@"data.sqlite"];
    
    if (self.main == YES) {
        // Skip migration for main reporter; migrate a separate one with the old API format.
        [self createStorageIfNeeded:newAPIKeyDBPath];
        return;
    }
    
    [self migrateReporterData:oldDBPath database:database];
    [AMAMigrationTo500Utils migrateReporterEventHashes:oldDirPath apiKey:self.apiKey];
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
                [AMAMigrationTo500Utils migrateTable:table
                                         tableScheme:[tables objectForKey:table]
                                            sourceDB:sourceDB
                                       destinationDB:db];
            }
            [AMAMigrationTo500Utils migrateReporterEvents:sourceDB
                                            destinationDB:db
                                                   apiKey:self.apiKey];

            [db close];
        }];
    [sourceDB close];
}

- (void)createStorageIfNeeded:(NSString *)dbPath
{
    if ([AMAFileUtility fileExistsAtPath:dbPath] == NO) {
        AMAReporterStorage *reporterStorage = [[AMAReporterStorage alloc] initWithApiKey:self.apiKey
                                                                        eventEnvironment:[[AMAEnvironmentContainer alloc] init]
                                                                                    main:NO];
        [reporterStorage storageInDatabase:^(id<AMAKeyValueStoring>  _Nonnull storage) {}];
    }
}

@end
