
#import "AMAIDSyncModuleEntryPoint.h"
#import "AMAIDSyncStartupController.h"
#import <AppMetricaCoreExtension/AMAServiceConfiguration.h>

@implementation AMAIDSyncModuleEntryPoint


- (void)initModuleWithContext:(id<AMAModuleContext>)context
{
    AMAIDSyncStartupController *controller = [AMAIDSyncStartupController sharedInstance];
    AMAServiceConfiguration *config = [[AMAServiceConfiguration alloc]
        initWithStartupObserver:controller
        reporterStorageController:controller];
    [context registerExternalService:config];
}


@end
