
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "AMACrashObserving.h"

NS_ASSUME_NONNULL_BEGIN

/// Delegate that only implements the @required method (didDetectCrash:).
/// Used to test that optional methods are not called when not implemented.
@interface MockCrashObserverDelegateMinimal : NSObject <AMACrashObserving>

@property (nonatomic, strong, nullable) XCTestExpectation *didDetectCrashExpectation;
@property (nonatomic, strong, nullable) AMACrashEvent *lastCrashEvent;

@end

NS_ASSUME_NONNULL_END
