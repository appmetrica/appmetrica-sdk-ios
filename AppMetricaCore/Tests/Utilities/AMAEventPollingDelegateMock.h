#import <Foundation/Foundation.h>
#import "AMAEventPollingDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class AMAModuleInvocationRecorder;

@interface AMAEventPollingDelegateMock : NSObject <AMAEventPollingDelegate>

@property (class, nonatomic, strong) NSArray<AMAEventPollingParameters *> *mockedEvents;
@property (class, nonatomic, weak, nullable) AMAModuleInvocationRecorder *invocationRecorder;

+ (void)reset;

@end

NS_ASSUME_NONNULL_END
