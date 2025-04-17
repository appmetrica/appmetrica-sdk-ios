
#import "AMAMigrationTo5100Utils.h"
#import <AppMetricaFMDB/AppMetricaFMDB.h>
#import "AMACore.h"
#import "AMADatabaseConstants.h"
#import "AMAReporterDatabaseMigrationTo5100EncodersFactory.h"
#import "AMAReporterDatabaseEncodersFactory.h"
#import "AMALocationEncoderFactory.h"
#import "AMALocationMigrationTo5100EncoderFactory.h"

@implementation AMAMigrationTo5100Utils

+ (void)migrateLocationTable:(NSString *)tableName
                 tableScheme:(NSArray *)tableScheme
                          db:(AMAFMDatabase *)db
{
    NSString *selectQuery = [NSString stringWithFormat:@"SELECT %@, %@ FROM %@;",
                             kAMACommonTableFieldOID,
                             kAMACommonTableFieldData,
                             tableName];
    
    AMAFMResultSet *resultSet = [db executeQuery:selectQuery];
    
    NSString *updateQuery = [NSString stringWithFormat:@"UPDATE %@ SET %@ = ? WHERE %@ = ?;",
                             tableName, kAMACommonTableFieldData, kAMACommonTableFieldOID];
    
    while ([resultSet next]) {
        NSData *columnValue = [resultSet objectForColumn:kAMACommonTableFieldData];
        
        NSData *migratedData = [self encodedLocationData:columnValue];
        
        NSNumber *rowID = @([resultSet intForColumn:kAMACommonTableFieldOID]);
        
        BOOL updateSuccess = [db executeUpdate:updateQuery withArgumentsInArray:@[migratedData ?: [NSNull null], rowID]];
        
        if (!updateSuccess) {
            AMALogWarn(@"Failed to update values in table at path: %@ error: %@",
                       db.databasePath, [db lastErrorMessage]);
        }
    }
    [resultSet close];
}


+ (void)migrateReporterTable:(NSString *)tableName
                 tableScheme:(NSArray *)tableScheme
                          db:(AMAFMDatabase *)db
{
    NSString *selectQuery = [NSString stringWithFormat:@"SELECT %@, %@, %@ FROM %@;",
                             kAMACommonTableFieldOID,
                             kAMACommonTableFieldDataEncryptionType,
                             kAMACommonTableFieldData,
                             tableName];
    
    AMAFMResultSet *resultSet = [db executeQuery:selectQuery];
    
    NSString *updateQuery = [NSString stringWithFormat:@"UPDATE %@ SET %@ = ? WHERE %@ = ?;",
                             tableName, kAMACommonTableFieldData, kAMACommonTableFieldOID];
    
    while ([resultSet next]) {
        NSNumber *encryptionValue = [resultSet objectForColumn:kAMACommonTableFieldDataEncryptionType];
        NSData *columnValue = [resultSet objectForColumn:kAMACommonTableFieldData];
        
        NSData *migratedData = [self encodedReporterData:columnValue encryptionValue:encryptionValue];
        
        NSNumber *rowID = @([resultSet intForColumn:kAMACommonTableFieldOID]);
        
        BOOL updateSuccess = [db executeUpdate:updateQuery withArgumentsInArray:@[migratedData ?: [NSNull null], rowID]];
        
        if (!updateSuccess) {
            AMALogWarn(@"Failed to update values in table at path: %@ error: %@",
                       db.databasePath, [db lastErrorMessage]);
        }
    }
    [resultSet close];
}

#pragma mark - Private -

+ (NSData *)encodedReporterData:(NSData *)data encryptionValue:(NSNumber *)encryptionValue
{
    AMAReporterDatabaseEncryptionType encryptionType = (AMAReporterDatabaseEncryptionType)[encryptionValue unsignedIntegerValue];
    
    id<AMAReporterDatabaseEncoderProviding> migrationEncoderFactory = [[AMAReporterDatabaseMigrationTo5100EncodersFactory alloc] init];
    id<AMADataEncoding> migrationEncoder = [migrationEncoderFactory encoderForEncryptionType:encryptionType];
    NSData *decodedWithOldEncrypterData = [migrationEncoder decodeData:data error:nil];
    
    id<AMAReporterDatabaseEncoderProviding> encoderFactory = [[AMAReporterDatabaseEncodersFactory alloc] init];
    id<AMADataEncoding> encoder = [encoderFactory encoderForEncryptionType:encryptionType];
    NSData *encodedWithNewEncrypterData = [encoder encodeData:decodedWithOldEncrypterData error:nil];
    
    return encodedWithNewEncrypterData;
}

+ (NSData *)encodedLocationData:(NSData *)data
{
    id<AMALocationEncoderProviding> migrationEncoderFactory = [[AMALocationMigrationTo5100EncoderFactory alloc] init];
    id<AMADataEncoding> migrationEncoder = [migrationEncoderFactory encoder];
    NSData *decodedWithOldEncrypterData = [migrationEncoder decodeData:data error:nil];
    
    id<AMALocationEncoderProviding> encoderFactory = [[AMALocationEncoderFactory alloc] init];
    id<AMADataEncoding> encoder = [encoderFactory encoder];
    NSData *encodedWithNewEncrypterData = [encoder encodeData:decodedWithOldEncrypterData error:nil];
    
    return encodedWithNewEncrypterData;
}

@end
