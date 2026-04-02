
#import <Foundation/Foundation.h>

#if __has_include("AMAErrorUtilities.h")
    #import "AMAErrorUtilities.h"
#else
    #import <AppMetricaCoreUtils/AMAErrorUtilities.h>
#endif

extern NSErrorDomain const kAMAAppMetricaErrorDomain __attribute__((deprecated("Use AMAAppMetricaErrorDomain instead")));

extern NSErrorDomain const kAMAAppMetricaInternalErrorDomain __attribute__((deprecated("Use AMAAppMetricaInternalErrorDomain instead")));
extern NSErrorDomain const kAMAAppMetricaDatabaseErrorDomain __attribute__((deprecated("Use AMAAppMetricaDatabaseErrorDomain instead")));

static const NSUInteger AMAAppMetricaEventErrorCodeInitializationError __attribute__((deprecated("Use AMAAppMetricaEventErrorCodeIsNotActivated instead"))) = AMAAppMetricaEventErrorCodeIsNotActivated;

static const NSUInteger AMAAppMetricaInternalEventJsonSerializationError __attribute__((deprecated("Use AMAAppMetricaInternalEventErrorCodeJsonSerialization instead"))) = AMAAppMetricaInternalEventErrorCodeJsonSerialization;
