#import <XCTest/XCTest.h>
#import "AMADatabaseMigrationProvider.h"

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

#import "AMAReporterDatabaseSchemeMigrationTo2.h"
#import "AMALocationDatabaseSchemeMigrationTo2.h"

#import "AMADataMigrationTo500.h"
#import "AMADataMigrationTo580.h"
#import "AMADataMigrationTo590.h"
#import "AMADataMigrationTo5100.h"

#import "AMAReporterDataMigrationTo500.h"
#import "AMAReporterDataMigrationTo580.h"
#import "AMAReporterDataMigrationTo5100.h"

#import "AMALocationDataMigrationTo500.h"
#import "AMALocationDataMigrationTo5100.h"

#import "AMALibraryMigration320.h"

#import "AMAMigrationTo19FinalizationOnApiKeySpecified.h"

@interface AMADatabaseMigrationProviderTests : XCTestCase
@end

@implementation AMADatabaseMigrationProviderTests

- (void)testConfigurationSchemeMigrations
{
    AMADatabaseMigrationProvider *provider = [[AMADatabaseMigrationProvider alloc] initWithContentType:AMADatabaseContentTypeConfiguration];
    NSArray *migrations = [provider schemeMigrations];
    XCTAssertEqual(migrations.count, 19);
    XCTAssertTrue([[migrations[0] class] isSubclassOfClass:[AMAConfigurationDatabaseSchemeMigrationTo2 class]]);
    XCTAssertTrue([[migrations[1] class] isSubclassOfClass:[AMAConfigurationDatabaseSchemeMigrationTo3 class]]);
    XCTAssertTrue([[migrations[2] class] isSubclassOfClass:[AMAConfigurationDatabaseSchemeMigrationTo4 class]]);
    XCTAssertTrue([[migrations[3] class] isSubclassOfClass:[AMAConfigurationDatabaseSchemeMigrationTo5 class]]);
    XCTAssertTrue([[migrations[4] class] isSubclassOfClass:[AMAConfigurationDatabaseSchemeMigrationTo6 class]]);
    XCTAssertTrue([[migrations[5] class] isSubclassOfClass:[AMAConfigurationDatabaseSchemeMigrationTo7 class]]);
    XCTAssertTrue([[migrations[6] class] isSubclassOfClass:[AMAConfigurationDatabaseSchemeMigrationTo8 class]]);
    XCTAssertTrue([[migrations[7] class] isSubclassOfClass:[AMAConfigurationDatabaseSchemeMigrationTo9 class]]);
    XCTAssertTrue([[migrations[8] class] isSubclassOfClass:[AMAConfigurationDatabaseSchemeMigrationTo10 class]]);
    XCTAssertTrue([[migrations[9] class] isSubclassOfClass:[AMAConfigurationDatabaseSchemeMigrationTo11 class]]);
    XCTAssertTrue([[migrations[10] class] isSubclassOfClass:[AMAConfigurationDatabaseSchemeMigrationTo12 class]]);
    XCTAssertTrue([[migrations[11] class] isSubclassOfClass:[AMAConfigurationDatabaseSchemeMigrationTo13 class]]);
    XCTAssertTrue([[migrations[12] class] isSubclassOfClass:[AMAConfigurationDatabaseSchemeMigrationTo14 class]]);
    XCTAssertTrue([[migrations[13] class] isSubclassOfClass:[AMAConfigurationDatabaseSchemeMigrationTo15 class]]);
    XCTAssertTrue([[migrations[14] class] isSubclassOfClass:[AMAConfigurationDatabaseSchemeMigrationTo16 class]]);
    XCTAssertTrue([[migrations[15] class] isSubclassOfClass:[AMAConfigurationDatabaseSchemeMigrationTo17 class]]);
    XCTAssertTrue([[migrations[16] class] isSubclassOfClass:[AMAConfigurationDatabaseSchemeMigrationTo18 class]]);
    XCTAssertTrue([[migrations[17] class] isSubclassOfClass:[AMAConfigurationDatabaseSchemeMigrationTo19 class]]);
    XCTAssertTrue([[migrations[18] class] isSubclassOfClass:[AMAConfigurationDatabaseSchemeMigrationTo20 class]]);
}

- (void)testConfigurationDataMigrations
{
    AMADatabaseMigrationProvider *provider = [[AMADatabaseMigrationProvider alloc] initWithContentType:AMADatabaseContentTypeConfiguration];
    NSArray *migrations = [provider dataMigrationsWithAPIKey:nil main:YES];
    XCTAssertEqual(migrations.count, 4);
    XCTAssertTrue([[migrations[0] class] isSubclassOfClass:[AMADataMigrationTo500 class]]);
    XCTAssertTrue([[migrations[1] class] isSubclassOfClass:[AMADataMigrationTo580 class]]);
    XCTAssertTrue([[migrations[2] class] isSubclassOfClass:[AMADataMigrationTo590 class]]);
    XCTAssertTrue([[migrations[3] class] isSubclassOfClass:[AMADataMigrationTo5100 class]]);
}

