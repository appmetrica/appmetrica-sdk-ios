
#import <Foundation/Foundation.h>
#import <Kiwi/Kiwi.h>
#import "AMAAppMetricaUUIDMigrator.h"
#import "AMAInstantFeaturesConfiguration+Migration.h"
#import "AMAMetricaConfiguration.h"
#import "AMADatabaseFactory.h"
#import "AMACore.h"

SPEC_BEGIN(AMAAppMetricaUUIDMigratorTests)

describe(@"AMAAppMetricaUUIDMigratorTests", ^{

    NSString *oldUUIDDatabasePath = @"some/path";
    AMAAppMetricaUUIDMigrator *__block provider;
    beforeEach(^{
        provider = [[AMAAppMetricaUUIDMigrator alloc] init];
    });
    context(@"Shared instance", ^{
        beforeEach(^{
            provider = [AMAAppMetricaUUIDMigrator new];
        });
        it (@"Should not be nil", ^{
            [[provider shouldNot] beNil];
        });
    });
    context(@"Retrieve UUID", ^{
        AMAInstantFeaturesConfiguration *__block instantConfiguration = nil;
        AMAInstantFeaturesConfiguration *__block migrationInstantConfiguration = nil;
        id __block uuidOldStorage = nil;
        AMAMetricaConfiguration *__block configuration;
        beforeEach(^{
            configuration = [AMAMetricaConfiguration nullMock];
            instantConfiguration = [AMAInstantFeaturesConfiguration nullMock];
            migrationInstantConfiguration = [AMAInstantFeaturesConfiguration nullMock];
            uuidOldStorage = [KWMock nullMockForProtocol:@protocol(AMAKeyValueStoring)];
            [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:configuration];
            [AMAInstantFeaturesConfiguration stub:@selector(sharedInstance) andReturn:instantConfiguration];
            [AMAInstantFeaturesConfiguration stub:@selector(migrationInstance) andReturn:migrationInstantConfiguration];
            [configuration stub:@selector(UUIDOldStorage) andReturn:uuidOldStorage];
            [AMADatabaseFactory stub:@selector(configurationDatabasePath) andReturn:oldUUIDDatabasePath];
        });

        context(@"No cached UUID", ^{
            context(@"Has UUID in instant configuration", ^{
                NSString *UUIDFromInstant = @"uuid from instant";
                beforeEach(^{
                    [instantConfiguration stub:@selector(UUID) andReturn:UUIDFromInstant];
                });
                it(@"Should return valid uuid", ^{
                    [[provider.migrateAppMetricaUUID should] equal:UUIDFromInstant];
                });
                it(@"Should not check old database existence", ^{
                    [[AMADatabaseFactory shouldNot] receive:@selector(configurationDatabasePath)];
                    [provider migrateAppMetricaUUID];
                });
                it(@"Should not check old database", ^{
                    [[configuration shouldNot] receive:@selector(UUIDOldStorage)];
                    [[uuidOldStorage shouldNot] receive:@selector(stringForKey:error:)];
                    [provider migrateAppMetricaUUID];
                });
            });
            context(@"No UUID in instant configuration", ^{
                beforeEach(^{
                    [instantConfiguration stub:@selector(UUID) andReturn:@""];
                });
                it(@"Should use right path", ^{
                    [[AMAFileUtility should] receive:@selector(fileExistsAtPath:) withArguments:oldUUIDDatabasePath];
                    [provider migrateAppMetricaUUID];
                });
                context(@"Old database does not exist", ^{
                    beforeEach(^{
                        [AMAFileUtility stub:@selector(fileExistsAtPath:) andReturn:theValue(NO)];
                    });
                    it(@"Should not check old database", ^{
                        [[configuration shouldNot] receive:@selector(UUIDOldStorage)];
                        [[uuidOldStorage shouldNot] receive:@selector(stringForKey:error:)];
                        [provider migrateAppMetricaUUID];
                    });
                });
                context(@"Old database exists", ^{
                    beforeEach(^{
                        [AMAFileUtility stub:@selector(fileExistsAtPath:) andReturn:theValue(YES)];
                    });
                    it(@"Should check old database", ^{
                        [[configuration should] receive:@selector(UUIDOldStorage)];
                        [[uuidOldStorage should] receive:@selector(stringForKey:error:) withArguments:@"uuid", kw_any()];
                        [provider migrateAppMetricaUUID];
                    });
                    context(@"Has UUID in old storage", ^{
                        NSString *uuidFromOldStorage = @"uuid from old storage";
                        beforeEach(^{
                            [uuidOldStorage stub:@selector(stringForKey:error:) andReturn:uuidFromOldStorage];
                        });
                        it(@"Should return valid UUID", ^{
                            [[provider.migrateAppMetricaUUID should] equal:uuidFromOldStorage];
                        });
                    });
                    context(@"No UUID in old storage", ^{
                        beforeEach(^{
                            [uuidOldStorage stub:@selector(stringForKey:error:) andReturn:@""];
                        });
                        
                        context(@"UUID in old instant configuration", ^{
                            NSString *const migrationUuid = @"migration_uuid";
                            beforeEach(^{
                                [migrationInstantConfiguration stub:@selector(UUID) andReturn:migrationUuid];
                            });
                            it(@"Should return migration uuid", ^{
                                [[provider.migrateAppMetricaUUID should] equal:migrationUuid];
                            });
                        });
                    });
                });
            });
        });
    });

});

SPEC_END
