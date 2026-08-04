
#import <AppMetricaLog/AMALogFlags.h>

#ifdef AMA_LOG_CHANNEL
#undef AMA_LOG_CHANNEL
#endif /* AMA_LOG_CHANNEL */

#define AMA_LOG_CHANNEL @"AppMetricaCrashes"

#import <AppMetricaCore/AppMetricaCore.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaLog/AppMetricaLog.h>
