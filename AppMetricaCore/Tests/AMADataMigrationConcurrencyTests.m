#import <XCTest/XCTest.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaFMDB/AppMetricaFMDB.h>
#import "AMAAppMetricaConfiguration+JSONSerializable.h"
#import "AMAAppMetricaConfigurationFileStorage.h"
#import "AMAAppMetricaConfigurationSnapshot.h"
#import "AMAAppMetricaConfigurationStorageCoordinator.h"
#import "AMACachingKeyValueStorage.h"
#import "AMADataMigrationTo590.h"
#import "AMADataMigrationTo620.h"
#import "AMADatabase.h"
#import "AMADatabaseConstants.h"
#import "AMADatabaseFactory.h"
#import "AMADatabaseKeyValueStorageProvider.h"
#import "AMADatabaseMigrationManager.h"
#import "AMADatabaseMigrationProvider.h"
#import "AMADatabaseObjectProvider.h"
#import "AMAInMemoryKeyValueStorageDataProvider.h"
#import "AMAInstantFeaturesConfiguration+Migration.h"
#import "AMAMetricaConfiguration.h"
#import "AMAImmediateExclusiveLock.h"
#import "AMAStorageKeys.h"
#import "AMAStringDatabaseKeyValueStorageConverter.h"
#import "AMATableDescriptionProvider.h"
#import "AMATableSchemeController.h"

@import AppMetricaIdentifiers;

// Pause the competing reader immediately before it acquires the database lock.
// Cancellation lets the regression fail without leaving permanently deadlocked threads.
@interface AMAControlledMigrationDatabase : AMADatabase
@property (atomic, strong) NSThread *cacheReaderThread;
@property (atomic, assign) BOOL cancelCacheReader;
@property (nonatomic, copy) dispatch_block_t beforeCacheReaderAccess;
@end

@implementation AMAControlledMigrationDatabase
- (void)inDatabase:(void (^)(AMAFMDatabase *db))block
{
    if (NSThread.currentThread == self.cacheReaderThread) {
        self.beforeCacheReaderAccess();
        if (self.cancelCacheReader) {
            return;
        }
    }
    [super inDatabase:block];
}
@end

@interface AMAControlledDataMigration : NSObject <AMADatabaseDataMigration>
@property (nonatomic, strong) id<AMADatabaseDataMigration> migration;
@property (nonatomic, copy) dispatch_block_t beforeMigration;
@property (nonatomic, copy) dispatch_block_t afterMigration;
@end

@implementation AMAControlledDataMigration
- (NSString *)migrationKey
{
    return self.migration.migrationKey;
}
- (void)applyMigrationToDatabase:(id<AMADatabaseProtocol>)database
{
    self.beforeMigration();
    [self.migration applyMigrationToDatabase:database];
    self.afterMigration();
}
@end

@interface AMADataMigrationConcurrencyTests : XCTestCase
@property (nonatomic, copy) NSString *directory;
@property (nonatomic, strong) AMAAppMetricaConfigurationFileStorage *snapshotStorage;
@property (nonatomic, strong) AMAAppMetricaConfigurationStorageCoordinator *configurationStorage;
@property (nonatomic, strong) AMAMetricaConfiguration *configuration;
@end

@implementation AMADataMigrationConcurrencyTests

- (void)setUp
{
    [super setUp];
    self.directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    [[NSFileManager defaultManager] createDirectoryAtPath:self.directory
                            withIntermediateDirectories:YES attributes:nil error:nil];
    self.snapshotStorage = [[AMAAppMetricaConfigurationFileStorage alloc] initWithFileStorage:[AMAStorageMock new]];
    self.configurationStorage = [[AMAAppMetricaConfigurationStorageCoordinator alloc]
        initWithPrivateStorage:self.snapshotStorage groupStorage:nil lock:[AMAImmediateExclusiveLock new]];
    [AMAInstantFeaturesConfiguration stub:@selector(sharedInstance)
                               andReturn:[AMAInstantFeaturesConfiguration nullMock]];
    [AMAInstantFeaturesConfiguration stub:@selector(migrationInstance)
                               andReturn:[AMAInstantFeaturesConfiguration nullMock]];
}

