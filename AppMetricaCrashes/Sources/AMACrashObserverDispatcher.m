#import "AMACrashObserverDispatcher.h"
#import "AMACrashObserverConfiguration.h"
#import "AMACrashObserving.h"
#import "AMACrashEvent.h"
#import "AMACrashEventConverter.h"
#import "AMADecodedCrash.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

@interface AMACrashObserverDispatcher ()

@property (nonatomic, strong) NSMutableArray<AMACrashObserverConfiguration *> *observerConfigurations;
@property (nonatomic, strong) id<AMAAsyncExecuting, AMASyncExecuting> executor;
@property (nonatomic, strong) AMACrashEventConverter *converter;

@end

@implementation AMACrashObserverDispatcher

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _observerConfigurations = [NSMutableArray array];
        _executor = [[AMAExecutor alloc] initWithIdentifier:self];
        _converter = [[AMACrashEventConverter alloc] init];
    }
    return self;
}

#pragma mark - Configuration Management

- (void)registerObserverConfiguration:(AMACrashObserverConfiguration *)configuration
{
    if (configuration == nil) {
        return;
    }

    [self.executor execute:^{
        if (![self.observerConfigurations containsObject:configuration]) {
            [self.observerConfigurations addObject:configuration];
        }
    }];
}

- (void)unregisterObserverConfiguration:(AMACrashObserverConfiguration *)configuration
{
    if (configuration == nil) {
        return;
    }

    [self.executor execute:^{
        [self.observerConfigurations removeObject:configuration];
    }];
}

- (NSArray<AMACrashObserverConfiguration *> *)registeredConfigurations
{
    return [self.executor syncExecute:^id{
        return [self.observerConfigurations copy];
    }];
}

#pragma mark - Crash Notification

- (void)notifyCrash:(AMADecodedCrash *)decodedCrash
{
    if (decodedCrash == nil) {
        return;
    }

    [self.executor execute:^{
        AMACrashEvent *crashEvent = [self.converter crashEventFromDecodedCrash:decodedCrash];
        if (crashEvent == nil) {
            return;
        }

        for (AMACrashObserverConfiguration *configuration in self.observerConfigurations) {
            [self dispatchCrashNotification:crashEvent configuration:configuration];
        }
    }];
}

- (void)notifyANR:(AMADecodedCrash *)decodedCrash
{
    if (decodedCrash == nil) {
        return;
    }

    [self.executor execute:^{
        AMACrashEvent *crashEvent = [self.converter crashEventFromDecodedCrash:decodedCrash];
        if (crashEvent == nil) {
            return;
        }

        for (AMACrashObserverConfiguration *configuration in self.observerConfigurations) {
            [self dispatchANRNotification:crashEvent configuration:configuration];
        }
    }];
}

- (void)notifyProbableUnhandledCrash:(NSString *)errorMessage
{
    if (errorMessage.length == 0) {
        return;
    }

    [self.executor execute:^{
        for (AMACrashObserverConfiguration *configuration in self.observerConfigurations) {
            [self dispatchProbableUnhandledCrashNotification:errorMessage configuration:configuration];
        }
    }];
}

#pragma mark - Private Methods

- (void)dispatchCrashNotification:(AMACrashEvent *)crashEvent
                    configuration:(AMACrashObserverConfiguration *)configuration
{
    dispatch_async(configuration.callbackQueue, ^{
        [configuration.delegate didDetectCrash:crashEvent];
    });
}   

- (void)dispatchANRNotification:(AMACrashEvent *)crashEvent
                  configuration:(AMACrashObserverConfiguration *)configuration
{
    if ([configuration.delegate respondsToSelector:@selector(didDetectANR:)]) {
        dispatch_async(configuration.callbackQueue, ^{
            [configuration.delegate didDetectANR:crashEvent];
        });
    }
}

- (void)dispatchProbableUnhandledCrashNotification:(NSString *)errorMessage
                                     configuration:(AMACrashObserverConfiguration *)configuration
{
    if ([configuration.delegate respondsToSelector:@selector(didDetectProbableUnhandledCrash:)]) {
        dispatch_async(configuration.callbackQueue, ^{
            [configuration.delegate didDetectProbableUnhandledCrash:errorMessage];
        });
    }
}

@end
