
#import "AMAAppMetricaPluginsImpl.h"
#import "AMACrashReporter.h"
#import <AppMetricaCore/AppMetricaCore.h>
#import "AMAAppMetricaCrashes+Private.h"

@interface AMAAppMetricaPluginsImpl ()

@property (nonatomic, strong, readwrite) id<AMAAppMetricaPluginReporting> crashReporter;

@end

@implementation AMAAppMetricaPluginsImpl

- (void)setupCrashReporter:(id<AMAAppMetricaPluginReporting>)crashReporter
{
    @synchronized (self) {
        self.crashReporter = crashReporter;
    }
}

- (void)reportUnhandledException:(AMAPluginErrorDetails *)errorDetails
                       onFailure:(nullable void (^)(NSError *error))onFailure
{
    if (self.crashReporter == nil) {
        return;
    }
    
    [self.crashReporter reportUnhandledException:errorDetails onFailure:onFailure];
}

- (void)reportError:(AMAPluginErrorDetails *)errorDetails
            message:(NSString *)message
          onFailure:(nullable void (^)(NSError *error))onFailure
{
    if (self.crashReporter == nil) {
        return;
    }
    
    [self.crashReporter reportError:errorDetails
                            message:[message copy]
                          onFailure:onFailure];
}

- (void)reportErrorWithIdentifier:(NSString *)identifier
                          message:(nullable NSString *)message
                          details:(nullable AMAPluginErrorDetails *)errorDetails
                        onFailure:(nullable void (^)(NSError *error))onFailure
{
    if (self.crashReporter == nil) {
        return;
    }
    
    [self.crashReporter reportErrorWithIdentifier:[identifier copy]
                                          message:[message copy]
                                          details:errorDetails
                                        onFailure:onFailure];
}

- (void)handlePluginInitFinished
{
    [[AMAAppMetricaCrashes crashes] handlePluginInitFinished];
}

@end
