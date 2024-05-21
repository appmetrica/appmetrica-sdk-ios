#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "AMAPrivacyTimer.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAPrivacyTimerMock : AMAPrivacyTimer

@property (nonatomic, strong, nullable) NSLock *onTimerLock;
@property (nonatomic, strong, nullable) XCTestExpectation *onTimerExpectation;
@property (nonatomic) BOOL disableFire;

@end

NS_ASSUME_NONNULL_END
