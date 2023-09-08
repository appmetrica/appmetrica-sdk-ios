
#if __has_include("AppMetricaCoreExtension.h")
    #import "AMAAdProviding.h"
    #import "AMAApplicationStateManager.h"
    #import "AMAEventFlushableDelegate.h"
    #import "AMACustomEventParameters.h"
    #import "AMAModuleActivationDelegate.h"
    #import "AMAReporterStorageControlling.h"
    #import "AMAServiceConfiguration.h"
    #import "AMAStartupProviding.h"
    #import "AMAModuleActivationConfiguration.h"
    #import "AMAAppMetricaExtended.h"
#else
    #import <AppMetricaCoreExtension/AMAAdProviding.h>
    #import <AppMetricaCoreExtension/AMAApplicationStateManager.h>
    #import <AppMetricaCoreExtension/AMAEventFlushableDelegate.h>
    #import <AppMetricaCoreExtension/AMACustomEventParameters.h>
    #import <AppMetricaCoreExtension/AMAModuleActivationDelegate.h>
    #import <AppMetricaCoreExtension/AMAReporterStorageControlling.h>
    #import <AppMetricaCoreExtension/AMAServiceConfiguration.h>
    #import <AppMetricaCoreExtension/AMAStartupProviding.h>
    #import <AppMetricaCoreExtension/AMAModuleActivationConfiguration.h>
    #import <AppMetricaCoreExtension/AMAAppMetricaExtended.h>
#endif
