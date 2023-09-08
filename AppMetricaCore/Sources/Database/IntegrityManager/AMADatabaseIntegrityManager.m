
#import "AMACore.h"
#import "AMADatabaseIntegrityManager.h"
#import "AMADatabaseIntegrityStorageFactory.h"
#import "AMADatabaseIntegrityStorage.h"
#import "AMADatabaseIntegrityProcessor.h"
#import "AMADatabaseIntegrityReport.h"
#import "AMADatabaseQueueProvider.h"
#import "FMDB.h"

@interface AMADatabaseIntegrityManager ()

@property (nonatomic, strong, readonly) NSString *databasePath;
@property (nonatomic, strong, readonly) AMADatabaseIntegrityStorage *storage;
@property (nonatomic, strong, readonly) AMADatabaseIntegrityProcessor *processor;

@end

@implementation AMADatabaseIntegrityManager

- (instancetype)initWithDatabasePath:(NSString *)databasePath
{
    NSString *storagePath = [databasePath stringByAppendingPathExtension:@"stat"];

    AMADatabaseIntegrityStorage *storage = [AMADatabaseIntegrityStorageFactory storageForPath:storagePath];
    AMADatabaseIntegrityProcessor *processor = [[AMADatabaseIntegrityProcessor alloc] init];

    return [self initWithDatabasePath:databasePath
                              storage:storage
                            processor:processor];
}

- (instancetype)initWithDatabasePath:(NSString *)databasePath
                             storage:(AMADatabaseIntegrityStorage *)storage
                           processor:(AMADatabaseIntegrityProcessor *)processor
{

    self = [super init];
    if (self != nil) {
        _databasePath = [databasePath copy];
        _storage = storage;
        _processor = processor;
    }
    return self;
}

#pragma mark - Public -

- (FMDatabaseQueue *)databaseWithEnsuredIntegrityWithIsNew:(BOOL *)isNew
{
    BOOL dbFileExists = [AMAFileUtility fileExistsAtPath:self.databasePath];
    AMADatabaseIntegrityReport *report = [[AMADatabaseIntegrityReport alloc] init];
    FMDatabaseQueue *databaseQueue = [self ensureIntegrityWithReport:report];
    if (isNew != NULL) {
        *isNew = dbFileExists == NO || [report.lastAppliedFixStep isEqual:kAMADatabaseIntegrityStepNewDatabase];
    }
    return databaseQueue;
}

#pragma mark - Private -

- (FMDatabaseQueue *)ensureIntegrityWithReport:(AMADatabaseIntegrityReport *)report
{
    FMDatabaseQueue *databaseQueue = [[AMADatabaseQueueProvider sharedInstance] queueForPath:self.databasePath];
    if ([self.processor checkIntegrityIssuesForDatabase:databaseQueue report:report]) {
        AMALogInfo(@"Checked integrity issues");
        return databaseQueue;
    }
    if ([self.processor fixIndexForDatabase:databaseQueue report:report]) {
        AMALogInfo(@"Maybe fixed index");
        if ([self.processor checkIntegrityIssuesForDatabase:databaseQueue report:report]) {
            AMALogInfo(@"Fixed index");
            return databaseQueue;
        }
    }

    id context = [self.delegate contextForIntegrityManager:self
                                      thatWillDropDatabase:databaseQueue];

    if ([self.processor fixWithBackupAndRestore:&databaseQueue report:report]) {
        AMALogInfo(@"Maybe fixed with backup and restored");
        if ([self.processor checkIntegrityIssuesForDatabase:databaseQueue report:report]) {
            AMALogInfo(@"Fixed with backup and restored");
            [self.delegate integrityManager:self didCreateNewDatabase:databaseQueue context:context];
            return databaseQueue;
        }
    }

    if ([self.processor fixWithCreatingNewDatabase:&databaseQueue report:report]) {
        AMALogInfo(@"Maybe fixed with creating new database");
        if ([self.processor checkIntegrityIssuesForDatabase:databaseQueue report:report]) {
            AMALogInfo(@"Fixed with creating new database");
            [self.delegate integrityManager:self didCreateNewDatabase:databaseQueue context:context];
            return databaseQueue;
        }
    }

    return nil;
}

@end
