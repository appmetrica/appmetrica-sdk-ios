
#import <Foundation/Foundation.h>
#import "AMACore.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAModuleContextImpl : NSObject <AMAModuleContext>

- (void)notifyWillActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration;
- (void)notifyDidActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration;
- (void)notifySendEventsBuffer;

- (NSSet<Class<AMAEventPollingDelegate>> *)eventPollingDelegates;
- (NSSet<id<AMAExtendedStartupObserving>> *)startupObservers;
- (NSSet<id<AMAReporterStorageControlling>> *)reporterStorageControllers;

@property (nonatomic, strong, readonly, nullable) id<AMAAdProviding> adProvider;

@end

NS_ASSUME_NONNULL_END
