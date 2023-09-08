
#if __has_include("AppMetricaCore.h")
    #import "AppMetricaCore.h"
//TODO: Remove after crashes
    #import "AMAAppMetricaConfiguration+Extended.h"
#else
    #import <AppMetricaCore/AppMetricaCore.h>
    #import <AppMetricaCore/AMAAppMetricaConfiguration+Extended.h>
#endif