- (void)testConfigurationApiKeyMigrations
{
    AMADatabaseMigrationProvider *provider = [[AMADatabaseMigrationProvider alloc] initWithContentType:AMADatabaseContentTypeConfiguration];
    NSArray *migrations = [provider apiKeyMigrations];
    XCTAssertEqual(migrations.count, 1);
    XCTAssertTrue([[migrations[0] class] isSubclassOfClass:[AMAMigrationTo19FinalizationOnApiKeySpecified class]]);
}

- (void)testDefaultConfigurationMigrations
{
    AMADatabaseMigrationProvider *defaultProvider = [[AMADatabaseMigrationProvider alloc] init];
    NSArray *defaultMigrations = [defaultProvider schemeMigrations];
    AMADatabaseMigrationProvider *provider = [[AMADatabaseMigrationProvider alloc] initWithContentType:AMADatabaseContentTypeConfiguration];
    NSArray *migrations = [provider schemeMigrations];
    XCTAssertEqual(defaultMigrations.count, migrations.count);
}

- (void)testConfigurationLibraryMigrations
{
    AMADatabaseMigrationProvider *provider = [[AMADatabaseMigrationProvider alloc] initWithContentType:AMADatabaseContentTypeConfiguration];
    NSArray *migrations = [provider libraryMigrations];
    XCTAssertEqual(migrations.count, 1);
    XCTAssertTrue([[migrations[0] class] isSubclassOfClass:[AMALibraryMigration320 class]]);
}

- (void)testReporterSchemeMigrations
{
    AMADatabaseMigrationProvider *provider = [[AMADatabaseMigrationProvider alloc] initWithContentType:AMADatabaseContentTypeReporter];
    NSArray *migrations = [provider schemeMigrations];
    XCTAssertEqual(migrations.count, 1);
    XCTAssertTrue([[migrations[0] class] isSubclassOfClass:[AMAReporterDatabaseSchemeMigrationTo2 class]]);
}

- (void)testReporterDataMigrations
{
    AMADatabaseMigrationProvider *provider = [[AMADatabaseMigrationProvider alloc] initWithContentType:AMADatabaseContentTypeReporter];
    NSArray *migrations = [provider dataMigrationsWithAPIKey:nil main:YES];
    XCTAssertEqual(migrations.count, 3);
    XCTAssertTrue([[migrations[0] class] isSubclassOfClass:[AMAReporterDataMigrationTo500 class]]);
    XCTAssertTrue([[migrations[1] class] isSubclassOfClass:[AMAReporterDataMigrationTo580 class]]);
    XCTAssertTrue([[migrations[2] class] isSubclassOfClass:[AMAReporterDataMigrationTo5100 class]]);
}

- (void)testReporterApiKeyMigrationsEmpty
{
    AMADatabaseMigrationProvider *provider = [[AMADatabaseMigrationProvider alloc] initWithContentType:AMADatabaseContentTypeReporter];
    NSArray *result = [provider apiKeyMigrations];
    XCTAssertEqual(result.count, 0);
}

- (void)testReporterLibraryMigrationsEmpty
{
    AMADatabaseMigrationProvider *provider = [[AMADatabaseMigrationProvider alloc] initWithContentType:AMADatabaseContentTypeReporter];
    NSArray *result = [provider libraryMigrations];
    XCTAssertEqual(result.count, 0);
}

- (void)testLocationSchemeMigrations
{
    AMADatabaseMigrationProvider *provider = [[AMADatabaseMigrationProvider alloc] initWithContentType:AMADatabaseContentTypeLocation];
    NSArray *migrations = [provider schemeMigrations];
    XCTAssertEqual(migrations.count, 1);
    XCTAssertTrue([[migrations[0] class] isSubclassOfClass:[AMALocationDatabaseSchemeMigrationTo2 class]]);
}

- (void)testLocationDataMigrations
{
    AMADatabaseMigrationProvider *provider = [[AMADatabaseMigrationProvider alloc] initWithContentType:AMADatabaseContentTypeLocation];
    NSArray *migrations = [provider dataMigrationsWithAPIKey:nil main:NO];
    XCTAssertEqual(migrations.count, 2);
    XCTAssertTrue([[migrations[0] class] isSubclassOfClass:[AMALocationDataMigrationTo500 class]]);
    XCTAssertTrue([[migrations[1] class] isSubclassOfClass:[AMALocationDataMigrationTo5100 class]]);
}

- (void)testLocationApiKeyMigrationsEmpty
{
    AMADatabaseMigrationProvider *provider = [[AMADatabaseMigrationProvider alloc] initWithContentType:AMADatabaseContentTypeLocation];
    NSArray *result = [provider apiKeyMigrations];
    XCTAssertEqual(result.count, 0);
}

- (void)testLocationLibraryMigrationsEmpty
{
    AMADatabaseMigrationProvider *provider = [[AMADatabaseMigrationProvider alloc] initWithContentType:AMADatabaseContentTypeLocation];
    NSArray *result = [provider libraryMigrations];
    XCTAssertEqual(result.count, 0);
}

@end
