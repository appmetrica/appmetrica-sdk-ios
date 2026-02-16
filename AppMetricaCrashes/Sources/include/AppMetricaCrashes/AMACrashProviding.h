
#import <Foundation/Foundation.h>

@class AMACrashEvent;
@protocol AMACrashProviderDelegate;

NS_ASSUME_NONNULL_BEGIN

/// Protocol for crash providers.
/// Supports two models:
/// - **Pull model**: Provider stores crashes; SDK retrieves them on startup via `pendingCrashReports`.
/// - **Push model**: Provider notifies SDK in real time via the `delegate`.
///
/// All methods are `@optional`. A provider implements only the methods relevant to its model.
NS_SWIFT_NAME(CrashProviding)
@protocol AMACrashProviding <NSObject>

@optional

#pragma mark - Pull model (provider stores crashes)

/// Returns all unprocessed crash reports.
/// A crash report is considered unprocessed until `didProcessCrashReports:` is called for it.
/// Called by the SDK on startup during crash processing.
/// @return Array of crash events, or nil.
- (nullable NSArray<AMACrashEvent *> *)pendingCrashReports;

#pragma mark - Push model (real-time notification)

/// Delegate for push-model notifications.
/// The SDK sets this delegate after the provider is registered.
/// The provider calls delegate methods when it detects a new crash.
@property (nonatomic, weak, nullable) id<AMACrashProviderDelegate> delegate;

#pragma mark - Common

/// Called after the SDK successfully processes specific reports.
/// A crash report is considered unprocessed until this method is called for it.
/// The provider should remove these reports from its storage.
/// Called for both pull-model (after processing `pendingCrashReports`) and push-model (after processing a pushed event) reports.
/// @param processedReports The crash events that have been processed.
- (void)didProcessCrashReports:(NSArray<AMACrashEvent *> *)processedReports;

@end

NS_ASSUME_NONNULL_END
