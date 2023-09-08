
#import <Foundation/Foundation.h>

@class FMDatabase;

NS_ASSUME_NONNULL_BEGIN

@interface AMADatabaseSchemeMigration : NSObject

- (NSUInteger)schemeVersion;
- (BOOL)applyTransactionalMigrationToDatabase:(FMDatabase *)db;

@end

NS_ASSUME_NONNULL_END
