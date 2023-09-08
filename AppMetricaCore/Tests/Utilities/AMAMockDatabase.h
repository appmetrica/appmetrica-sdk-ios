
#import <Foundation/Foundation.h>
#import "AMADatabaseProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAMockDatabase : NSObject <AMADatabaseProtocol>

+ (instancetype)reporterDatabase;
+ (instancetype)configurationDatabase;
+ (instancetype)locationDatabase;
+ (instancetype)simpleKVDatabase;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
