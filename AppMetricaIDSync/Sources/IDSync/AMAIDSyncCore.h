
#ifndef AMA_RELEASE
#define AMA_RELEASE 0
#endif

#if AMA_RELEASE

#define AMA_ALLOW_DESCRIPTIONS 0
#define AMA_ALLOW_INTERNAL_LOG 0
#define AMA_ALLOW_BACKTRACE_LOG 0

#else // AMA_RELEASE

#define AMA_ALLOW_DESCRIPTIONS 1
#define AMA_ALLOW_INTERNAL_LOG 1

#ifndef NDEBUG
#define AMA_ALLOW_BACKTRACE_LOG 1
#else // NDEBUG
#define AMA_ALLOW_BACKTRACE_LOG 0
#endif // NDEBUG

#endif // AMA_RELEASE

#define AMA_LOG_CHANNEL @"AppMetricaIDSync"

#import <AppMetricaCore/AppMetricaCore.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaLog/AppMetricaLog.h>
