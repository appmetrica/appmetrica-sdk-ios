
#import <Foundation/Foundation.h>
#import "AMAReporterDatabaseEncryptionType.h"

@interface AMAReporterDatabaseEncryptionDefaults : NSObject

+ (AMAReporterDatabaseEncryptionType)eventDataEncryptionType;
+ (AMAReporterDatabaseEncryptionType)sessionDataEncryptionType;

+ (NSData *)firstMessage;
+ (NSData *)secondMessage;

@end
