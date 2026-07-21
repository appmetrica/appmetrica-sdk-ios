
#import "AMAModuleRegistrarMocks.h"
#import "Utilities/AMAModuleInvocationRecorder.h"

// MARK: - AMAFakeEntryPoint

@implementation AMAFakeEntryPoint

static NSInteger sRegistrationCallCount = 0;

+ (NSInteger)registrationCallCount { return sRegistrationCallCount; }
+ (void)resetCallCount { sRegistrationCallCount = 0; }

- (void)registerComponentsWithRegistrar:(id<AMAModuleRegistrar>)registrar
{
    [self.invocationRecorder recordInvocationFromClass:self.class selector:_cmd];
    self.registrationCallCount++;
    self.receivedRegistrar = registrar;
    sRegistrationCallCount++;
    if (self.registrationHandler != nil) {
        self.registrationHandler(registrar);
    }
}

@end

// MARK: - AMAModuleActivationDelegateMock

@implementation AMAModuleActivationDelegateMock

static NSInteger sWillCount = 0;
static NSInteger sDidCount = 0;
static AMAModuleActivationConfiguration *sLastConfig = nil;
static __weak AMAModuleInvocationRecorder *sActivationInvocationRecorder = nil;
static void (^sWillActivateHandler)(AMAModuleActivationConfiguration *) = nil;
static void (^sDidActivateHandler)(AMAModuleActivationConfiguration *) = nil;

+ (AMAModuleInvocationRecorder *)invocationRecorder
{
    return sActivationInvocationRecorder;
}

+ (void)setInvocationRecorder:(AMAModuleInvocationRecorder *)recorder
{
    sActivationInvocationRecorder = recorder;
}

+ (void (^)(AMAModuleActivationConfiguration *))willActivateHandler
{
    return sWillActivateHandler;
}

+ (void)setWillActivateHandler:(void (^)(AMAModuleActivationConfiguration *))handler
{
    sWillActivateHandler = [handler copy];
}

+ (void (^)(AMAModuleActivationConfiguration *))didActivateHandler
{
    return sDidActivateHandler;
}

+ (void)setDidActivateHandler:(void (^)(AMAModuleActivationConfiguration *))handler
{
    sDidActivateHandler = [handler copy];
}

+ (NSInteger)willActivateCallCount { return sWillCount; }
+ (NSInteger)didActivateCallCount  { return sDidCount; }
+ (nullable AMAModuleActivationConfiguration *)lastConfiguration { return sLastConfig; }
+ (void)reset
{
    sWillCount = 0;
    sDidCount = 0;
    sLastConfig = nil;
    sActivationInvocationRecorder = nil;
    sWillActivateHandler = nil;
    sDidActivateHandler = nil;
}

+ (void)willActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration
{
    [sActivationInvocationRecorder recordInvocationFromClass:self selector:_cmd];
    sWillCount++;
    sLastConfig = configuration;
    if (sWillActivateHandler != nil) {
        sWillActivateHandler(configuration);
    }
}

+ (void)didActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration
{
    [sActivationInvocationRecorder recordInvocationFromClass:self selector:_cmd];
    sDidCount++;
    sLastConfig = configuration;
    if (sDidActivateHandler != nil) {
        sDidActivateHandler(configuration);
    }
}

@end

// MARK: - AMAEventFlushableDelegateMock

@implementation AMAEventFlushableDelegateMock

static NSInteger sFlushCount = 0;
static __weak AMAModuleInvocationRecorder *sFlushInvocationRecorder = nil;
static dispatch_block_t sSendEventsBufferHandler = nil;

+ (AMAModuleInvocationRecorder *)invocationRecorder
{
    return sFlushInvocationRecorder;
}

+ (void)setInvocationRecorder:(AMAModuleInvocationRecorder *)recorder
{
    sFlushInvocationRecorder = recorder;
}

+ (dispatch_block_t)sendEventsBufferHandler
{
    return sSendEventsBufferHandler;
}

+ (void)setSendEventsBufferHandler:(dispatch_block_t)handler
{
    sSendEventsBufferHandler = [handler copy];
}

+ (NSInteger)sendEventsBufferCallCount { return sFlushCount; }
+ (void)reset
{
    sFlushCount = 0;
    sFlushInvocationRecorder = nil;
    sSendEventsBufferHandler = nil;
}
+ (void)sendEventsBuffer
{
    [sFlushInvocationRecorder recordInvocationFromClass:self selector:_cmd];
    sFlushCount++;
    if (sSendEventsBufferHandler != nil) {
        sSendEventsBufferHandler();
    }
}

@end

// MARK: - AMAModulePreActivationHandlerMock

@implementation AMAModulePreActivationHandlerMock

- (void)handlePreActivationWithConfiguration:(AMAModuleActivationConfiguration *)configuration
{
    [self.invocationRecorder recordInvocationFromClass:self.class selector:_cmd];
    self.handleCallCount++;
    if (self.preActivationBlock != nil) {
        self.preActivationBlock(configuration);
    }
}

@end

// MARK: - AMAExtendedStartupObservingMock

@implementation AMAExtendedStartupObservingMock

- (NSDictionary *)startupParameters
{
    [self.invocationRecorder recordInvocationFromClass:self.class selector:_cmd];
    return self.stubbedStartupParameters ?: @{};
}

- (void)startupUpdatedWithParameters:(NSDictionary *)parameters
{
    [self.invocationRecorder recordInvocationFromClass:self.class selector:_cmd];
    self.updatedCallCount++;
    self.lastParameters = parameters;
}

- (void)setupStartupProvider:(id<AMAStartupStorageProviding>)startupStorageProvider
       cachingStorageProvider:(id<AMACachingStorageProviding>)cachingStorageProvider
{
    [self.invocationRecorder recordInvocationFromClass:self.class selector:_cmd];
    self.setupCallCount++;
}

- (void)startupUpdateFailedWithError:(NSError *)error
{
    [self.invocationRecorder recordInvocationFromClass:self.class selector:_cmd];
    self.failedCallCount++;
    self.lastError = error;
}

@end

// MARK: - AMAReporterStorageControllingMock

@implementation AMAReporterStorageControllingMock

- (void)setupWithReporterStorage:(id<AMAKeyValueStorageProviding>)stateStorageProvider
                            main:(BOOL)main
                       forAPIKey:(NSString *)apiKey
{
    [self.invocationRecorder recordInvocationFromClass:self.class selector:_cmd];
    self.setupCallCount++;
}

@end
