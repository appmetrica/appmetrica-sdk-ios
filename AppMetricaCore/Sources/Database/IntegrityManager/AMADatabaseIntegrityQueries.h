
#import <Foundation/Foundation.h>

@class FMDatabaseQueue;

@interface AMADatabaseIntegrityQueries : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (NSArray<NSString *> *)integrityIssuesForDBQueue:(FMDatabaseQueue *)dbQueue error:(NSError **)error;
+ (BOOL)fixIntegrityForDBQueue:(FMDatabaseQueue *)dbQueue error:(NSError **)error;
+ (BOOL)backupDBQueue:(FMDatabaseQueue *)dbQueue backupDB:(FMDatabaseQueue *)backupDBqueue error:(NSError **)error;

@end
