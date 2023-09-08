
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AMAHostAppState) {
    AMAHostAppStateForeground = 0,
    AMAHostAppStateBackground = 1,
    AMAHostAppStateTerminated = 2,
    AMAHostAppStateUnknown = -1,
};

@protocol AMAHostStateProviderDelegate;

@protocol AMAHostStateProviding <NSObject>

@property (nonatomic, nullable, weak) id<AMAHostStateProviderDelegate> delegate;

- (AMAHostAppState)hostState;

- (void)forceUpdateToForeground;

@end

@interface AMAHostStateProvider : NSObject<AMAHostStateProviding>

@end

@protocol AMAHostStateProviderDelegate <NSObject>

- (void)hostStateDidChange:(AMAHostAppState)hostState;

@end

NS_ASSUME_NONNULL_END
