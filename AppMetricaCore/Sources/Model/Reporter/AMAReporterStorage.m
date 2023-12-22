
#import "AMAReporterStorage.h"
#import "AMADatabaseFactory.h"
#import "AMADatabaseProtocol.h"
#import "AMAEventSerializer.h"
#import "AMASessionSerializer.h"
#import "AMAReporterStateStorage.h"
#import "AMASessionStorage.h"
#import "AMAEventStorage.h"
#import "AMAReportRequestProvider.h"
#import "AMAEventsCleaner.h"
#import "AMASessionsCleaner.h"
#import "AMAReporterStoragesContainer.h"
#import "AMASharedReporterProvider.h"

@interface AMAReporterStorage ()

@property (nonatomic, strong, readonly) id<AMADatabaseProtocol> database;
@property (nonatomic, strong, readonly) AMAEventSerializer *eventSerializer;
@property (nonatomic, strong, readonly) AMASessionSerializer *sessionSerializer;

@end

@implementation AMAReporterStorage

- (instancetype)initWithApiKey:(NSString *)apiKey
              eventEnvironment:(AMAEnvironmentContainer *)eventEnvironment
{
    AMASharedReporterProvider *reporterProvider = [[AMASharedReporterProvider alloc] initWithApiKey:apiKey];
    AMAEventsCleaner *eventsCleaner = [[AMAEventsCleaner alloc] initWithReporterProvider:reporterProvider];
    return [self initWithApiKey:apiKey
               eventEnvironment:eventEnvironment
                  eventsCleaner:eventsCleaner
                       database:[AMADatabaseFactory reporterDatabaseForApiKey:apiKey
                                                                eventsCleaner:eventsCleaner]];
}

- (instancetype)initWithApiKey:(NSString *)apiKey
              eventEnvironment:(AMAEnvironmentContainer *)eventEnvironment
                 eventsCleaner:(AMAEventsCleaner *)eventsCleaner
                      database:(id<AMADatabaseProtocol>)database
{
    self = [super init];
    if (self != nil) {
        _apiKey = [apiKey copy];
        _database = database;

        _eventSerializer = [[AMAEventSerializer alloc] init];
        _sessionSerializer = [[AMASessionSerializer alloc] init];
        _stateStorage = [[AMAReporterStateStorage alloc] initWithStorageProvider:database.storageProvider
                                                                eventEnvironment:eventEnvironment];
        _sessionStorage = [[AMASessionStorage alloc] initWithDatabase:database
                                                           serializer:_sessionSerializer
                                                         stateStorage:_stateStorage];
        _eventStorage = [[AMAEventStorage alloc] initWithDatabase:database
                                                  eventSerializer:_eventSerializer];
        _reportRequestProvider = [[AMAReportRequestProvider alloc] initWithApiKey:apiKey
                                                                         database:database
                                                                  eventSerializer:_eventSerializer
                                                                sessionSerializer:_sessionSerializer];
        _sessionsCleaner = [[AMASessionsCleaner alloc] initWithDatabase:database
                                                          eventsCleaner:eventsCleaner
                                                                 apiKey:apiKey];
    }
    return self;
}

- (id<AMADatabaseKeyValueStorageProviding>)keyValueStorageProvider
{
    return self.database.storageProvider;
}

- (void)storageInDatabase:(void (^)(id<AMAKeyValueStoring> storage))block
{
    [self.database inDatabase:^(AMAFMDatabase *db) {
        if (block != nil) {
            block([self.database.storageProvider storageForDB:db]);
        }
    }];
}

- (void)restoreState
{
    [[AMAReporterStoragesContainer sharedInstance] waitMigrationForApiKey:self.apiKey];
    [self.stateStorage restoreState];
}

@end
