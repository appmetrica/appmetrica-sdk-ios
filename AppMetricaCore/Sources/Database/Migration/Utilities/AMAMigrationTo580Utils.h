
#import <Foundation/Foundation.h>

@class AMAFMDatabase;

@interface AMAMigrationTo580Utils : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (void)migrateTable:(NSString *)tableName
         tableScheme:(NSArray *)tableScheme
            sourceDB:(AMAFMDatabase *)sourceDB
       destinationDB:(AMAFMDatabase *)destinationDB;

+ (void)migrateReporterEventHashes:(NSString *)apiKey;

@end