- (void)tearDown
{
    [self.configuration clearStubs];
    [AMAMetricaConfiguration clearStubs];
    [AMADatabaseFactory clearStubs];
    [AMAInstantFeaturesConfiguration clearStubs];
    self.configuration = nil;
    [[NSFileManager defaultManager] removeItemAtPath:self.directory error:nil];
    [super tearDown];
}

- (AMAControlledMigrationDatabase *)databaseWithMigrations:(NSArray *)migrations
                                                    name:(NSString *)name
                                         backingProvider:(id<AMAKeyValueStorageDataProviding>)backingProvider
{
    AMADatabaseMigrationManager *manager = [[AMADatabaseMigrationManager alloc]
        initWithCurrentSchemeVersion:kAMAConfigurationDatabaseSchemaVersion
        schemeMigrations:@[] apiKeyMigrations:@[] dataMigrations:migrations libraryMigrations:@[]];
    AMADatabaseKeyValueStorageProvider *provider = [[AMADatabaseKeyValueStorageProvider alloc]
        initWithTableName:kAMAKeyValueTableName
        converter:[AMAStringDatabaseKeyValueStorageConverter new]
        objectProvider:[AMADatabaseObjectProvider blockForStrings] backingKVSDataProvider:backingProvider];
    [provider addBackingKeys:@[AMAStorageStringKeyUUID]];
    AMATableSchemeController *scheme = [[AMATableSchemeController alloc] initWithTableSchemes:@{
        kAMAKeyValueTableName: [AMATableDescriptionProvider stringKVTableMetaInfo],
    }];
    AMAControlledMigrationDatabase *database = [[AMAControlledMigrationDatabase alloc]
        initWithTableSchemeController:scheme databasePath:[self.directory stringByAppendingPathComponent:name]
        migrationManager:manager trimManager:nil keyValueStorageProvider:provider criticalKeyValueKeys:@[]];
    provider.database = database;
    return database;
}

- (NSObject<AMAIdentifierProviding> *)configureForDatabase:(id<AMADatabaseProtocol>)database
{
    [self.configuration clearStubs];
    self.configuration = [[AMAMetricaConfiguration alloc]
        initWithKeychainBridge:nil database:database appGroupIdentifierProvider:nil
        appMetricaConfigurationStorage:self.configurationStorage];
    NSObject<AMAIdentifierProviding> *identifierProvider = [KWMock nullMockForProtocol:@protocol(AMAIdentifierProviding)];
    [self.configuration stub:@selector(identifierProvider) andReturn:identifierProvider];
    [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:self.configuration];
    [AMADatabaseFactory stub:@selector(configurationDatabasePath) andReturn:database.databasePath];
    return identifierProvider;
}

