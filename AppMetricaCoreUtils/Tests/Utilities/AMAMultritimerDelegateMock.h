
#import <Foundation/Foundation.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMAMultritimerDelegateMock : NSObject<AMAMultitimerDelegate>

@property (nonatomic, strong, nullable) XCTestExpectation *fireCalledExpectation;
@property (nonatomic) BOOL invalidateTimer;

@end

NS_ASSUME_NONNULL_END
