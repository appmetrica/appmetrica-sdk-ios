#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMAStorageMock : NSObject<AMAFileStorage>

@property (nonatomic, assign, readwrite) BOOL fileExists;

@property (nonatomic, strong, nullable) NSError *mockError;

@property (nonatomic, copy, nullable) NSData *mockedData;

@property (nonatomic, strong, nullable) XCTestExpectation *readExpectation;
@property (nonatomic, strong, nullable) XCTestExpectation *writeExpectation;
@property (nonatomic, strong, nullable) XCTestExpectation *deleteExpectation;

@end

NS_ASSUME_NONNULL_END
