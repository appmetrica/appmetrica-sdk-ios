#import <Foundation/Foundation.h>
#import "AMACore.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAModuleRegistry : NSObject

@property (nonatomic, copy, readonly) NSArray<id<AMAModuleEntryPoint>> *entryPoints;
@property (nonatomic, copy, readonly) NSArray<id<AMAModulePreActivationHandler>> *preActivationHandlers;
@property (nonatomic, copy, readonly) NSArray<Class<AMAModuleActivationDelegate>> *activationDelegates;
@property (nonatomic, copy, readonly) NSArray<Class<AMAEventPollingDelegate>> *pollingDelegates;
@property (nonatomic, copy, readonly) NSArray<Class<AMAEventFlushableDelegate>> *flushableDelegates;
@property (nonatomic, copy, readonly) NSArray<id<AMAExtendedStartupObserving>> *startupObservers;
@property (nonatomic, copy, readonly) NSArray<id<AMAReporterStorageControlling>> *storageControllers;
@property (nonatomic, strong, readonly, nullable) id<AMAAdProviding> adProvider;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithEntryPoints:(NSArray<id<AMAModuleEntryPoint>> *)entryPoints
            preActivationHandlers:(NSArray<id<AMAModulePreActivationHandler>> *)preActivationHandlers
              activationDelegates:(NSArray<Class<AMAModuleActivationDelegate>> *)activationDelegates
                 pollingDelegates:(NSArray<Class<AMAEventPollingDelegate>> *)pollingDelegates
                flushableDelegates:(NSArray<Class<AMAEventFlushableDelegate>> *)flushableDelegates
                 startupObservers:(NSArray<id<AMAExtendedStartupObserving>> *)startupObservers
               storageControllers:(NSArray<id<AMAReporterStorageControlling>> *)storageControllers
                       adProvider:(nullable id<AMAAdProviding>)adProvider NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
