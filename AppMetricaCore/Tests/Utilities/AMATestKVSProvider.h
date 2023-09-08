
#import <Foundation/Foundation.h>
#import "AMADatabaseKeyValueStorageProviding.h"

@interface AMATestKVSProvider : NSObject <AMADatabaseKeyValueStorageProviding>

@property (nonatomic, strong) id<AMADatabaseProtocol> database;

@end
