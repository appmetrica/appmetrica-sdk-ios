#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "AMAAdProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAAdProviderMock : AMAAdProvider

@property (nonatomic, nullable) id<AMAAdProviding> setupAdProviderValue;
@property (nonatomic, nullable) XCTestExpectation *setupAdProviderExpectation;

+ (instancetype)new;

@end

NS_ASSUME_NONNULL_END
