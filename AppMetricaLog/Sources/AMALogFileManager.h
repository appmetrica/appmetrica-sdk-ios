
#import <Foundation/Foundation.h>

@class AMALogFile;
@class AMALogFileFactory;

@interface AMALogFileManager : NSObject

- (instancetype)initWithLogsDirectory:(NSString *)logsDirectoryPath
                       logFileFactory:(AMALogFileFactory *)logFileFactor;

- (instancetype)initWithLogsDirectory:(NSString *)logsDirectoryPath
                       logFileFactory:(AMALogFileFactory *)logFileFactor
                          fileManager:(NSFileManager *)fileManager;

- (NSArray *)retrieveLogFiles;
- (void)removeLogFiles:(NSArray *)logFiles;

- (NSFileHandle *)fileHandleForLogFile:(AMALogFile *)logFile;

@end
