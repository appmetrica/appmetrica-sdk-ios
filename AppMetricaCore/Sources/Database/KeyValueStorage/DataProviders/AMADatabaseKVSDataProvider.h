
#import <Foundation/Foundation.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMADatabaseObjectProviderBlock.h"

@class FMDatabase;
@class FMResultSet;

@interface AMADatabaseKVSDataProvider : NSObject <AMAKeyValueStorageDataProviding>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDatabase:(FMDatabase *)database
                       tableName:(NSString *)tableName
                  objectProvider:(AMADatabaseObjectProviderBlock)objectProvider;

@end
