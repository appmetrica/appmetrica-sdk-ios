
#import <Foundation/Foundation.h>

@interface AMAFailureDispatcher : NSObject

+ (void)dispatchError:(NSError *)error withBlock:(void (^)(NSError *))block;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end
