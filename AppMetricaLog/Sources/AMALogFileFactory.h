
#import <Foundation/Foundation.h>

@class AMALogFile;

@interface AMALogFileFactory : NSObject

- (instancetype)initWithPrefix:(NSString *)prefix;

- (AMALogFile *)logFileWithSerialNumber:(NSNumber *)serialNumber;
- (AMALogFile *)logFileFromFilePath:(NSString *)filePath;

@end
