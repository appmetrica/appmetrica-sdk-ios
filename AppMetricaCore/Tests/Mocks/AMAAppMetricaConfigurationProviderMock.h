#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "AMAAppMetricaConfigurationFileStorage.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAAppMetricaConfigurationProviderMock : NSObject<AMAAppMetricaConfigurationStoring>

@property (copy, nullable) AMAAppMetricaConfiguration *configuration;

@property (strong, nonatomic, nullable) XCTestExpectation *loadConfigurationExpectation;
@property (strong, nonatomic, nullable) XCTestExpectation *saveConfigurationExpectation;

@end

NS_ASSUME_NONNULL_END
