#import <XCTest/XCTest.h>
#import <Kiwi/Kiwi.h>
#import "AMADataMigrationTo5140.h"
#import "AMADatabaseProtocol.h"
#import "AMADatabaseQueryRecorderMock.h"
#import <AppMetricaFMDB/AppMetricaFMDB.h>

SPEC_BEGIN(AMADataMigrationTo5140Tests)

describe(@"AMADataMigrationTo5140", ^{
    
    AMADataMigrationTo5140 *__block databaseMigration;
    AMADatabaseQueryRecorderMock *__block database;
    
    beforeEach(^{
        databaseMigration = [AMADataMigrationTo5140 new];
        database = [AMADatabaseQueryRecorderMock new];
    });
    
    context(@"Check migration", ^{
        it(@"should execute query", ^{
            [databaseMigration applyMigrationToDatabase:database];
            [[database.executedStatements should] equal:@[@"PRAGMA auto_vacuum=FULL; PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL; VACUUM;"]];
        });
        
        it(@"Should return migrationKey", ^{
            [[[databaseMigration migrationKey] should] equal: @"5.14.0.migration.applied"];
        });
    });
    
});

SPEC_END
