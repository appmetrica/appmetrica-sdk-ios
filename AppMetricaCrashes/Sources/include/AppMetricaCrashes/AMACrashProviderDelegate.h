
#import <Foundation/Foundation.h>

@protocol AMACrashProviding;
@class AMACrashEvent;

NS_ASSUME_NONNULL_BEGIN

/// Delegate protocol for push-model crash providers.
/// SDK sets itself as a delegate when a provider is registered.
/// The provider calls delegate methods when it detects a new crash or ANR in real time.
NS_SWIFT_NAME(CrashProviderDelegate)
@protocol AMACrashProviderDelegate <NSObject>

/// Called when a crash provider detects a new crash report.
/// @param provider The provider that detected the crash.
/// @param report The crash event.
- (void)crashProvider:(id<AMACrashProviding>)provider
       didDetectCrash:(AMACrashEvent *)report;

/// Called when a crash provider detects a new ANR report.
/// @param provider The provider that detected the ANR.
/// @param report The ANR event.
- (void)crashProvider:(id<AMACrashProviding>)provider
         didDetectANR:(AMACrashEvent *)report;

@end

NS_ASSUME_NONNULL_END
