
#if __has_include("AppMetricaCrashes.h")
    #import "AMAAppMetricaCrashes.h"
    #import "AMAAppMetricaCrashesConfiguration.h"
    #import "AMAAppMetricaPluginReporting.h"
    #import "AMAAppMetricaPlugins.h"
    #import "AMACrashProcessingReporting.h"
    #import "AMAError.h"
    #import "AMAErrorRepresentable.h"
    #import "AMAPluginErrorDetails.h"
    #import "AMAStackTraceElement.h"
#else
    #import <AppMetricaCrashes/AMAAppMetricaCrashes.h>
    #import <AppMetricaCrashes/AMAAppMetricaCrashesConfiguration.h>
    #import <AppMetricaCrashes/AMAAppMetricaPluginReporting.h>
    #import <AppMetricaCrashes/AMAAppMetricaPlugins.h>
    #import <AppMetricaCrashes/AMACrashProcessingReporting.h>
    #import <AppMetricaCrashes/AMAError.h>
    #import <AppMetricaCrashes/AMAErrorRepresentable.h>
    #import <AppMetricaCrashes/AMAPluginErrorDetails.h>
    #import <AppMetricaCrashes/AMAStackTraceElement.h>
#endif
