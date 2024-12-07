
#import <Foundation/Foundation.h>
#import "AMAMetricaConfiguration.h"

@protocol AMADatabaseProtocol;

@interface AMAMetricaConfiguration (MigrationTo590)

@property (nonatomic, strong, readonly) id<AMADatabaseProtocol> database;

@end
