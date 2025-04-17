
#import <Foundation/Foundation.h>
#import "AMAReporterDatabaseEncryptionType.h"

@protocol AMADataEncoding;

@protocol AMAReporterDatabaseEncoderProviding <NSObject>

- (id<AMADataEncoding>)encoderForEncryptionType:(AMAReporterDatabaseEncryptionType)encryptionType;

@end
