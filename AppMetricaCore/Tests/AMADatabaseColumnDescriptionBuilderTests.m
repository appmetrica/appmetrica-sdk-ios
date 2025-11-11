
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMADatabaseColumnDescriptionBuilder.h"


SPEC_BEGIN(AMADatabaseColumnDescriptionBuilderTests)

describe(@"AMADatabaseColumnDescriptionBuilder", ^{
    it(@"Should fail if nothing supplied", ^{
        [[theBlock(^{
            AMADatabaseColumnDescriptionBuilder *builder = [[AMADatabaseColumnDescriptionBuilder alloc] init];
            [builder buildSQL];
        }) should] raise];
    });

    it(@"Should fail if no name supplied", ^{
        [[theBlock(^{
            AMADatabaseColumnDescriptionBuilder *builder = [[AMADatabaseColumnDescriptionBuilder alloc] init];
            [[builder addType:@"type"] addDefaultValue:@"def"];
            [builder buildSQL];
        }) should] raise];
    });

    it(@"Should fail if no type supplied", ^{
        [[theBlock(^{
            AMADatabaseColumnDescriptionBuilder *builder = [[AMADatabaseColumnDescriptionBuilder alloc] init];
            [[builder addName:@"type"] addDefaultValue:@"def"];
            [builder buildSQL];
        }) should] raise];
    });

    it(@"Should not fail if name and type supplied", ^{
        AMADatabaseColumnDescriptionBuilder *builder = [[AMADatabaseColumnDescriptionBuilder alloc] init];
        [[builder addName:@"latitude"] addType:@"DOUBLE"];
        NSString *sql = [builder buildSQL];
        [[sql should] equal:@"latitude DOUBLE"];
    });

    it(@"Should build correct field with type, name and default filled", ^{
        AMADatabaseColumnDescriptionBuilder *builder = [[AMADatabaseColumnDescriptionBuilder alloc] init];
        [[[builder addName:@"latitude"] addType:@"DOUBLE"] addDefaultValue:@"0"];
        NSString *sql = [builder buildSQL];
        [[sql should] equal:@"latitude DOUBLE DEFAULT 0"];
    });

    it(@"Should build correct with type name and not null ", ^{
        AMADatabaseColumnDescriptionBuilder *builder = [[AMADatabaseColumnDescriptionBuilder alloc] init];
        [[[builder addName:@"latitude"] addType:@"DOUBLE"] addIsNotNull:YES];
        NSString *sql = [builder buildSQL];
        [[sql should] equal:@"latitude DOUBLE NOT NULL"];
    });

    it(@"Should build correct with type name and not null ", ^{
        AMADatabaseColumnDescriptionBuilder *builder = [[AMADatabaseColumnDescriptionBuilder alloc] init];
        [[[builder addName:@"latitude"] addType:@"DOUBLE"] addIsNotNull:NO];
        NSString *sql = [builder buildSQL];
        [[sql should] equal:@"latitude DOUBLE"];
    });

    it(@"Should build correct with type name and primary key ", ^{
        AMADatabaseColumnDescriptionBuilder *builder = [[AMADatabaseColumnDescriptionBuilder alloc] init];
        [[[builder addName:@"latitude"] addType:@"DOUBLE"] addIsPrimaryKey:YES];
        NSString *sql = [builder buildSQL];
        [[sql should] equal:@"latitude DOUBLE PRIMARY KEY"];
    });

    it(@"Should build correct with type name and primary key ", ^{
        AMADatabaseColumnDescriptionBuilder *builder = [[AMADatabaseColumnDescriptionBuilder alloc] init];
        [[[builder addName:@"latitude"] addType:@"DOUBLE"] addIsPrimaryKey:NO];
        NSString *sql = [builder buildSQL];
        [[sql should] equal:@"latitude DOUBLE"];
    });

    it(@"Should build correct with type name and primary key autoincrement ", ^{
        AMADatabaseColumnDescriptionBuilder *builder = [[AMADatabaseColumnDescriptionBuilder alloc] init];
        [[[[builder addName:@"latitude"] addType:@"DOUBLE"] addIsPrimaryKey:YES] addIsAutoincrement:YES];
        NSString *sql = [builder buildSQL];
        [[sql should] equal:@"latitude DOUBLE PRIMARY KEY AUTOINCREMENT"];
    });

    it(@"Should build correct with type name and no primary key and autoincrement ", ^{
        AMADatabaseColumnDescriptionBuilder *builder = [[AMADatabaseColumnDescriptionBuilder alloc] init];
        [[[builder addName:@"latitude"] addType:@"DOUBLE"] addIsPrimaryKey:NO];
        NSString *sql = [builder buildSQL];
        [[sql should] equal:@"latitude DOUBLE"];
    });

    it(@"Should build correct with type name and primary key and autoincrement and default value ", ^{
        AMADatabaseColumnDescriptionBuilder *builder = [[AMADatabaseColumnDescriptionBuilder alloc] init];
        [[[[[builder addName:@"latitude"] addType:@"DOUBLE"] addIsPrimaryKey:YES] addIsAutoincrement:YES] addDefaultValue:@"1"];
        NSString *sql = [builder buildSQL];
        [[sql should] equal:@"latitude DOUBLE DEFAULT 1 PRIMARY KEY AUTOINCREMENT"];
    });

    it(@"Should build correct with type name and not null and default value ", ^{
        AMADatabaseColumnDescriptionBuilder *builder = [[AMADatabaseColumnDescriptionBuilder alloc] init];
        [[[[builder addName:@"latitude"] addType:@"DOUBLE"] addIsNotNull:YES] addDefaultValue:@"1"];
        NSString *sql = [builder buildSQL];
        [[sql should] equal:@"latitude DOUBLE NOT NULL DEFAULT 1"];
    });

    it(@"Should build with default value bool", ^{
        AMADatabaseColumnDescriptionBuilder *builder = [[AMADatabaseColumnDescriptionBuilder alloc] init];
        [[[[builder addName:@"finished"] addType:@"BOOL"] addIsNotNull:YES] addDefaultValue:@(YES)];
        NSString *sql = [builder buildSQL];
        [[sql should] equal:@"finished BOOL NOT NULL DEFAULT 1"];
    });

});

SPEC_END
