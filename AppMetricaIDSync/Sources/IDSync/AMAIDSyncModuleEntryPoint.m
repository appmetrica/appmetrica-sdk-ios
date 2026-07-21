
#import "AMAIDSyncModuleEntryPoint.h"
#import "AMAIDSyncStartupController.h"
#import <AppMetricaCoreExtension/AMAServiceConfiguration.h>

@implementation AMAIDSyncModuleEntryPoint


- (void)registerComponentsWithRegistrar:(id<AMAModuleRegistrar>)registrar
{
    AMAIDSyncStartupController *controller = [AMAIDSyncStartupController sharedInstance];
    AMAServiceConfiguration *config = [[AMAServiceConfiguration alloc]
        initWithStartupObserver:controller
        reporterStorageController:controller];
    [registrar registerServiceConfiguration:config];
}


@end
