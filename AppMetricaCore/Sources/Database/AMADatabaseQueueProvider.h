
#import <Foundation/Foundation.h>

@class FMDatabaseQueue;

@interface AMADatabaseQueueProvider : NSObject

@property (nonatomic, assign) BOOL logsEnabled;

- (FMDatabaseQueue *)inMemoryQueue;
- (FMDatabaseQueue *)queueForPath:(NSString *)path;

+ (instancetype)sharedInstance;

@end
