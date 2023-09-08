
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMAMockDatabase.h"
#import "AMATableSchemeController.h"
#import "AMABinaryDatabaseKeyValueStorageConverter.h"
#import "AMAStringDatabaseKeyValueStorageConverter.h"
#import "AMATableDescriptionProvider.h"
#import "AMAKeyValueStorageConverting.h"
#import "AMADatabaseKeyValueStorageProvider.h"
#import "AMADatabaseObjectProvider.h"
#import "AMADatabaseConstants.h"
#import "AMAFMDatabaseQueue.h"
@import FMDB;

@interface AMAMockDatabase ()

@property (nonatomic, strong, readonly) AMATableSchemeController *tableSchemeController;
@property (nonatomic, strong, readonly) NSMutableArray *delayedBlocks;

@property (nonatomic, strong) FMDatabaseQueue *dbQueue;

@end

@implementation AMAMockDatabase

@synthesize storageProvider = _storageProvider;

+ (instancetype)reporterDatabase
{
    AMATableSchemeController *tableSchemeController = [[AMATableSchemeController alloc] initWithTableSchemes:@{
        kAMAEventTableName: [AMATableDescriptionProvider eventsTableMetaInfo],
        kAMASessionTableName: [AMATableDescriptionProvider sessionsTableMetaInfo],
        kAMAKeyValueTableName: [AMATableDescriptionProvider binaryKVTableMetaInfo],
    }];
    id<AMAKeyValueStorageConverting> keyValueStorageConverter =
        [[AMABinaryDatabaseKeyValueStorageConverter alloc] init];
    return [[AMAMockDatabase alloc] initWithTableSchemeController:tableSchemeController
                                         keyValueStorageConverter:keyValueStorageConverter
                                                   objectProvider:[AMADatabaseObjectProvider blockForDataBlobs]];
}

+ (instancetype)configurationDatabase
{
    AMATableSchemeController *tableSchemeController = [[AMATableSchemeController alloc] initWithTableSchemes:@{
        kAMAKeyValueTableName: [AMATableDescriptionProvider stringKVTableMetaInfo],
    }];
    id<AMAKeyValueStorageConverting> keyValueStorageConverter =
        [[AMAStringDatabaseKeyValueStorageConverter alloc] init];
    return [[AMAMockDatabase alloc] initWithTableSchemeController:tableSchemeController
                                         keyValueStorageConverter:keyValueStorageConverter
                                                   objectProvider:[AMADatabaseObjectProvider blockForStrings]];
}

+ (instancetype)locationDatabase
{
    AMATableSchemeController *tableSchemeController = [[AMATableSchemeController alloc] initWithTableSchemes:@{
        kAMALocationsTableName: [AMATableDescriptionProvider locationsTableMetaInfo],
        kAMALocationsVisitsTableName: [AMATableDescriptionProvider visitsTableMetaInfo],
        kAMAKeyValueTableName: [AMATableDescriptionProvider stringKVTableMetaInfo],
    }];
    id<AMAKeyValueStorageConverting> keyValueStorageConverter =
        [[AMAStringDatabaseKeyValueStorageConverter alloc] init];
    return [[AMAMockDatabase alloc] initWithTableSchemeController:tableSchemeController
                                         keyValueStorageConverter:keyValueStorageConverter
                                                   objectProvider:[AMADatabaseObjectProvider blockForStrings]];
}

+ (instancetype)simpleKVDatabase
{
    NSArray *metaInfo = @[
        @{ kAMASQLName : kAMAKeyValueTableFieldKey, kAMASQLType : @"TEXT" },
        @{ kAMASQLName : kAMAKeyValueTableFieldValue, kAMASQLType : @"TEXT" },
    ];
    AMATableSchemeController *tableSchemeController = [[AMATableSchemeController alloc] initWithTableSchemes:@{
        kAMAKeyValueTableName: metaInfo,
    }];
    id<AMAKeyValueStorageConverting> keyValueStorageConverter =
        [[AMAStringDatabaseKeyValueStorageConverter alloc] init];
    return [[AMAMockDatabase alloc] initWithTableSchemeController:tableSchemeController
                                         keyValueStorageConverter:keyValueStorageConverter
                                                   objectProvider:[AMADatabaseObjectProvider blockForStrings]];
}

- (instancetype)initWithTableSchemeController:(AMATableSchemeController *)tableSchemeController
                     keyValueStorageConverter:(id<AMAKeyValueStorageConverting>)keyValueStorageConverter
                               objectProvider:(AMADatabaseObjectProviderBlock)objectProvider
{
    self = [super init];
    if (self != nil) {
        _tableSchemeController = tableSchemeController;
        AMADatabaseKeyValueStorageProvider *provider =
            [[AMADatabaseKeyValueStorageProvider alloc] initWithTableName:@"kv"
                                                                converter:keyValueStorageConverter
                                                           objectProvider:objectProvider
                                                   backingKVSDataProvider:nil];
        _storageProvider = provider;
        provider.database = self;
        _delayedBlocks = [NSMutableArray array];
    }
    return self;
}

- (AMADatabaseType)databaseType
{
    return AMADatabaseTypeInMemory;
}

- (NSString *)databasePath
{
    return nil;
}

- (void)dealloc
{
    [_dbQueue close];
}

- (void)inDatabase:(void (^)(FMDatabase *db))block
{
    [self inOpenedDatabase:^{
        [self.dbQueue inDatabase:block];
    }];
}

- (void)inTransaction:(void (^)(FMDatabase *db, AMARollbackHolder *rollback))block
{
    [self inOpenedDatabase:^{
        [self.dbQueue inExclusiveTransaction:^(FMDatabase *db, BOOL *rollback) {
            if (block != nil) {
                AMARollbackHolder *holder = [[AMARollbackHolder alloc] init];
                block(db, holder);
                if (holder.rollback) {
                    *rollback = YES;
                }
                [holder complete];
            }
        }];
    }];
}

- (NSString *)detectedInconsistencyDescription
{
    return nil;
}

- (void)resetDetectedInconsistencyDescription
{
    // Do nothing
}

- (void)ensureMigrated
{
    // Do nothing
}

- (void)migrateToMainApiKey:(NSString *)apiKey
{
    // Do nothing
}

- (void)executeWhenOpen:(dispatch_block_t)block
{
    if (block == nil) {
        return;
    }
    @synchronized (self) {
        if (self.dbQueue != nil) {
            block();
        }
        else {
            [self.delayedBlocks addObject:block];
        }
    }
}

- (void)inOpenedDatabase:(dispatch_block_t)block
{
    if (block != nil) {
        @synchronized(self) {
            if (self.dbQueue == nil) {
                self.dbQueue = [[AMAFMDatabaseQueue alloc] initWithPath:nil];
                [self.dbQueue inDatabase:^(FMDatabase *db) {
                    [self.tableSchemeController createSchemaInDB:db];
                }];
                for (dispatch_block_t block in self.delayedBlocks) {
                    block();
                }
                [self.delayedBlocks removeAllObjects];
            }
            block();
        }
    }
}

@end
