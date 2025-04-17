
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

@end

@implementation AMAReporterDataMigrationTo500

- (instancetype)initWithApiKey:(NSString *)apiKey
{
    self = [super init];
    if (self != nil) {
        self.apiKey = apiKey;
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
    
    @synchronized (self) {
        [self createStorageIfNeeded:newAPIKeyDBPath];
        [self migrateReporterData:oldDBPath destinationDBPath:newAPIKeyDBPath];
        [AMAMigrationTo500Utils migrateReporterEventHashes:oldDirPath apiKey:self.apiKey];
    }
}

- (void)migrateReporterData:(NSString *)sourceDBPath
          destinationDBPath:(NSString *)destinationDBPath
{
    AMAFMDatabase *sourceDB = [AMAFMDatabase databaseWithPath:sourceDBPath];
    AMAFMDatabase *destinationDB = [AMAFMDatabase databaseWithPath:destinationDBPath];

    if ([sourceDB open] == NO) {
        AMALogWarn(@"Failed to open database at path: %@", sourceDBPath);
        return;
    }

    if ([destinationDB open] == NO) {
        AMALogWarn(@"Failed to open database at path: %@", destinationDBPath);
        return;
    }

    NSDictionary *tables = @{
        kAMAKeyValueTableName : [AMATableDescriptionProvider binaryKVTableMetaInfo],
        kAMASessionTableName : [AMATableDescriptionProvider sessionsTableMetaInfo],
    };
    for (NSString *table in tables) {
        [AMAMigrationTo500Utils migrateTable:table
                                 tableScheme:[tables objectForKey:table]
                                    sourceDB:sourceDB
                               destinationDB:destinationDB];
    }
    [AMAMigrationTo500Utils migrateReporterEvents:sourceDB
                                    destinationDB:destinationDB
                                           apiKey:self.apiKey];

    [sourceDB close];
    [destinationDB close];
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
