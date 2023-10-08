
#import "AMAInternalEventsReporter+Private.h"
#import "AMAReporter.h"
#import "AMAReporterProviding.h"
#import "AMAEventTypes.h"
#import <AppMetricaHostState/AppMetricaHostState.h>

static NSString *const kAMASchemaInconsistencyEventName = @"SchemaInconsistencyDetected";
static NSString *const kAMASchemaInconsistencyEventParametersDescriptionKey = @"schema: ";

static NSString *const kAMATransactionFailureEventName = @"TransactionFailure";
static NSString *const kAMATransactionFailureEventParametersTransactionNameKey = @"name";
static NSString *const kAMATransactionFailureEventParametersRollbackResultKey = @"rollback";
static NSString *const kAMATransactionFailureEventParametersRollbackContentKey = @"rollbackcontent";
static NSString *const kAMATransactionFailureEventParametersExceptionParametersKey = @"exception";

static NSString *const kAMASearchAdsAttemptEventName = @"AppleSearchAdsAttempt";
static NSString *const kAMASearchAdsTokenSuccessEventName = @"AppleSearchAdsTokenSuccess";

static NSString *const kAMASearchAdsCompletionEventName = @"AppleSearchAdsCompletion";
static NSString *const kAMASearchAdsCompletionEventParametersTypeKey = @"type";
static NSString *const kAMASearchAdsCompletionEventParametersTypeAbsentValue = @"null";

static NSString *const kAMAInternalEventsReporterExceptionDescriptionNameKey = @"name";
static NSString *const kAMAInternalEventsReporterExceptionDescriptionReasonKey = @"reason";
static NSString *const kAMAInternalEventsReporterExceptionDescriptionBacktraceKey = @"backtrace";
static NSString *const kAMAInternalEventsReporterExceptionDescriptionUserInfoKey = @"userInfo";

@interface AMAInternalEventsReporter ()

@property (nonatomic, strong, readonly) id<AMAExecuting> executor;
@property (nonatomic, strong, readonly) id<AMAReporterProviding> reporterProvider;

@property (nonatomic, strong) id<AMAHostStateProviding> hostStateProvider;

@end

@implementation AMAInternalEventsReporter

- (instancetype)initWithExecutor:(id<AMAExecuting>)executor
                reporterProvider:(id<AMAReporterProviding>)reporterProvider
{
    return [self initWithExecutor:executor
                 reporterProvider:reporterProvider
                hostStateProvider:[[AMAHostStateProvider alloc] init]];
}

- (instancetype)initWithExecutor:(id<AMAExecuting>)executor
                reporterProvider:(id<AMAReporterProviding>)reporterProvider
               hostStateProvider:(id<AMAHostStateProviding>)hostStateProvider
{
    self = [super init];
    if (self != nil) {
        _executor = executor;
        _reporterProvider = reporterProvider;
        _hostStateProvider = hostStateProvider;
        _hostStateProvider.delegate = self;
    }
    return self;
}

- (void)reportEvent:(NSString *)event parameters:(NSDictionary *)parameters
{
    [self.executor execute:^{
        id<AMAAppMetricaReporting> reporter = [self.reporterProvider reporter];
        [reporter reportEvent:event parameters:parameters onFailure:nil];
    }];
}

- (void)reportSchemaInconsistencyWithDescription:(NSString *)inconsistencyDescription
{
    NSDictionary *parameters = nil;
    if (inconsistencyDescription != nil) {
        parameters = @{ kAMASchemaInconsistencyEventParametersDescriptionKey : inconsistencyDescription };
    }
    [self reportEvent:kAMASchemaInconsistencyEventName parameters:parameters];
}

- (void)reportFailedTransactionWithID:(NSString *)transactionID
                            ownerName:(NSString *)ownerName
                      rollbackContent:(NSString *)rollbackContent
                    rollbackException:(NSException *)rollbackException
                       rollbackFailed:(BOOL)rollbackFailed
{
    NSString *parametersKey = transactionID ?: @"Unknown";
    NSDictionary *exceptionParameters = [[self class] descriptionParametersForException:rollbackException];

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[kAMATransactionFailureEventParametersTransactionNameKey] = ownerName;
    parameters[kAMATransactionFailureEventParametersExceptionParametersKey] = exceptionParameters;
    parameters[kAMATransactionFailureEventParametersRollbackContentKey] = rollbackContent;
    parameters[kAMATransactionFailureEventParametersRollbackResultKey] = rollbackFailed ? @"failed" : @"succeeded";

    [self reportEvent:kAMATransactionFailureEventName parameters:@{ parametersKey: [parameters copy] }];
}

