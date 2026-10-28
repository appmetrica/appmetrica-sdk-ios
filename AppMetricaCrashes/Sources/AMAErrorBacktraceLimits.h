
#import <Foundation/Foundation.h>

/// Max stack frames kept for native and plugin error reports before symbolication.
static const NSUInteger AMAErrorMaxBacktraceFramesCount = 200;

/// Max depth of the underlying-error chain for native `NSError` / `AMAErrorRepresentable` reports.
static const NSUInteger AMAErrorMaxUnderlyingErrorsCount = 10;
