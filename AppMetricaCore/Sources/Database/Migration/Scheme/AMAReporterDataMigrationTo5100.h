
#import "AMADatabaseDataMigration.h"

@interface AMAReporterDataMigrationTo5100 : NSObject<AMADatabaseDataMigration>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithApiKey:(NSString *)apiKey;

@end
