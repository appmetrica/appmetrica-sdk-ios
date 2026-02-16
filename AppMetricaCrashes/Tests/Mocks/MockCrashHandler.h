
#import <Foundation/Foundation.h>
#import "AMACrashFilteringProxy.h"

@class AMACrashEvent;

NS_ASSUME_NONNULL_BEGIN

@interface MockCrashHandler : NSObject <AMACrashFilteringProxy>

@property (nonatomic, copy) NSString *apiKey;
@property (nonatomic, assign) BOOL crashResult;
@property (nonatomic, assign) BOOL anrResult;
@property (nonatomic, assign) NSUInteger crashCallCount;
@property (nonatomic, assign) NSUInteger anrCallCount;
@property (nonatomic, strong, nullable) AMACrashEvent *lastCrashEvent;

@end

NS_ASSUME_NONNULL_END
