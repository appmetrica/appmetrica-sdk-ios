
#import <Foundation/Foundation.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <XCTest/XCTest.h>


NS_ASSUME_NONNULL_BEGIN

@interface AMACancellableExecutorMock : NSObject<AMACancelableExecuting>

@property (nonnull, readonly) NSArray<NSNumber *> *receivedDelays;
@property (nullable) XCTestExpectation *cancelExpectation;

@end

NS_ASSUME_NONNULL_END
