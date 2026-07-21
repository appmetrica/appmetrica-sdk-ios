
#import <AppMetricaTestUtils/AMAModuleRegistrarMock.h>

@interface AMAModuleRegistrarMock ()

@property (nonatomic, strong, readwrite) NSMutableArray<id<AMAModulePreActivationHandler>> *preActivationHandlers;
@property (nonatomic, strong, readwrite) NSMutableArray<Class> *activationDelegates;
@property (nonatomic, strong, readwrite) NSMutableArray<Class> *eventPollingDelegates;
@property (nonatomic, strong, readwrite) NSMutableArray<Class> *eventFlushableDelegates;
@property (nonatomic, strong, readwrite) NSMutableArray<id<AMAAdProviding>> *adProviders;
@property (nonatomic, strong, readwrite) NSMutableArray<AMAServiceConfiguration *> *serviceConfigurations;

@property (nonatomic, strong, readwrite) XCTestExpectation *registerPreActivationHandlerExpectation;
@property (nonatomic, strong, readwrite) XCTestExpectation *registerActivationDelegateExpectation;
@property (nonatomic, strong, readwrite) XCTestExpectation *registerEventPollingDelegateExpectation;
@property (nonatomic, strong, readwrite) XCTestExpectation *registerEventFlushableDelegateExpectation;
@property (nonatomic, strong, readwrite) XCTestExpectation *registerAdProviderExpectation;
@property (nonatomic, strong, readwrite) XCTestExpectation *registerServiceConfigurationExpectation;

@end

@implementation AMAModuleRegistrarMock

- (instancetype)initWithTestCase:(XCTestCase *)testCase
{
    self = [super init];
    if (self) {
        _preActivationHandlers = [NSMutableArray array];
        _activationDelegates = [NSMutableArray array];
        _eventPollingDelegates = [NSMutableArray array];
        _eventFlushableDelegates = [NSMutableArray array];
        _adProviders = [NSMutableArray array];
        _serviceConfigurations = [NSMutableArray array];

        _registerPreActivationHandlerExpectation =
            [[XCTestExpectation alloc] initWithDescription:@"registerPreActivationHandler:"];
        _registerPreActivationHandlerExpectation.assertForOverFulfill = NO;

        _registerActivationDelegateExpectation =
            [[XCTestExpectation alloc] initWithDescription:@"registerActivationDelegate:"];
        _registerActivationDelegateExpectation.assertForOverFulfill = NO;

        _registerEventPollingDelegateExpectation =
            [[XCTestExpectation alloc] initWithDescription:@"registerEventPollingDelegate:"];
        _registerEventPollingDelegateExpectation.assertForOverFulfill = NO;

        _registerEventFlushableDelegateExpectation =
            [[XCTestExpectation alloc] initWithDescription:@"registerEventFlushableDelegate:"];
        _registerEventFlushableDelegateExpectation.assertForOverFulfill = NO;

        _registerAdProviderExpectation =
            [[XCTestExpectation alloc] initWithDescription:@"registerAdProvider:"];
        _registerAdProviderExpectation.assertForOverFulfill = NO;

        _registerServiceConfigurationExpectation =
            [[XCTestExpectation alloc] initWithDescription:@"registerServiceConfiguration:"];
        _registerServiceConfigurationExpectation.assertForOverFulfill = NO;
    }
    return self;
}

#pragma mark - AMAModuleRegistrar

- (void)registerPreActivationHandler:(id<AMAModulePreActivationHandler>)handler
{
    [_preActivationHandlers addObject:handler];
    [_registerPreActivationHandlerExpectation fulfill];
}

- (void)registerActivationDelegate:(Class<AMAModuleActivationDelegate>)delegate
{
    [_activationDelegates addObject:delegate];
    [_registerActivationDelegateExpectation fulfill];
}

- (void)registerEventPollingDelegate:(Class<AMAEventPollingDelegate>)delegate
{
    [_eventPollingDelegates addObject:delegate];
    [_registerEventPollingDelegateExpectation fulfill];
}

- (void)registerEventFlushableDelegate:(Class<AMAEventFlushableDelegate>)delegate
{
    [_eventFlushableDelegates addObject:delegate];
    [_registerEventFlushableDelegateExpectation fulfill];
}

- (void)registerAdProvider:(id<AMAAdProviding>)provider
{
    [_adProviders addObject:provider];
    [_registerAdProviderExpectation fulfill];
}

- (void)registerServiceConfiguration:(AMAServiceConfiguration *)configuration
{
    [_serviceConfigurations addObject:configuration];
    [_registerServiceConfigurationExpectation fulfill];
}

@end