- (void)reportSearchAdsAttempt
{
    [self reportEvent:kAMASearchAdsAttemptEventName parameters:nil];
}

- (void)reportSearchAdsTokenSuccess
{
    [self reportEvent:kAMASearchAdsTokenSuccessEventName parameters:nil];
}

- (void)reportSearchAdsCompletionWithType:(NSString *)completionType parameters:(NSDictionary *)parameters
{
    NSParameterAssert(completionType);
    NSString *completionTypeKey = completionType ?: kAMASearchAdsCompletionEventParametersTypeAbsentValue;
    NSDictionary *eventParameters = nil;
    if (parameters == nil) {
        eventParameters = @{ kAMASearchAdsCompletionEventParametersTypeKey: completionTypeKey };
    }
    else {
        eventParameters = @{ kAMASearchAdsCompletionEventParametersTypeKey: @{ completionTypeKey: parameters } };
    }
    [self reportEvent:kAMASearchAdsCompletionEventName parameters:eventParameters];
}

- (void)reportExtensionsReportWithParameters:(NSDictionary *)parameters
{
    [self reportEvent:@"extensions_list" parameters:parameters];
}

- (void)reportExtensionsReportCollectingException:(NSException *)exception
{
    NSDictionary *parameters = nil;
    if (exception.name != nil) {
        parameters = @{ exception.name: exception.reason ?: @"Unknown reason" };
    }
    [self reportEvent:@"extensions_list_collecting_exception" parameters:parameters];
}

- (void)reportCorruptedCrashReportWithError:(NSError *)error
{
    [self reportEvent:@"corrupted_crash_report" withError:error];
}

- (void)reportUnsupportedCrashReportVersionWithError:(NSError *)error
{
    [self reportEvent:@"crash_report_version_unsupported" withError:error];
}

- (void)reportRecrashWithError:(NSError *)error
{
    [self reportEvent:@"crash_report_recrash" withError:error];
}

- (void)reportSKADAttributionParsingError:(NSDictionary *)parameters
{
    [self reportEvent:@"skad_attribution_parsing_error" parameters:parameters];
}

- (void)reportEventFileNotFoundForEventWithType:(NSUInteger)eventType
{
    NSDictionary *parameters = @{ @"event_type": @(eventType) };
    switch (eventType) {
        case AMAEventTypeProtobufCrash:
        case AMAEventTypeProtobufANR:
            // TODO(bamx23): Drop this event?
            [self reportEvent:@"empty_crash" parameters:parameters];
            break;

        default:
            [self reportEvent:@"event_value_file_not_found" parameters:parameters];
            break;
    }
}

#pragma mark - Utils -

- (void)reportEvent:(NSString *)event withError:(NSError *)error
{
    NSDictionary *parameters = @{
        @"domain" : error.domain ?: @"<unknown>",
        @"error_code" : @(error.code),
        @"error_details" : error.userInfo.description ?: @"No error details supplied",
    };
    [self reportEvent:event parameters:parameters];
}

+ (NSDictionary *)descriptionParametersForException:(NSException *)exception
{
    if (exception == nil) {
        return nil;
    }

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[kAMAInternalEventsReporterExceptionDescriptionNameKey] = exception.name;
    parameters[kAMAInternalEventsReporterExceptionDescriptionReasonKey] = exception.reason;
    parameters[kAMAInternalEventsReporterExceptionDescriptionBacktraceKey] = exception.callStackSymbols;
    parameters[kAMAInternalEventsReporterExceptionDescriptionUserInfoKey] = exception.userInfo;

    return [parameters copy];
}

#pragma mark - AMAHostStateProviderDelegate delegate -

- (void)hostStateDidChange:(AMAHostAppState)hostState
{
    AMALogInfo(@"state: %lu", (unsigned long)hostState);
    switch (hostState) {
        case AMAHostAppStateForeground:
            [[self.reporterProvider reporter] resumeSession];
            break;
        case AMAHostAppStateBackground:
            [[self.reporterProvider reporter] pauseSession];
            break;
        default:
            break;
    }
}

@end
