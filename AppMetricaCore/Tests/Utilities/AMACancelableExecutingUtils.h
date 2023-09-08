
#import <Foundation/Foundation.h>

@protocol AMACancelableExecuting;

@interface AMACancelableExecutingUtils : NSObject

+ (id<AMACancelableExecuting>)stubCancellableExecutor;

@end
