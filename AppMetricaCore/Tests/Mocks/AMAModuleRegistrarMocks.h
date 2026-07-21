
#import <Foundation/Foundation.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>

@class AMAModuleActivationConfiguration;
@class AMAModuleInvocationRecorder;

NS_ASSUME_NONNULL_BEGIN

// MARK: - AMAModuleEntryPoint

@interface AMAFakeEntryPoint : NSObject <AMAModuleEntryPoint>
// Instance tracking (for tests that create instances directly)
@property (nonatomic, assign) NSInteger registrationCallCount;
@property (nonatomic, weak, nullable) id<AMAModuleRegistrar> receivedRegistrar;
@property (nonatomic, weak, nullable) AMAModuleInvocationRecorder *invocationRecorder;
@property (nonatomic, copy, nullable) void (^registrationHandler)(id<AMAModuleRegistrar> registrar);
// Class tracking (for tests where instances are created internally via classLookup)
+ (NSInteger)registrationCallCount;
+ (void)resetCallCount;
@end

// MARK: - AMAModuleActivationDelegate

@interface AMAModuleActivationDelegateMock : NSObject <AMAModuleActivationDelegate>
@property (class, nonatomic, weak, nullable) AMAModuleInvocationRecorder *invocationRecorder;
@property (class, nonatomic, copy, nullable) void (^willActivateHandler)(AMAModuleActivationConfiguration *configuration);
@property (class, nonatomic, copy, nullable) void (^didActivateHandler)(AMAModuleActivationConfiguration *configuration);
+ (NSInteger)willActivateCallCount;
+ (NSInteger)didActivateCallCount;
+ (nullable AMAModuleActivationConfiguration *)lastConfiguration;
+ (void)reset;
@end

// MARK: - AMAEventFlushableDelegate

@interface AMAEventFlushableDelegateMock : NSObject <AMAEventFlushableDelegate>
@property (class, nonatomic, weak, nullable) AMAModuleInvocationRecorder *invocationRecorder;
@property (class, nonatomic, copy, nullable) dispatch_block_t sendEventsBufferHandler;
+ (NSInteger)sendEventsBufferCallCount;
+ (void)reset;
@end

// MARK: - AMAModulePreActivationHandler

@interface AMAModulePreActivationHandlerMock : NSObject <AMAModulePreActivationHandler>
@property (nonatomic, assign) NSInteger handleCallCount;
@property (nonatomic, weak, nullable) AMAModuleInvocationRecorder *invocationRecorder;
@property (nonatomic, copy, nullable) void (^preActivationBlock)(AMAModuleActivationConfiguration *configuration);
@end

// MARK: - AMAExtendedStartupObserving

@interface AMAExtendedStartupObservingMock : NSObject <AMAExtendedStartupObserving>
@property (nonatomic, assign) NSInteger updatedCallCount;
@property (nonatomic, assign) NSInteger failedCallCount;
@property (nonatomic, assign) NSInteger setupCallCount;
@property (nonatomic, strong, nullable) NSDictionary *lastParameters;
@property (nonatomic, strong, nullable) NSError *lastError;
@property (nonatomic, strong, nullable) NSDictionary *stubbedStartupParameters;
@property (nonatomic, weak, nullable) AMAModuleInvocationRecorder *invocationRecorder;
@end

// MARK: - AMAReporterStorageControlling

@interface AMAReporterStorageControllingMock : NSObject <AMAReporterStorageControlling>
@property (nonatomic, assign) NSInteger setupCallCount;
@property (nonatomic, weak, nullable) AMAModuleInvocationRecorder *invocationRecorder;
@end

NS_ASSUME_NONNULL_END
