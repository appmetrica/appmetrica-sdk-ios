
#import <Foundation/Foundation.h>

@class AMACrashEvent;

NS_ASSUME_NONNULL_BEGIN

/// Protocol for crash handling with selective reporting to a custom API key.
/// Implement this protocol to filter which crashes and ANRs should be additionally
/// reported to your own API key.
NS_SWIFT_NAME(CrashFilteringProxy)
@protocol AMACrashFilteringProxy <NSObject>

/// The API key to report matching crashes to.
@property (nonatomic, copy, readonly) NSString *apiKey;

/// Return YES to additionally report this crash to the handler's API key.
/// @param crashEvent Information about the crash event.
- (BOOL)shouldReportCrash:(AMACrashEvent *)crashEvent;

/// Return YES to additionally report this ANR to the handler's API key.
/// @param crashEvent Information about the ANR event.
- (BOOL)shouldReportANR:(AMACrashEvent *)crashEvent;

@end

NS_ASSUME_NONNULL_END
