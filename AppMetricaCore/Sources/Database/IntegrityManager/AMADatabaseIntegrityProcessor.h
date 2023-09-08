
#import <Foundation/Foundation.h>

@class AMADatabaseIntegrityReport;
@class FMDatabaseQueue;
@class AMASQLiteIntegrityIssueParser;

extern NSString *const kAMADatabaseIntegrityStepInitial;
extern NSString *const kAMADatabaseIntegrityStepReindex;
extern NSString *const kAMADatabaseIntegrityStepBackupRestore;
extern NSString *const kAMADatabaseIntegrityStepNewDatabase;

@interface AMADatabaseIntegrityProcessor : NSObject

- (instancetype)initWithParser:(AMASQLiteIntegrityIssueParser *)parser;

- (BOOL)checkIntegrityIssuesForDatabase:(FMDatabaseQueue *)databaseQueue
                                 report:(AMADatabaseIntegrityReport *)report;

- (BOOL)fixIndexForDatabase:(FMDatabaseQueue *)databaseQueue
                     report:(AMADatabaseIntegrityReport *)report;

- (BOOL)fixWithBackupAndRestore:(FMDatabaseQueue **)databaseQueue
                         report:(AMADatabaseIntegrityReport *)report;

- (BOOL)fixWithCreatingNewDatabase:(FMDatabaseQueue **)databaseQueue
                            report:(AMADatabaseIntegrityReport *)report;

@end
