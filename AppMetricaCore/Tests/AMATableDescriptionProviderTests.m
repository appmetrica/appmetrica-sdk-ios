
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMATableDescriptionProvider.h"

SPEC_BEGIN(AMATableDescriptionProviderTests)

describe(@"AMATableDescriptionProvider", ^{
    it(@"Should provide valid events table", ^{
        NSArray *eventsTable = [AMATableDescriptionProvider eventsTableMetaInfo];
        NSArray *expectedTable = @[
            @{kAMASQLName: @"id", kAMASQLType: @"INTEGER", kAMASQLIsNotNull: @YES, kAMASQLIsPrimaryKey: @YES, kAMASQLIsAutoincrement: @YES},
            @{kAMASQLName: @"session_oid", kAMASQLType: @"INTEGER", kAMASQLIsNotNull: @YES},
            @{kAMASQLName: @"created_at", kAMASQLType: @"DOUBLE", kAMASQLIsNotNull: @YES},
            @{kAMASQLName: @"sequence_number", kAMASQLType: @"INTEGER", kAMASQLIsNotNull: @YES},
            @{kAMASQLName: @"type", kAMASQLType: @"INTEGER", kAMASQLIsNotNull: @YES},
            @{kAMASQLName: @"data_encryption_type", kAMASQLType: @"INTEGER"},
            @{kAMASQLName: @"data", kAMASQLType: @"BLOB", kAMASQLIsNotNull: @YES },
        ];
        [[eventsTable should] equal:expectedTable];
    });

    it(@"Should provide valid sessions table", ^{
        NSArray *sessionTable = [AMATableDescriptionProvider sessionsTableMetaInfo];
        NSArray *expectedTable = @[
            @{kAMASQLName: @"id", kAMASQLType: @"INTEGER", kAMASQLIsNotNull: @YES, kAMASQLIsPrimaryKey: @YES, kAMASQLIsAutoincrement: @YES},
            @{kAMASQLName: @"start_time", kAMASQLType: @"DOUBLE", kAMASQLIsNotNull: @YES},
            @{kAMASQLName: @"type", kAMASQLType: @"INTEGER", kAMASQLIsNotNull: @YES},
            @{kAMASQLName: @"finished", kAMASQLType: @"BOOL", kAMASQLIsNotNull: @YES, kAMASQLDefaultValue: @NO},
            @{kAMASQLName: @"last_event_time", kAMASQLType: @"DOUBLE" },
            @{kAMASQLName: @"pause_time", kAMASQLType: @"DOUBLE", kAMASQLIsNotNull: @YES},
            @{kAMASQLName: @"event_seq", kAMASQLType: @"INTEGER", kAMASQLIsNotNull: @YES, kAMASQLDefaultValue: @"0"},
            @{kAMASQLName: @"data_encryption_type", kAMASQLType: @"INTEGER"},
            @{kAMASQLName: @"data", kAMASQLType: @"BLOB", kAMASQLIsNotNull: @YES},
        ];
        [[sessionTable should] equal:expectedTable];
    });

    it(@"Should provide valid locations table", ^{
        NSArray *locationsTable = [AMATableDescriptionProvider locationsTableMetaInfo];
        NSArray *expectedTable = @[
            @{kAMASQLName: @"id", kAMASQLType: @"INTEGER", kAMASQLIsNotNull: @YES, kAMASQLIsPrimaryKey: @YES},
            @{kAMASQLName: @"timestamp", kAMASQLType: @"DOUBLE", kAMASQLIsNotNull: @YES},
            @{kAMASQLName: @"data", kAMASQLType: @"BLOB", kAMASQLIsNotNull: @YES },
        ];
        [[locationsTable should] equal:expectedTable];
    });
         
    it(@"Should provide valid visits table", ^{
        NSArray *visitsTable = [AMATableDescriptionProvider visitsTableMetaInfo];
        NSArray *expectedTable = @[
            @{kAMASQLName: @"id", kAMASQLType: @"INTEGER", kAMASQLIsNotNull: @YES, kAMASQLIsPrimaryKey: @YES},
            @{kAMASQLName: @"timestamp", kAMASQLType: @"DOUBLE", kAMASQLIsNotNull: @YES},
            @{kAMASQLName: @"data", kAMASQLType: @"BLOB", kAMASQLIsNotNull: @YES },
        ];
        [[visitsTable should] equal:expectedTable];
    });

    it(@"Should provide valid binary kv table", ^{
        NSArray *kvTable = [AMATableDescriptionProvider binaryKVTableMetaInfo];
        NSArray *expectedTable = @[
            @{kAMASQLName: @"k", kAMASQLType: @"TEXT", kAMASQLIsNotNull: @YES, kAMASQLIsPrimaryKey: @YES},
            @{kAMASQLName: @"v", kAMASQLType: @"BLOB"},
        ];
        [[kvTable should] equal:expectedTable];
    });

    it(@"Should provide valid string kv table", ^{
        NSArray *kvTable = [AMATableDescriptionProvider stringKVTableMetaInfo];
        NSArray *expectedTable = @[
            @{kAMASQLName: @"k", kAMASQLType: @"TEXT", kAMASQLIsNotNull: @YES, kAMASQLIsPrimaryKey: @YES},
            @{kAMASQLName: @"v", kAMASQLType: @"TEXT", kAMASQLIsNotNull: @YES, kAMASQLDefaultValue : @"''"},
        ];
        [[kvTable should] equal:expectedTable];
    });
});

SPEC_END
