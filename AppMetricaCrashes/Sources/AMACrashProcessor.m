
#import "AMACrashLogging.h"
#import "AMACrashProcessor.h"
#import "AMADecodedCrash.h"
#import "AMACrashReportCrash.h"
#import "AMACrashReportError.h"
#import "AMASignal.h"
#import "AMADecodedCrashSerializer.h"
#import "AMAInfo.h"
#import "AMACrashProcessingReporting.h"
#import "AMACrashEventType.h"
#import "AMADecodedCrashSerializer+CustomEventParameters.h"
#import "AMAExceptionFormatter.h"
#import "AMAErrorModel.h"

@interface AMACrashProcessor ()

@property (nonatomic, strong, readonly) AMADecodedCrashSerializer *serializer;
@property (nonatomic, strong, readonly) AMAExceptionFormatter *formatter;

@end

@implementation AMACrashProcessor

@synthesize extendedCrashReporters = _extendedCrashReporters;

- (instancetype)initWithIgnoredSignals:(NSArray *)ignoredSignals
                            serializer:(AMADecodedCrashSerializer *)serializer
{
    return [self initWithIgnoredSignals:ignoredSignals
                             serializer:serializer
                              formatter:[[AMAExceptionFormatter alloc] init]];
}

- (instancetype)initWithIgnoredSignals:(NSArray *)ignoredSignals
                            serializer:(AMADecodedCrashSerializer *)serializer
                             formatter:(AMAExceptionFormatter *)formatter
{
    self = [super init];

    if (self != nil) {
        _serializer = serializer;
        _formatter = formatter;
        _ignoredCrashSignals = [ignoredSignals copy];
        _extendedCrashReporters = [NSMutableSet set];
    }

    return self;
}

- (void)processCrash:(AMADecodedCrash *)decodedCrash withError:(NSError *)error
{
    if (error != nil) {
        [self reportCrashReportErrorToMetrica:decodedCrash withError:error];
        return;
    }

    if ([self shouldIgnoreCrash:decodedCrash]) { return; }
    
    AMACustomEventParameters *encodedCrash = [self.serializer eventParametersFromDecodedData:decodedCrash
                                                                                forEventType:AMACrashEventTypeCrash];
    
    [AMAAppMetrica reportEventWithParameters:encodedCrash onFailure:^(NSError *error) {
        if (error != nil) {
            AMALogError(@"Failed to report app crash with error: %@", error);
            [self reportCrashReportErrorToMetrica:decodedCrash withError:error];
        }
    }];
    
    [self reportSafely];
}

- (void)processANR:(AMADecodedCrash *)decodedCrash withError:(NSError *)error
{
    if (error != nil) {
        [self reportCrashReportErrorToMetrica:decodedCrash withError:error];
        return;
    }

    AMACustomEventParameters *parameters = [self.serializer eventParametersFromDecodedData:decodedCrash
                                                                              forEventType:AMACrashEventTypeANR];
    
    [AMAAppMetrica reportEventWithParameters:parameters onFailure:^(NSError *error) {
        if (error != nil) {
            AMALogError(@"Failed to report app ANR with error: %@", error);
            [self reportCrashReportErrorToMetrica:decodedCrash withError:error];
        }
    }];
}

- (void)processError:(AMAErrorModel *)errorModel onFailure:(void (^)(NSError *))onFailure
{
    NSError *potentialError = nil;
    NSData *formattedData = [self.formatter formattedError:errorModel];
    
    if (formattedData == nil) {
        onFailure(potentialError);
        return;
    }
    
    AMACustomEventParameters *params = [[AMACustomEventParameters alloc] initWithEventType:AMACrashEventTypeError];
    params.valueType = AMAEventValueTypeBinary;
    params.data = formattedData;
    params.GZipped = YES;
    params.bytesTruncated = errorModel.bytesTruncated;
    
    [AMAAppMetrica reportEventWithParameters:params onFailure:onFailure];
}

#pragma mark - Private

- (BOOL)shouldIgnoreCrash:(AMADecodedCrash *)decodedCrash
{
    return [self.ignoredCrashSignals containsObject:@(decodedCrash.crash.error.signal.signal)];
}

- (void)reportCrashReportErrorToMetrica:(AMADecodedCrash *)decodedCrash withError:(NSError *)error
{
    switch (error.code) {
        case AMAAppMetricaEventErrorCodeInvalidName:
            [[AMAAppMetrica sharedInternalEventsReporter] reportCorruptedCrashReportWithError:error];
            break;
        case AMAAppMetricaInternalEventErrorCodeRecrash:
            [[AMAAppMetrica sharedInternalEventsReporter] reportRecrashWithError:error];
            break;
        case AMAAppMetricaInternalEventErrorCodeUnsupportedReportVersion:
            [[AMAAppMetrica sharedInternalEventsReporter] reportUnsupportedCrashReportVersionWithError:error];
            break;
        default:
            break;
    }
}

- (void)reportSafely
{
    for (id<AMACrashProcessingReporting> crashReporter in self.extendedCrashReporters) {
        if (crashReporter != nil) {
            [crashReporter reportCrash:@"Unhandled crash"];
        }
    }
}

@end
