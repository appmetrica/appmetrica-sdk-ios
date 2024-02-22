
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "AMAPrivacyTimer.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAPrivacyTimerDelegateMock : NSObject<AMAPrivacyTimerDelegate>

@property (nonatomic, strong, nullable) XCTestExpectation *fireExpectation;

@end

NS_ASSUME_NONNULL_END
