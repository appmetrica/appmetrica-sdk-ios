
#import <Foundation/Foundation.h>

@interface AMAQueuesFactory : NSObject

+ (dispatch_queue_t)serialQueueForIdentifierObject:(NSObject *)identifierObject domain:(NSString *)domain;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end
