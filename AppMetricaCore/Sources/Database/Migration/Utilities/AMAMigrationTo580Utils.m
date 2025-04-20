
#import "AMAMigrationTo580Utils.h"
#import "AMATableDescriptionProvider.h"
#import "AMADatabaseProtocol.h"
#import "AMADatabaseConstants.h"
#import <AppMetricaFMDB/AppMetricaFMDB.h>
#import "AMADatabaseHelper.h"
#import "AMAEventNameHashesStorage.h"
#import "AMAEventNameHashesStorageFactory.h"

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

@end
