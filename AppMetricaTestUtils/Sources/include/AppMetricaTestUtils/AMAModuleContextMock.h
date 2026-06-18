
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMAModuleContextMock : NSObject <AMAModuleContext>

@property (nonatomic, strong, readonly) NSMutableArray<Class> *activationDelegates;
@property (nonatomic, strong, readonly) NSMutableArray<Class> *eventPollingDelegates;
@property (nonatomic, strong, readonly) NSMutableArray<Class> *eventFlushableDelegates;
@property (nonatomic, strong, readonly) NSMutableArray<id<AMAAdProviding>> *adProviders;
@property (nonatomic, strong, readonly) NSMutableArray<AMAServiceConfiguration *> *serviceConfigurations;

@property (nonatomic, strong, readonly) XCTestExpectation *addActivationDelegateExpectation;
@property (nonatomic, strong, readonly) XCTestExpectation *addEventPollingDelegateExpectation;
@property (nonatomic, strong, readonly) XCTestExpectation *addEventFlushableDelegateExpectation;
@property (nonatomic, strong, readonly) XCTestExpectation *registerAdProviderExpectation;
@property (nonatomic, strong, readonly) XCTestExpectation *registerExternalServiceExpectation;

- (instancetype)initWithTestCase:(XCTestCase *)testCase;

@end

NS_ASSUME_NONNULL_END
