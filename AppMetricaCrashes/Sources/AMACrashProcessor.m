
#import "AMACrashLogging.h"
#import "AMACrashProcessor.h"
#import "AMACrashEventType.h"
#import "AMACrashReportCrash.h"
#import "AMACrashReportError.h"
#import "AMADecodedCrash.h"
#import "AMADecodedCrashSerializer+CustomEventParameters.h"
#import "AMADecodedCrashSerializer.h"
#import "AMAErrorModel.h"
#import "AMAExceptionFormatter.h"
#import "AMAInfo.h"
#import "AMASignal.h"
#import "AMACrashReporter.h"

@interface AMACrashProcessor ()

@property (nonatomic, strong, readonly) AMADecodedCrashSerializer *serializer;
@property (nonatomic, strong, readonly) AMAExceptionFormatter *formatter;
@property (nonatomic, strong, readonly) AMACrashReporter *crashReporter;

@property (nonatomic, strong, readonly) NSArray<id<AMACrashProcessingReporting>> *extendedCrashProcessors;

@end

@implementation AMACrashProcessor

- (instancetype)initWithIgnoredSignals:(NSArray *)ignoredSignals
                            serializer:(AMADecodedCrashSerializer *)serializer
                         crashReporter:(AMACrashReporter *)crashReporter
                    extendedProcessors:(NSArray<id<AMACrashProcessingReporting>> *)extendedCrashProcessors
{
    return [self initWithIgnoredSignals:ignoredSignals
                             serializer:serializer
                          crashReporter:crashReporter
                              formatter:[[AMAExceptionFormatter alloc] init]
                     extendedProcessors:extendedCrashProcessors];
}

- (instancetype)initWithIgnoredSignals:(NSArray *)ignoredSignals
                            serializer:(AMADecodedCrashSerializer *)serializer
                         crashReporter:(AMACrashReporter *)crashReporter
                             formatter:(AMAExceptionFormatter *)formatter
                    extendedProcessors:(NSArray<id<AMACrashProcessingReporting>> *)extendedCrashProcessors
{
    self = [super init];

    if (self != nil) {
        _serializer = serializer;
        _formatter = formatter;
        _ignoredCrashSignals = [ignoredSignals copy];
        _crashReporter = crashReporter;
        _extendedCrashProcessors = extendedCrashProcessors;
    }

    return self;
}

#pragma mark - Public -

- (void)processCrash:(AMADecodedCrash *)decodedCrash withError:(NSError *)error
{
    if (error != nil) {
        [self.crashReporter reportInternalError:error];
        return;
    }

    if ([self shouldIgnoreCrash:decodedCrash]) { return; }
    
    NSError *localError = nil;
    AMAEventPollingParameters *parameters = [self.serializer eventParametersFromDecodedData:decodedCrash
                                                                               forEventType:AMACrashEventTypeCrash
                                                                                      error:&localError];
    
    if (parameters == nil) {
        [self.crashReporter reportInternalCorruptedCrash:localError];
    }
    
    [self.crashReporter reportCrashWithParameters:parameters];
}

- (void)processANR:(AMADecodedCrash *)decodedCrash withError:(NSError *)error
{
    if (error != nil) {
        [self.crashReporter reportInternalError:error];
        return;
    }
    
    NSError *localError = nil;
    AMAEventPollingParameters *parameters = [self.serializer eventParametersFromDecodedData:decodedCrash
                                                                               forEventType:AMACrashEventTypeANR
                                                                                      error:&localError];
    
    if (parameters == nil) {
        [self.crashReporter reportInternalCorruptedCrash:localError];
    }
    
    [self.crashReporter reportANRWithParameters:parameters];
}

- (void)processError:(NSError *)error
{
    [self.crashReporter reportNSError:error onFailure:nil];
}

#pragma mark - Private -

- (BOOL)shouldIgnoreCrash:(AMADecodedCrash *)decodedCrash
{
    return [self.ignoredCrashSignals containsObject:@(decodedCrash.crash.error.signal.signal)];
}

@end
