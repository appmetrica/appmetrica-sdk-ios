
#import "AMADatabaseMigrationProvider.h"
#import "AMADatabaseSchemeMigration.h"

#import "AMAConfigurationDatabaseSchemeMigrationTo2.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo3.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo4.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo5.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo6.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo7.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo8.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo9.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo10.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo11.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo12.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo13.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo14.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo15.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo16.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo17.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo18.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo19.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo20.h"
#import "AMAMigrationTo19FinalizationOnApiKeySpecified.h"
#import "AMALibraryMigration320.h"

#import "AMADataMigrationTo500.h"
#import "AMAReporterDataMigrationTo500.h"
#import "AMALocationDataMigrationTo500.h"
#import "AMALocationDataMigrationTo5100.h"
#import "AMADataMigrationTo580.h"
#import "AMAReporterDataMigrationTo580.h"
#import "AMAReporterDataMigrationTo5100.h"
#import "AMADataMigrationTo590.h"
#import "AMADataMigrationTo5100.h"

#import "AMALocationDatabaseSchemeMigrationTo2.h"

#import "AMAReporterDatabaseSchemeMigrationTo2.h"

//1 - initial
//2 - added api_key and type to sessions
//3 - added finished to sessions
//4 - moved location to events, removed from sessions
//5 - added location to errors table
//6 - added server_time_offset to session, event environment
//7 - change api_key type from INTEGER to STRING
//8 - change event environment to error_environment, add app_environment
//9 - change event is_truncated to bytes_truncated
//10 - change session updated_at to last_event_time and pause_time
//11 - move errors table to events table, remov errors table
//12 - move reportsURL into reportHosts
//13 - add location_enabled to events
//14 - add user_profile_id to events
//15 - add encryption_type to events
//16 - add session_id and attribution_id to sessions, add first_occurrence to events
//17 - add startup.had.first to kv
//18 - add global_number and number_of_type to events
//19 - separate storage into api-key specific storages (for reporters) and one shared (for global config)
//20 - change type of columns from STRING to TEXT
NSUInteger const kAMAConfigurationDatabaseSchemaVersion = 20;

//1 - initial
//2 - change type of columns from STRING to TEXT
NSUInteger const kAMAReporterDatabaseSchemaVersion = 2;

//1 - initial
//2 - change type of columns from STRING to TEXT
//~ - add `visit` table. No migration needed, because new tables are created automatically
NSUInteger const kAMALocationDatabaseSchemaVersion = 2;

@interface AMADatabaseMigrationProvider ()

@property (nonatomic, readonly) AMADatabaseContentType contentType;

@end

@implementation AMADatabaseMigrationProvider

- (instancetype)init
{
    return [self initWithContentType:AMADatabaseContentTypeConfiguration];
}

- (instancetype)initWithContentType:(AMADatabaseContentType)contentType
{
    self = [super init];
    if (self) {
        _contentType = contentType;
    }
    return self;
}

- (NSArray<AMADatabaseSchemeMigration *> *)schemeMigrations
{
    switch (self.contentType) {
        case AMADatabaseContentTypeConfiguration:
            return [self configurationSchemeMigrations];
        case AMADatabaseContentTypeReporter:
            return [self reporterSchemeMigrations];
        case AMADatabaseContentTypeLocation:
            return [self locationSchemeMigrations];
        default:
            return @[];
    }
}

- (NSArray<id<AMAApiKeyMigration>> *)apiKeyMigrations
{
    switch (self.contentType) {
        case AMADatabaseContentTypeConfiguration:
            return [self configurationAPIKeyMigrations];
        case AMADatabaseContentTypeReporter:
        case AMADatabaseContentTypeLocation:
        default:
            return @[];
    }
}

- (NSArray<id<AMADatabaseDataMigration>> *)dataMigrationsWithAPIKey:(NSString *)apiKey
                                                               main:(BOOL)main
{
    switch (self.contentType) {
        case AMADatabaseContentTypeConfiguration:
            return [self configurationDataMigrations];
        case AMADatabaseContentTypeReporter:
            return [self reporterDataMigrationsWithAPIKey:apiKey main:main];
        case AMADatabaseContentTypeLocation:
            return [self locationDataMigrations];
        default:
            return @[];
    }
}

