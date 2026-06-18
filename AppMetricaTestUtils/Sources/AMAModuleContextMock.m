
#import <AppMetricaTestUtils/AMAModuleContextMock.h>

@interface AMAModuleContextMock ()

@property (nonatomic, strong, readwrite) NSMutableArray<Class> *activationDelegates;
@property (nonatomic, strong, readwrite) NSMutableArray<Class> *eventPollingDelegates;
@property (nonatomic, strong, readwrite) NSMutableArray<Class> *eventFlushableDelegates;
@property (nonatomic, strong, readwrite) NSMutableArray<id<AMAAdProviding>> *adProviders;
@property (nonatomic, strong, readwrite) NSMutableArray<AMAServiceConfiguration *> *serviceConfigurations;

@property (nonatomic, strong, readwrite) XCTestExpectation *addActivationDelegateExpectation;
@property (nonatomic, strong, readwrite) XCTestExpectation *addEventPollingDelegateExpectation;
@property (nonatomic, strong, readwrite) XCTestExpectation *addEventFlushableDelegateExpectation;
@property (nonatomic, strong, readwrite) XCTestExpectation *registerAdProviderExpectation;
@property (nonatomic, strong, readwrite) XCTestExpectation *registerExternalServiceExpectation;

@end

@implementation AMAModuleContextMock

- (instancetype)initWithTestCase:(XCTestCase *)testCase
{
    self = [super init];
    if (self) {
        _activationDelegates = [NSMutableArray array];
        _eventPollingDelegates = [NSMutableArray array];
        _eventFlushableDelegates = [NSMutableArray array];
        _adProviders = [NSMutableArray array];
        _serviceConfigurations = [NSMutableArray array];

        _addActivationDelegateExpectation =
            [[XCTestExpectation alloc] initWithDescription:@"addActivationDelegate:"];
        _addActivationDelegateExpectation.assertForOverFulfill = NO;

        _addEventPollingDelegateExpectation =
            [[XCTestExpectation alloc] initWithDescription:@"addEventPollingDelegate:"];
        _addEventPollingDelegateExpectation.assertForOverFulfill = NO;

        _addEventFlushableDelegateExpectation =
            [[XCTestExpectation alloc] initWithDescription:@"addEventFlushableDelegate:"];
        _addEventFlushableDelegateExpectation.assertForOverFulfill = NO;

        _registerAdProviderExpectation =
            [[XCTestExpectation alloc] initWithDescription:@"registerAdProvider:"];
        _registerAdProviderExpectation.assertForOverFulfill = NO;

        _registerExternalServiceExpectation =
            [[XCTestExpectation alloc] initWithDescription:@"registerExternalService:"];
        _registerExternalServiceExpectation.assertForOverFulfill = NO;
    }
    return self;
}

#pragma mark - AMAModuleContext

- (void)addActivationDelegate:(Class<AMAModuleActivationDelegate>)delegate
{
    [_activationDelegates addObject:delegate];
    [_addActivationDelegateExpectation fulfill];
}

- (void)addEventPollingDelegate:(Class<AMAEventPollingDelegate>)delegate
{
    [_eventPollingDelegates addObject:delegate];
    [_addEventPollingDelegateExpectation fulfill];
}

- (void)addEventFlushableDelegate:(Class<AMAEventFlushableDelegate>)delegate
{
    [_eventFlushableDelegates addObject:delegate];
    [_addEventFlushableDelegateExpectation fulfill];
}

- (void)registerAdProvider:(id<AMAAdProviding>)provider
{
    [_adProviders addObject:provider];
    [_registerAdProviderExpectation fulfill];
}

- (void)registerExternalService:(AMAServiceConfiguration *)configuration
{
    [_serviceConfigurations addObject:configuration];
    [_registerExternalServiceExpectation fulfill];
}

@end