- (void)testMigrationsCompleteWhileConcurrentCacheReaderIsWaitingForDatabase
{
    for (id<AMADatabaseDataMigration> migration in @[[AMADataMigrationTo590 new], [AMADataMigrationTo620 new]]) {
        NSString *expectedUUID = @"550e8400-e29b-41d4-a716-446655440000";
        @autoreleasepool {
            AMAControlledMigrationDatabase *seed = [self databaseWithMigrations:@[] name:migration.migrationKey
                                                               backingProvider:nil];
            XCTAssertTrue([seed.storageProvider.syncStorage saveString:expectedUUID forKey:AMAStorageStringKeyUUID error:nil]);
        }
        dispatch_semaphore_t migrationEntered = dispatch_semaphore_create(0);
        dispatch_semaphore_t readerEntered = dispatch_semaphore_create(0);
        dispatch_semaphore_t resumeMigration = dispatch_semaphore_create(0);
        dispatch_semaphore_t migrationCompleted = dispatch_semaphore_create(0);
        dispatch_semaphore_t resumeReader = dispatch_semaphore_create(0);
        dispatch_group_t workers = dispatch_group_create();
        AMAControlledDataMigration *controlledMigration = [AMAControlledDataMigration new];
        controlledMigration.migration = migration;
        controlledMigration.beforeMigration = ^{
            dispatch_semaphore_signal(migrationEntered);
            dispatch_semaphore_wait(resumeMigration, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));
        };
        controlledMigration.afterMigration = ^{
            dispatch_semaphore_signal(migrationCompleted);
        };
        AMAControlledMigrationDatabase *database = [self databaseWithMigrations:@[controlledMigration]
                                                                           name:migration.migrationKey backingProvider:nil];
        NSObject<AMAIdentifierProviding> *identifierProvider = [self configureForDatabase:database];
        __block NSString *migratedUUID = nil;
        [identifierProvider stub:@selector(updateAppMigrationDataWithUuid:) withBlock:^id(NSArray *params) {
            migratedUUID = params[0];
            return nil;
        }];
        database.beforeCacheReaderAccess = ^{
            dispatch_semaphore_signal(readerEntered);
            dispatch_semaphore_wait(resumeReader, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));
        };
        // An earlier migration can already have flushed the cache before this migration runs.
        // With no pending writes this disables delayed reads without opening the database.
        [(AMACachingKeyValueStorage *)database.storageProvider.cachingStorage flush];
        dispatch_group_async(workers, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
            [database ensureMigrated];
        });
        XCTAssertEqual(dispatch_semaphore_wait(migrationEntered, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC)), 0);
        dispatch_group_async(workers, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
            database.cacheReaderThread = NSThread.currentThread;
            [database.storageProvider.cachingStorage jsonDictionaryForKey:AMAStorageStringKeyAttributionModel
                                                                    error:nil];
        });
        XCTAssertEqual(dispatch_semaphore_wait(readerEntered, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC)), 0);
        dispatch_semaphore_signal(resumeMigration);
        long result = dispatch_semaphore_wait(migrationCompleted, dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC));
        database.cancelCacheReader = result != 0;
        dispatch_semaphore_signal(resumeReader);
        XCTAssertEqual(dispatch_group_wait(workers, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC)), 0);
        XCTAssertEqual(result, 0, @"%@ waited for the cache while holding the database lock", migration.migrationKey);
        XCTAssertTrue([database.storageProvider.syncStorage boolNumberForKey:migration.migrationKey error:nil].boolValue);
        if ([migration isKindOfClass:AMADataMigrationTo590.class]) {
            XCTAssertEqualObjects(migratedUUID, expectedUUID);
        }
    }
}

