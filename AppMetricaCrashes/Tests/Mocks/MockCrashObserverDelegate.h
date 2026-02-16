
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "AMACrashObserving.h"

NS_ASSUME_NONNULL_BEGIN

@interface MockCrashObserverDelegate : NSObject <AMACrashObserving>

@property (nonatomic, strong, nullable) XCTestExpectation *didDetectCrashExpectation;
@property (nonatomic, strong, nullable) XCTestExpectation *didDetectANRExpectation;
@property (nonatomic, strong, nullable) XCTestExpectation *didDetectProbableUnhandledCrashExpectation;

@property (nonatomic, strong, nullable) AMACrashEvent * lastCrashEvent;
@property (nonatomic, copy, nullable) NSString *lastErrorMessage;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
