
#import "AMAModuleContextMocks.h"

// MARK: - AMAFakeEntryPoint

@implementation AMAFakeEntryPoint

static NSInteger sInitContextCallCount = 0;

+ (NSInteger)initContextCallCount { return sInitContextCallCount; }
+ (void)resetCallCount { sInitContextCallCount = 0; }

- (void)initModuleWithContext:(id<AMAModuleContext>)context
{
    self.initCallCount++;
    self.receivedContext = context;
    sInitContextCallCount++;
}

@end

// MARK: - AMAModuleActivationDelegateMock

@implementation AMAModuleActivationDelegateMock

static NSInteger sWillCount = 0;
static NSInteger sDidCount = 0;
static AMAModuleActivationConfiguration *sLastConfig = nil;

+ (NSInteger)willActivateCallCount { return sWillCount; }
+ (NSInteger)didActivateCallCount  { return sDidCount; }
+ (nullable AMAModuleActivationConfiguration *)lastConfiguration { return sLastConfig; }
+ (void)reset { sWillCount = 0; sDidCount = 0; sLastConfig = nil; }

+ (void)willActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration
{
    sWillCount++;
    sLastConfig = configuration;
}

+ (void)didActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration
{
    sDidCount++;
    sLastConfig = configuration;
}

@end

// MARK: - AMAEventFlushableDelegateMock

@implementation AMAEventFlushableDelegateMock

static NSInteger sFlushCount = 0;

+ (NSInteger)sendEventsBufferCallCount { return sFlushCount; }
+ (void)reset { sFlushCount = 0; }
+ (void)sendEventsBuffer { sFlushCount++; }

@end

// MARK: - AMAExtendedStartupObservingMock

@implementation AMAExtendedStartupObservingMock

- (NSDictionary *)startupParameters { return self.stubbedStartupParameters ?: @{}; }

- (void)startupUpdatedWithParameters:(NSDictionary *)parameters
{
    self.updatedCallCount++;
    self.lastParameters = parameters;
}

- (void)setupStartupProvider:(id<AMAStartupStorageProviding>)startupStorageProvider
       cachingStorageProvider:(id<AMACachingStorageProviding>)cachingStorageProvider
{
    self.setupCallCount++;
}

- (void)startupUpdateFailedWithError:(NSError *)error
{
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
    self.setupCallCount++;
}

@end
