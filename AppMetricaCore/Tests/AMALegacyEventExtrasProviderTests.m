
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMALegacyEventExtrasProvider.h"
#import <AppMetricaFMDB/AppMetricaFMDB.h>
#import <AppMetricaProtobufUtils/AppMetricaProtobufUtils.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMAMigrationTo500Utils.h"
#import "LegacyEventExtras.pb-c.h"

SPEC_BEGIN(AMALegacyEventExtrasProviderTests)

describe(@"AMALegacyEventExtrasProvider", ^{
    
    NSDictionary *const extrasValue = @{@"user_id":@"user id",
                                        @"type":@"user type",
                                        @"options":@{@"key":@"value"}};
    AMAFMDatabase *__block db = nil;
    
    beforeEach(^{
        // In memory database
        db = [AMAFMDatabase databaseWithPath:NULL];
        [db open];
        
        NSString *createTableQuery = @"CREATE TABLE IF NOT EXISTS kv ("
                                     @"k TEXT PRIMARY KEY NOT NULL, "
                                     @"v BLOB NOT NULL)";
        [db executeUpdate:createTableQuery];
        
        NSString *insertQuery = @"INSERT INTO kv (k, v) VALUES (?, ?);";
        [db executeUpdate:insertQuery, @"user_info", [AMAJSONSerialization stringWithJSONObject:extrasValue error:nil]];
    });
    
    afterEach(^{
        [db close];
    });
    
    context(@"Legacy extras", ^{
        it(@"Should select and pack legacy extras", ^{
            AMAProtobufAllocator *allocator = [[AMAProtobufAllocator alloc] init];
            
            NSData *result = [AMALegacyEventExtrasProvider legacyExtrasData:db];
            Ama__LegacyEventExtras *extrasData = NULL;
            
            extrasData = ama__legacy_event_extras__unpack(allocator.protobufCAllocator,
                                                          result.length,
                                                          result.bytes);
            
            NSString *userID = [NSString stringWithUTF8String:extrasData->id];
            NSString *type = [NSString stringWithUTF8String:extrasData->type];
            NSString *optionsString = [NSString stringWithUTF8String:extrasData->options];
            NSDictionary *options = [AMAJSONSerialization dictionaryWithJSONString:optionsString
                                                                     error:nil];
            
            [[userID should] equal:extrasValue[@"user_id"]];
            [[type should] equal:extrasValue[@"type"]];
            [[options should] equal:extrasValue[@"options"]];
        });
    });
    
});

SPEC_END
