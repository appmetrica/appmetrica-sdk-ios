
#import <Foundation/Foundation.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>

@class AMAModuleActivationConfiguration;

// MARK: - AMAModuleEntryPoint

@interface AMAFakeEntryPoint : NSObject <AMAModuleEntryPoint>
// Instance tracking (for tests that create instances directly)
@property (nonatomic, assign) NSInteger initCallCount;
@property (nonatomic, weak, nullable) id<AMAModuleContext> receivedContext;
// Class tracking (for tests where instances are created internally via classLookup)
+ (NSInteger)initContextCallCount;
+ (void)resetCallCount;
@end

// MARK: - AMAModuleActivationDelegate

@interface AMAModuleActivationDelegateMock : NSObject <AMAModuleActivationDelegate>
+ (NSInteger)willActivateCallCount;
+ (NSInteger)didActivateCallCount;
+ (nullable AMAModuleActivationConfiguration *)lastConfiguration;
+ (void)reset;
@end

// MARK: - AMAEventFlushableDelegate

@interface AMAEventFlushableDelegateMock : NSObject <AMAEventFlushableDelegate>
+ (NSInteger)sendEventsBufferCallCount;
+ (void)reset;
@end

// MARK: - AMAExtendedStartupObserving

@interface AMAExtendedStartupObservingMock : NSObject <AMAExtendedStartupObserving>
@property (nonatomic, assign) NSInteger updatedCallCount;
@property (nonatomic, assign) NSInteger failedCallCount;
@property (nonatomic, assign) NSInteger setupCallCount;
@property (nonatomic, strong, nullable) NSDictionary *lastParameters;
@property (nonatomic, strong, nullable) NSError *lastError;
@property (nonatomic, strong, nullable) NSDictionary *stubbedStartupParameters;
@end

// MARK: - AMAReporterStorageControlling

@interface AMAReporterStorageControllingMock : NSObject <AMAReporterStorageControlling>
@property (nonatomic, assign) NSInteger setupCallCount;
@end
