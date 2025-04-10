#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "AMAAdResolver.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAAdResolverMock : AMAAdResolver

@property (nonatomic, nullable) XCTestExpectation *updateAdProviderExpectation;
@property (nonatomic) BOOL updateAdProviderValue;

@end

NS_ASSUME_NONNULL_END
