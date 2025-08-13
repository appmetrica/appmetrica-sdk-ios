#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "AMAResolver.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAMockResolver : AMAResolver

@property (nonatomic, readwrite) BOOL defaultValue;

@property (nonatomic, strong, nullable) XCTestExpectation *updateExpectation;
@property (nonatomic, assign) BOOL lastValue;

@end

NS_ASSUME_NONNULL_END
