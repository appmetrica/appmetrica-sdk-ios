
#import "AMADecodedCrashSerializer+CustomEventParameters.h"

#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import "AMACrashReportCrash.h"
#import "AMACrashReportError.h"
#import "AMADecodedCrash.h"
#import "AMAInfo.h"

@implementation AMADecodedCrashSerializer (CustomEventParameters)

- (AMACustomEventParameters *)eventParametersFromDecodedData:(AMADecodedCrash *)decodedCrash
                                                forEventType:(AMACrashEventType)eventType
{
    NSData *rawData = [self dataForCrash:decodedCrash];
    
    AMACustomEventParameters *encodedEvent = [[AMACustomEventParameters alloc] initWithEventType:eventType];
    encodedEvent.valueType = AMAEventValueTypeFile;
    encodedEvent.data = rawData;
    encodedEvent.creationDate = decodedCrash.info.timestamp;
    encodedEvent.appState = decodedCrash.appState;
    encodedEvent.errorEnvironment = decodedCrash.errorEnvironment;
    encodedEvent.appEnvironment = decodedCrash.appEnvironment;
    
    return encodedEvent;
}

- (AMACustomEventParameters *)eventParametersFromDecodedData:(AMADecodedCrash *)decodedCrash
{
    AMACrashEventType type = decodedCrash.crash.error.type == AMACrashTypeMainThreadDeadlock
        ? AMACrashEventTypeANR
        : AMACrashEventTypeCrash;
    
    return [self eventParametersFromDecodedData:decodedCrash forEventType:type];
}

@end
