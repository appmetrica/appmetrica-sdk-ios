
#import <Foundation/Foundation.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <XCTest/XCTest.h>


NS_ASSUME_NONNULL_BEGIN

@interface AMAAsyncCancellableExecutorMock : NSObject<AMACancelableExecuting>

@property (nonatomic, nullable, strong) XCTestExpectation *executeExpectation;
@property (nonatomic, nullable, strong) XCTestExpectation *cancelExpectation;

@end

NS_ASSUME_NONNULL_END
