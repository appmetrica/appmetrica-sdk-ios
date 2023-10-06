
#if __has_include("AppMetricaCrashes.h")
    #import "AMAAppMetricaPluginReporting.h"
    #import "AMAAppMetricaPlugins.h"
    #import "AMACrashMatchingRule.h"
    #import "AMACrashProcessingReporting.h"
    #import "AMACrashes.h"
    #import "AMACrashesConfiguration.h"
    #import "AMAError.h"
    #import "AMAErrorRepresentable.h"
    #import "AMAPluginErrorDetails.h"
    #import "AMAStackTraceElement.h"
#else
    #import <AppMetricaCrashes/AMAAppMetricaPluginReporting.h>
    #import <AppMetricaCrashes/AMAAppMetricaPlugins.h>
    #import <AppMetricaCrashes/AMACrashMatchingRule.h>
    #import <AppMetricaCrashes/AMACrashProcessingReporting.h>
    #import <AppMetricaCrashes/AMACrashes.h>
    #import <AppMetricaCrashes/AMACrashesConfiguration.h>
    #import <AppMetricaCrashes/AMAError.h>
    #import <AppMetricaCrashes/AMAErrorRepresentable.h>
    #import <AppMetricaCrashes/AMAPluginErrorDetails.h>
    #import <AppMetricaCrashes/AMAStackTraceElement.h>
#endif
