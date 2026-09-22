#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "AMAAppMetricaConfiguration.h"
#import "AMAAppMetricaConfigurationStoring.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAAppMetricaConfigurationProviderMock : NSObject <AMAAppMetricaConfigurationFileStoring>

@property (copy, nullable) AMAAppMetricaConfiguration *configuration;
@property (strong, nullable) NSDate *savedAt;

@property (strong, nonatomic, nullable) XCTestExpectation *loadSnapshotExpectation;
@property (strong, nonatomic, nullable) XCTestExpectation *saveSnapshotExpectation;
@property (strong, nonatomic, nullable) XCTestExpectation *deleteSnapshotExpectation;

@end

NS_ASSUME_NONNULL_END
