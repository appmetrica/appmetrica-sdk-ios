
#import <AppMetricaLog/AMALogFlags.h>

#ifdef AMA_LOG_CHANNEL
#undef AMA_LOG_CHANNEL
#endif /* AMA_LOG_CHANNEL */

#define AMA_LOG_CHANNEL @"AppMetricaCore"

#import "AMATime.h"
#import <AppMetricaLog/AppMetricaLog.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaCoreExtension.h>
