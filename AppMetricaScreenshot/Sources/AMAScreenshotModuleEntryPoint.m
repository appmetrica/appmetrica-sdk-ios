
#import "AMAScreenshotModuleEntryPoint.h"
#import "AMAScreenshotLoader.h"
#import <AppMetricaCoreExtension/AMAServiceConfiguration.h>

@implementation AMAScreenshotModuleEntryPoint


- (void)registerComponentsWithRegistrar:(id<AMAModuleRegistrar>)registrar
{
    AMAScreenshotLoader *loader = [AMAScreenshotLoader sharedInstance];
    AMAServiceConfiguration *config = [[AMAServiceConfiguration alloc]
        initWithStartupObserver:loader
        reporterStorageController:loader];
    [registrar registerServiceConfiguration:config];
}


@end
