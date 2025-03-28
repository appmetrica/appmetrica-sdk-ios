#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "AMAScreenshotReporting.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAMockScreenshotReporter : NSObject<AMAScreenshotReporting>

@property (nonatomic, strong, nullable) XCTestExpectation *reportScreenshotExpectation;

@end

NS_ASSUME_NONNULL_END
