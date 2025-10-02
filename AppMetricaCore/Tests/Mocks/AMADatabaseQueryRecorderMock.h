#import <Foundation/Foundation.h>
#import "AMADatabaseProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMADatabaseQueryRecorderMock : NSObject<AMADatabaseProtocol>

@property (nonatomic, strong, readonly) id<AMADatabaseKeyValueStorageProviding> storageProvider;

@property (nonatomic, copy, readonly) NSArray<NSString *> *executedStatements;

@end

NS_ASSUME_NONNULL_END
