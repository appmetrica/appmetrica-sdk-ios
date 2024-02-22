#import <Foundation/Foundation.h>
#import "AMAPrivacyTimerStorage.h"
#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMAPrivacyTimerStorageMock : NSObject<AMAPrivacyTimerStorage>

@property (nullable, nonatomic) XCTestExpectation *retryPeriodExpectation;
@property (nullable, nonatomic) XCTestExpectation *isResendPeriodOutdatedExpection;
@property (nullable, nonatomic) XCTestExpectation *privacyEventSentExpectation;

@property (readwrite, nonatomic) NSArray<NSNumber *> *retryPeriod;
@property (readwrite, nonatomic) BOOL isResendPeriodOutdated;
- (void) privacyEventSent;

@end

NS_ASSUME_NONNULL_END
