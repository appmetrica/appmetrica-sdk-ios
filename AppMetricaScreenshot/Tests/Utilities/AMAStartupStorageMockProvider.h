#import <Foundation/Foundation.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import <XCTest/XCTest.h>

@protocol AMAKeyValueStoring;

NS_ASSUME_NONNULL_BEGIN

@interface AMAStartupStorageMockProvider : NSObject<AMAStartupStorageProviding>

@property (nonatomic, strong, nullable) id<AMAKeyValueStoring> mockedStartupStorage;
@property (nonatomic, strong, nullable) XCTestExpectation *saveStorageExpectation;

@property (nonatomic, copy, readonly, nullable) NSArray<NSString *> *startupStorageKeys;
@property (nonatomic, strong, nullable) XCTestExpectation *startupStorageExpectation;

@end

NS_ASSUME_NONNULL_END
