
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMAModuleRegistrarMock : NSObject <AMAModuleRegistrar>

@property (nonatomic, strong, readonly) NSMutableArray<id<AMAModulePreActivationHandler>> *preActivationHandlers;
@property (nonatomic, strong, readonly) NSMutableArray<Class> *activationDelegates;
@property (nonatomic, strong, readonly) NSMutableArray<Class> *eventPollingDelegates;
@property (nonatomic, strong, readonly) NSMutableArray<Class> *eventFlushableDelegates;
@property (nonatomic, strong, readonly) NSMutableArray<id<AMAAdProviding>> *adProviders;
@property (nonatomic, strong, readonly) NSMutableArray<AMAServiceConfiguration *> *serviceConfigurations;

@property (nonatomic, strong, readonly) XCTestExpectation *registerPreActivationHandlerExpectation;
@property (nonatomic, strong, readonly) XCTestExpectation *registerActivationDelegateExpectation;
@property (nonatomic, strong, readonly) XCTestExpectation *registerEventPollingDelegateExpectation;
@property (nonatomic, strong, readonly) XCTestExpectation *registerEventFlushableDelegateExpectation;
@property (nonatomic, strong, readonly) XCTestExpectation *registerAdProviderExpectation;
@property (nonatomic, strong, readonly) XCTestExpectation *registerServiceConfigurationExpectation;

- (instancetype)initWithTestCase:(XCTestCase *)testCase;

@end

NS_ASSUME_NONNULL_END
