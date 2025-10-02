#import "AMADatabaseQueryRecorderMock.h"
#import <Kiwi/Kiwi.h>
#import "AMAFMDatabaseQueryRecorderMock.h"

@interface AMADatabaseQueryRecorderMock ()

@property (nonatomic, strong, nonnull) AMAFMDatabaseQueryRecorderMock *fmDbQueryRecorderMock;

@end

@implementation AMADatabaseQueryRecorderMock

- (instancetype)init
{
    self = [super init];
    if (self) {
        _storageProvider = [KWMock nullMockForProtocol:@protocol(AMADatabaseKeyValueStorageProviding)];
        _fmDbQueryRecorderMock = [AMAFMDatabaseQueryRecorderMock new];
    }
    return self;
}

- (NSArray<NSString *> *)executedStatements
{
    return self.fmDbQueryRecorderMock.executedStatements;
}

- (AMADatabaseType)databaseType
{
    return AMADatabaseTypeInMemory;
}

- (NSString *)databasePath
{
    return nil;
}

- (void)inDatabase:(void (^)(AMAFMDatabase *db))block
{
    block(self.fmDbQueryRecorderMock);
}

- (void)inTransaction:(void (^)(AMAFMDatabase *db, AMARollbackHolder *rollbackHolder))block
{
    [NSException raise:@"inTransaction not implemented" format:@""];
}

- (void)ensureMigrated
{
    
}

- (void)migrateToMainApiKey:(NSString *)apiKey
{
    
}

- (NSString *)detectedInconsistencyDescription
{
    return nil;
}

- (void)resetDetectedInconsistencyDescription
{
    
}

- (void)executeWhenOpen:(dispatch_block_t)block
{
    
}

@end
