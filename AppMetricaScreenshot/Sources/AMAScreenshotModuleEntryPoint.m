
#import "AMAScreenshotModuleEntryPoint.h"
#import "AMAScreenshotLoader.h"
#import <AppMetricaCoreExtension/AMAServiceConfiguration.h>

@implementation AMAScreenshotModuleEntryPoint


- (void)initModuleWithContext:(id<AMAModuleContext>)context
{
    AMAScreenshotLoader *loader = [AMAScreenshotLoader sharedInstance];
    AMAServiceConfiguration *config = [[AMAServiceConfiguration alloc]
        initWithStartupObserver:loader
        reporterStorageController:loader];
    [context registerExternalService:config];
}


@end