- (void)testUUIDMigrationPreservesSourcePriority
{
    NSArray<NSDictionary<NSString *, NSString *> *> *cases = @[
        @{ @"instant": @"instant-uuid", @"database": @"database-uuid", @"backup": @"backup-uuid",
           @"legacyInstant": @"legacy-uuid", @"expected": @"instant-uuid" },
        @{ @"database": @"database-uuid", @"backup": @"backup-uuid", @"legacyInstant": @"legacy-uuid",
           @"expected": @"database-uuid" },
        @{ @"backup": @"backup-uuid", @"legacyInstant": @"legacy-uuid", @"expected": @"backup-uuid" },
        @{ @"legacyInstant": @"legacy-uuid", @"expected": @"legacy-uuid" },
        @{},
    ];
    for (NSDictionary<NSString *, NSString *> *values in cases) {
        NSString *name = NSUUID.UUID.UUIDString;
        @autoreleasepool {
            AMAControlledMigrationDatabase *seed = [self databaseWithMigrations:@[] name:name backingProvider:nil];
            [seed ensureMigrated];
            if (values[@"database"] != nil) {
                XCTAssertTrue([seed.storageProvider.syncStorage saveString:values[@"database"]
                                                                    forKey:AMAStorageStringKeyUUID error:nil]);
            }
        }
        AMAInMemoryKeyValueStorageDataProvider *backup = [AMAInMemoryKeyValueStorageDataProvider new];
        if (values[@"backup"] != nil) {
            [backup saveObject:values[@"backup"] forKey:AMAStorageStringKeyUUID error:nil];
        }
        AMAInstantFeaturesConfiguration *instant = [AMAInstantFeaturesConfiguration nullMock];
        [instant stub:@selector(UUID) andReturn:values[@"instant"]];
        [AMAInstantFeaturesConfiguration stub:@selector(sharedInstance) andReturn:instant];
        AMAInstantFeaturesConfiguration *legacyInstant = [AMAInstantFeaturesConfiguration nullMock];
        [legacyInstant stub:@selector(UUID) andReturn:values[@"legacyInstant"]];
        [AMAInstantFeaturesConfiguration stub:@selector(migrationInstance) andReturn:legacyInstant];

        AMADataMigrationTo590 *migration = [AMADataMigrationTo590 new];
        AMAControlledMigrationDatabase *database = [self databaseWithMigrations:@[migration] name:name backingProvider:backup];
        NSObject<AMAIdentifierProviding> *identifierProvider = [self configureForDatabase:database];
        __block NSString *migratedUUID = nil;
        __block NSUInteger updates = 0;
        [identifierProvider stub:@selector(updateAppMigrationDataWithUuid:) withBlock:^id(NSArray *params) {
            migratedUUID = params[0];
            updates++;
            return nil;
        }];
        [database ensureMigrated];
        XCTAssertEqualObjects(migratedUUID, values[@"expected"]);
        XCTAssertEqual(updates, values[@"expected"] == nil ? 0u : 1u);
        XCTAssertTrue([database.storageProvider.syncStorage boolNumberForKey:migration.migrationKey error:nil].boolValue);
    }
}

- (void)testLegacyConfigurationMigrationPreservesConfigurationAndSnapshotDate
{
    NSString *name = @"configuration.sqlite";
    AMAAppMetricaConfiguration *configuration = [[AMAAppMetricaConfiguration alloc]
        initWithAPIKey:@"550e8400-e29b-41d4-a716-446655440000"];
    configuration.sessionTimeout = 120;
    configuration.logsEnabled = YES;
    AMAControlledMigrationDatabase *seed = [self databaseWithMigrations:@[] name:name backingProvider:nil];
    [seed.storageProvider.syncStorage saveJSONDictionary:configuration.JSON
                                                 forKey:AMAStorageStringKeyAppMetricaClientConfiguration error:nil];
    NSDate *savedAt = [NSDate dateWithTimeIntervalSince1970:123];
    AMAAppMetricaConfiguration *currentConfiguration = [[AMAAppMetricaConfiguration alloc]
        initWithAPIKey:@"660e8400-e29b-41d4-a716-446655440000"];
    [self.snapshotStorage saveSnapshot:[[AMAAppMetricaConfigurationSnapshot alloc]
        initWithConfiguration:currentConfiguration savedAt:savedAt source:AMAAppMetricaConfigurationSnapshotSourcePrivate]];

    AMADataMigrationTo620 *migration = [AMADataMigrationTo620 new];
    AMAControlledMigrationDatabase *database = [self databaseWithMigrations:@[migration] name:name backingProvider:nil];
    [self configureForDatabase:database];
    [database ensureMigrated];
    AMAAppMetricaConfigurationSnapshot *snapshot = [self.snapshotStorage loadSnapshot];
    XCTAssertEqualObjects(snapshot.configuration.JSON, configuration.JSON);
    XCTAssertEqualObjects(snapshot.savedAt, savedAt);
    XCTAssertEqual(snapshot.source, AMAAppMetricaConfigurationSnapshotSourcePrivate);
    XCTAssertTrue([database.storageProvider.syncStorage boolNumberForKey:migration.migrationKey error:nil].boolValue);
}

@end
