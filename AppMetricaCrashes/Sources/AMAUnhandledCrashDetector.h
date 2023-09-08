
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

- (instancetype)initWithStorage:(AMAUserDefaultsStorage *)storage
                       executor:(id<AMAExecuting>)executor;

- (void)startDetecting;

- (void)checkUnhandledCrash:(AMAUnhandledCrashCallback)unhandledCrashCallback;

@end
