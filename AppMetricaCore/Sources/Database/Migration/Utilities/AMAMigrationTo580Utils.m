
#import "AMAMigrationTo580Utils.h"
#import "AMATableDescriptionProvider.h"
#import "AMADatabaseProtocol.h"
#import "AMADatabaseConstants.h"
#import <AppMetricaFMDB/AppMetricaFMDB.h>
#import "AMADatabaseHelper.h"
#import "AMAReporterStoragesContainer.h"
#import "AMAReporterStorage.h"
#import "AMAEventNameHashesStorage.h"
#import "AMAEventStorage+Migration.h"
#import "AMAEventSerializer.h"
#import "AMAEventNameHashesStorageFactory.h"
#import "AMAEventSerializer+Migration.h"

@implementation AMAMigrationTo580Utils

+ (void)migrateTable:(NSString *)tableName
         tableScheme:(NSArray *)tableScheme
            sourceDB:(AMAFMDatabase *)sourceDB
       destinationDB:(AMAFMDatabase *)destinationDB
{
    NSMutableArray *columns = [NSMutableArray array];
    NSMutableArray *valueQuestions = [NSMutableArray array];
    for (NSDictionary *field in tableScheme) {
        [columns addObject:field[kAMASQLName]];
        [valueQuestions addObject:@"?"];
    }
    NSString *joined = [columns componentsJoinedByString:@", "];
    NSString *selectQuery = [NSString stringWithFormat:@"SELECT %@ FROM %@;", joined, tableName];
    AMAFMResultSet *resultSet = [sourceDB executeQuery:selectQuery];
    
    NSString *insertQuery = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@);",
                             tableName, joined, [valueQuestions componentsJoinedByString:@", "]];
    
    while ([resultSet next]) {
        
        NSMutableArray *columnValues = [NSMutableArray array];
        for (NSString *columnName in columns) {
            id columnValue = [resultSet objectForColumn:columnName];
            
            [columnValues addObject:(columnValue ?: [NSNull null])];
        }
        
        BOOL insertSuccess = [destinationDB executeUpdate:insertQuery withArgumentsInArray:columnValues];
        if (insertSuccess == NO) {
            AMALogWarn(@"Failed to insert values into table at path: %@ error: %@",
                       destinationDB.databasePath, [destinationDB lastErrorMessage]);
        }
    }
    [resultSet close];
}

+ (void)migrateReporterEvents:(AMAFMDatabase *)sourceDB
                destinationDB:(AMAFMDatabase *)destinationDB
                       apiKey:(NSString *)apiKey
{
    AMAEventSerializer *serializer = [[AMAEventSerializer alloc] migrationTo5100Init];
    NSArray<AMAEvent*> *reporterEvents = [self getEventsInDB:sourceDB eventSerializer:serializer];
    
    [self saveReporterEvents:reporterEvents apiKey:apiKey db:destinationDB];
}

+ (void)migrateReporterEventHashes:(NSString *)apiKey
{
    AMAEventNameHashesStorage *migrationStorage = [AMAEventNameHashesStorageFactory storageForApiKey:apiKey main:NO];
    AMAEventNameHashesStorage *currentStorage = [AMAEventNameHashesStorageFactory storageForApiKey:apiKey main:YES];
    AMAEventNameHashesCollection *oldCollection = [migrationStorage loadCollection];
    BOOL result = [currentStorage saveCollection:oldCollection];
    if (result == NO) {
        AMALogError(@"Failed to save event hashes collection for apiKey: %@", apiKey);
    }
}

#pragma mark - Events Migration -

+ (NSArray<AMAEvent*> *)getEventsInDB:(AMAFMDatabase *)db
                      eventSerializer:(AMAEventSerializer *)eventSerializer
{
    NSMutableArray *result = [NSMutableArray array];
    NSError *error = nil;
    [AMADatabaseHelper enumerateRowsWithFilter:nil
                                         order:nil
                                   valuesArray:@[]
                                     tableName:kAMAEventTableName
                                         limit:INT_MAX
                                            db:db
                                         error:&error
                                         block:^(NSDictionary *dictionary) {
        NSError *deserializationError = nil;
        AMAEvent *event = [eventSerializer eventForDictionary:dictionary error:&deserializationError];
        if (deserializationError != nil) {
            AMALogInfo(@"Deserialization error: %@", deserializationError);
        }
        else if (event != nil) {
            [result addObject:event];
        }
    }];
    if (error != nil) {
        AMALogInfo(@"Error: %@", error);
    }
    return [result copy];
}

+ (BOOL)saveReporterEvents:(NSArray<AMAEvent*> *)events
                    apiKey:(NSString *)apiKey
                        db:(AMAFMDatabase *)db
{
    AMAEventSerializer *eventSerializer = [[AMAEventSerializer alloc] migrationTo5100Init];
    
    BOOL __block result = NO;
    for (AMAEvent *event in events) {
        NSDictionary *eventDictionary = [eventSerializer dictionaryForEvent:event error:nil];
        if (eventDictionary == nil) {
            return NO;
        }
        
        NSNumber *eventOID = [AMADatabaseHelper insertRowWithDictionary:eventDictionary
                                                              tableName:kAMAEventTableName
                                                                     db:db
                                                                  error:nil];
        result = result && eventOID != nil;
    }
    return result;
}

@end
