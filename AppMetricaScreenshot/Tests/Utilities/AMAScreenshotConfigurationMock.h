#import <Foundation/Foundation.h>
#import "AMAScreenshotConfiguration.h"
#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMAScreenshotConfigurationMock : AMAScreenshotConfiguration

@property (nonatomic, nullable) XCTestExpectation *screenshotEnabledSetterExpectation;
@property (nonatomic, nullable) XCTestExpectation *screenshotEnabledGetterExpectation;

@property (nonatomic) BOOL screenshotEnabledValue;

@end

NS_ASSUME_NONNULL_END
