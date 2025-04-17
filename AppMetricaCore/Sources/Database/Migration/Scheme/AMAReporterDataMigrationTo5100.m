
#import <AppMetricaLog/AppMetricaLog.h>
#import "AMAStorageKeys.h"
#import "AMAReporterDataMigrationTo5100.h"
#import "AMADatabaseProtocol.h"
#import "AMADatabaseConstants.h"
#import <AppMetricaFMDB/AppMetricaFMDB.h>
#import "AMATableDescriptionProvider.h"
#import "AMAMigrationTo5100Utils.h"

@interface AMAReporterDataMigrationTo5100 ()

@property (nonatomic, strong) NSString *apiKey;

@end

@implementation AMAReporterDataMigrationTo5100

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
    return AMAStorageStringKeyDidApplyDataMigrationFor5100;
}

- (void)applyMigrationToDatabase:(id<AMADatabaseProtocol>)database
{
    @synchronized (self) {
        [self migrateReporterDataInDatabase:database];
    }
}

- (void)migrateReporterDataInDatabase:(id<AMADatabaseProtocol>)database
{
    NSDictionary *tables = @{
        kAMASessionTableName : [AMATableDescriptionProvider sessionsTableMetaInfo],
        kAMAEventTableName : [AMATableDescriptionProvider eventsTableMetaInfo],
    };
    [database inDatabase:^(AMAFMDatabase *db) {
        for (NSString *table in tables) {
            [AMAMigrationTo5100Utils migrateReporterTable:table
                                              tableScheme:[tables objectForKey:table]
                                                       db:db];
        }
        
        [db close];
    }];
}

@end
