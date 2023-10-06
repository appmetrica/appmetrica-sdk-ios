
#import <Foundation/Foundation.h>
#import <AppMetricaHostState/AppMetricaHostState.h>
#import "AMACrashLogging.h"

@class AMAUserDefaultsStorage;
@protocol AMAExecuting;

typedef NS_ENUM(NSInteger, AMAUnhandledCrashType) {
    AMAUnhandledCrashUnknown,
    AMAUnhandledCrashBackground,
    AMAUnhandledCrashForeground,
};

typedef void (^AMAUnhandledCrashCallback)(AMAUnhandledCrashType crashType);

@interface AMAUnhandledCrashDetector : NSObject<AMAHostStateProviderDelegate>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithStorage:(AMAUserDefaultsStorage *)storage
                       executor:(id<AMAExecuting>)executor;

- (instancetype)initWithStorage:(AMAUserDefaultsStorage *)storage
              hostStateProvider:(id<AMAHostStateProviding>)hostStateProvider
                       executor:(id<AMAExecuting>)executor NS_DESIGNATED_INITIALIZER;

- (void)startDetecting;

- (void)checkUnhandledCrash:(AMAUnhandledCrashCallback)unhandledCrashCallback;

@end