- (NSArray<id<AMALibraryMigration>> *)libraryMigrations
{
    switch (self.contentType) {
        case AMADatabaseContentTypeConfiguration:
            return [self configurationLibraryMigrations];
        case AMADatabaseContentTypeReporter:
        case AMADatabaseContentTypeLocation:
        default:
            return @[];
    }
}

#pragma mark - Scheme migrations

- (NSArray<AMADatabaseSchemeMigration *> *)configurationSchemeMigrations
{
    return @[
        [AMAConfigurationDatabaseSchemeMigrationTo2 new],
        [AMAConfigurationDatabaseSchemeMigrationTo3 new],
        [AMAConfigurationDatabaseSchemeMigrationTo4 new],
        [AMAConfigurationDatabaseSchemeMigrationTo5 new],
        [AMAConfigurationDatabaseSchemeMigrationTo6 new],
        [AMAConfigurationDatabaseSchemeMigrationTo7 new],
        [AMAConfigurationDatabaseSchemeMigrationTo8 new],
        [AMAConfigurationDatabaseSchemeMigrationTo9 new],
        [AMAConfigurationDatabaseSchemeMigrationTo10 new],
        [AMAConfigurationDatabaseSchemeMigrationTo11 new],
        [AMAConfigurationDatabaseSchemeMigrationTo12 new],
        [AMAConfigurationDatabaseSchemeMigrationTo13 new],
        [AMAConfigurationDatabaseSchemeMigrationTo14 new],
        [AMAConfigurationDatabaseSchemeMigrationTo15 new],
        [AMAConfigurationDatabaseSchemeMigrationTo16 new],
        [AMAConfigurationDatabaseSchemeMigrationTo17 new],
        [AMAConfigurationDatabaseSchemeMigrationTo18 new],
        [AMAConfigurationDatabaseSchemeMigrationTo19 new],
        [AMAConfigurationDatabaseSchemeMigrationTo20 new],
    ];
}

- (NSArray<AMADatabaseSchemeMigration *> *)reporterSchemeMigrations
{
    return @[
        [AMAReporterDatabaseSchemeMigrationTo2 new],
    ];
}

- (NSArray<AMADatabaseSchemeMigration *> *)locationSchemeMigrations
{
    return @[
        [AMALocationDatabaseSchemeMigrationTo2 new],
    ];
}

#pragma mark - API Key migrations

- (NSArray<id<AMAApiKeyMigration>> *)configurationAPIKeyMigrations
{
    return @[
        [AMAMigrationTo19FinalizationOnApiKeySpecified new],
    ];
}

#pragma mark - Data migrations

- (NSArray<id<AMADatabaseDataMigration>> *)configurationDataMigrations
{
    return @[
        [AMADataMigrationTo500 new],
        [AMADataMigrationTo580 new],
        [AMADataMigrationTo590 new],
        [AMADataMigrationTo5100 new],
    ];
}

- (NSArray<id<AMADatabaseDataMigration>> *)reporterDataMigrationsWithAPIKey:(NSString *)apiKey
                                                                       main:(BOOL)main
{
    return @[
        [[AMAReporterDataMigrationTo500 alloc] initWithApiKey:apiKey main:main],
        [[AMAReporterDataMigrationTo580 alloc] initWithApiKey:apiKey main:main],
        [[AMAReporterDataMigrationTo5100 alloc] initWithApiKey:apiKey],
    ];
}

- (NSArray<id<AMADatabaseDataMigration>> *)locationDataMigrations
{
    return @[
        [AMALocationDataMigrationTo500 new],
        [AMALocationDataMigrationTo5100 new],
    ];
}

#pragma mark - Library migrations

- (NSArray<id<AMALibraryMigration>> *)configurationLibraryMigrations
{
    return @[
        [AMALibraryMigration320 new],
    ];
}

@end
