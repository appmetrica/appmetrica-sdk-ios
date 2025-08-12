#import <Foundation/Foundation.h>
#import "AMAPrivacyTimerRetryPolicy.h"
#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMAPrivacyTimerStorageMock : NSObject<AMAPrivacyTimerRetryPolicy>

@property (nullable, nonatomic) XCTestExpectation *retryPeriodExpectation;
@property (nullable, nonatomic) XCTestExpectation *isResendPeriodOutdatedExpection;
@property (nullable, nonatomic) XCTestExpectation *privacyEventSentExpectation;

@property (readwrite, nonatomic) NSArray<NSNumber *> *retryPeriod;
@property (readwrite, nonatomic) BOOL isResendPeriodOutdated;
- (void) privacyEventSent;

@end

NS_ASSUME_NONNULL_END
