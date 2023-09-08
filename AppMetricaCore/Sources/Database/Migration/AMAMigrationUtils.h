
#import <Foundation/Foundation.h>

@class FMDatabase;
@protocol AMADatabaseProtocol;

@interface AMAMigrationUtils : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (BOOL)addLocationToTable:(NSString *)tableName inDatabase:(FMDatabase *)db;
+ (BOOL)addServerTimeOffsetToSessionsTableInDatabase:(FMDatabase *)db;
+ (BOOL)addErrorEnvironmentToEventsAndErrorsTableInDatabase:(FMDatabase *)db;
+ (BOOL)addAppEnvironmentToEventsAndErrorsTableInDatabase:(FMDatabase *)db;
+ (BOOL)addTruncatedToEventsAndErrorsTableInDatabase:(FMDatabase *)db;
+ (BOOL)addUserInfoInDatabase:(FMDatabase *)db;
+ (BOOL)addLocationEnabledInDatabase:(FMDatabase *)db;
+ (BOOL)addUserProfileIDInDatabase:(FMDatabase *)db;
+ (BOOL)addEncryptionTypeInDatabase:(FMDatabase *)db;
+ (BOOL)addFirstOccurrenceInDatabase:(FMDatabase *)db;
+ (BOOL)addAttributionIDInDatabase:(FMDatabase *)db;
+ (BOOL)addGlobalEventNumberInDatabase:(FMDatabase *)db;
+ (BOOL)addEventNumberOfTypeInDatabase:(FMDatabase *)db;

+ (BOOL)updateColumnTypes:(NSString *)columnTypesDescription ofKeyValueTable:(NSString *)tableName db:(FMDatabase *)db;

+ (void)resetStartupUpdatedAtToDistantPastInDatabase:(id<AMADatabaseProtocol>)database db:(FMDatabase *)db;

@end
