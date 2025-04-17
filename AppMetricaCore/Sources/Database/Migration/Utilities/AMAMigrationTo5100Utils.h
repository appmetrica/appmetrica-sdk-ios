
#import <Foundation/Foundation.h>

@class AMAFMDatabase;

@interface AMAMigrationTo5100Utils : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (void)migrateLocationTable:(NSString *)tableName
                 tableScheme:(NSArray *)tableScheme
                          db:(AMAFMDatabase *)db;

+ (void)migrateReporterTable:(NSString *)tableName
                 tableScheme:(NSArray *)tableScheme
                          db:(AMAFMDatabase *)db;

@end
