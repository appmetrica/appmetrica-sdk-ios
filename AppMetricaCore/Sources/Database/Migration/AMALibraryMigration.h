
#import <Foundation/Foundation.h>

@class FMDatabase;
@protocol AMADatabaseProtocol;

@protocol AMALibraryMigration <NSObject>

@property (nonatomic, copy, readonly) NSString *version;

- (void)applyMigrationToDatabase:(id<AMADatabaseProtocol>)database db:(FMDatabase *)db;

@end
