
#import <Foundation/Foundation.h>

@class AMADatabaseSchemeMigration;
@protocol AMAApiKeyMigration;
@protocol AMADatabaseDataMigration;
@protocol AMALibraryMigration;

extern NSUInteger const kAMAConfigurationDatabaseSchemaVersion;
extern NSUInteger const kAMAReporterDatabaseSchemaVersion;
extern NSUInteger const kAMALocationDatabaseSchemaVersion;

typedef NS_ENUM(NSInteger, AMADatabaseContentType) {
    AMADatabaseContentTypeConfiguration,
    AMADatabaseContentTypeReporter,
    AMADatabaseContentTypeLocation
};

@interface AMADatabaseMigrationProvider : NSObject

- (instancetype)initWithContentType:(AMADatabaseContentType)contentType;

- (NSArray<AMADatabaseSchemeMigration *> *)schemeMigrations;
- (NSArray<id<AMAApiKeyMigration>> *)apiKeyMigrations;
- (NSArray<id<AMADatabaseDataMigration>> *)dataMigrationsWithAPIKey:(NSString *)apiKey
                                                               main:(BOOL)main;
- (NSArray<id<AMALibraryMigration>> *)libraryMigrations;

@end
