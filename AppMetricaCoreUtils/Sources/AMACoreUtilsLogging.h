
#import <AppMetricaLog/AMALogFlags.h>

#ifdef AMA_LOG_CHANNEL
#undef AMA_LOG_CHANNEL
#endif /* AMA_LOG_CHANNEL */

#define AMA_LOG_CHANNEL @"AppMetricaCoreUtils"

#import <AppMetricaLog/AppMetricaLog.h>
