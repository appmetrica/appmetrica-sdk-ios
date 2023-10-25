#import "AMACrashLogging.h"

#import "AMACrashReporter.h"

#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

#import "AMACrashProcessingReporting.h"

static NSString *const kAppMetricaAPIKey = @"20799a27-fa80-4b36-b2db-0f8141f24180";

@interface AMACrashReporter ()

@property (nonatomic, strong, readonly) id<AMAAppMetricaReporting> reporter;

@end

@implementation AMACrashReporter

- (instancetype)init
{
    return [self initWithReporter:[AMAAppMetrica reporterForApiKey:kAppMetricaAPIKey]];
}

- (instancetype)initWithReporter:(id<AMAAppMetricaReporting>)reporter
{
    self = [super init];
    if (self != nil) {
        _extendedCrashReporters = [NSMutableSet set];
        _reporter = reporter;
    }
    return self;
}

#pragma mark - Public -

- (void)reportCrashWithParameters:(nonnull AMACustomEventParameters *)parameters 
{
    [AMAAppMetrica reportEventWithParameters:parameters onFailure:^(NSError *error) {
        if (error != nil) {
            AMALogError(@"Failed to report app crash with error: %@", error);
            [self reportErrorToAppMetricaWithError:error eventName:@"internal_error_crash"];
        }
    }];
    
    [self reportExtendedCrashes];
}

- (void)reportANRWithParameters:(nonnull AMACustomEventParameters *)parameters 
{
    [AMAAppMetrica reportEventWithParameters:parameters onFailure:^(NSError *error) {
        if (error != nil) {
            AMALogError(@"Failed to report app ANR with error: %@", error);
            [self reportErrorToAppMetricaWithError:error eventName:@"internal_error_anr"];
        }
    }];
}

- (void)reportErrorWithParameters:(nonnull AMACustomEventParameters *)parameters
                        onFailure:(void (^)(NSError *))onFailure;
{
    [AMAAppMetrica reportEventWithParameters:parameters onFailure:onFailure];
}

- (void)reportInternalError:(NSError *)error
{
    NSString *eventName;
    
    switch (error.code) {
        case AMAAppMetricaEventErrorCodeInvalidName:
            eventName = @"corrupted_crash_report_invalid_name";
            break;
        case AMAAppMetricaInternalEventErrorCodeRecrash:
            eventName = @"crash_report_recrash";
            break;
        case AMAAppMetricaInternalEventErrorCodeUnsupportedReportVersion:
            eventName = @"crash_report_version_unsupported";
            break;
        default:
            return;
    }
    
    [self reportErrorToAppMetricaWithError:error eventName:eventName];
}

- (void)reportInternalCorruptedCrash:(NSError *)error
{
    [self reportErrorToAppMetricaWithError:error eventName:@"corrupted_crash_report"];
}

- (void)reportInternalCorruptedError:(NSError *)error
{
    [self reportErrorToAppMetricaWithError:error eventName:@"corrupted_error_report"];
}

#pragma mark - Private -

- (void)reportErrorToAppMetricaWithError:(NSError *)error eventName:(NSString *)eventName
{
    NSDictionary *parameters = @{
        @"domain" : error.domain ?: @"<unknown>",
        @"error_code" : @(error.code),
        @"error_details" : error.userInfo.count > 0 ? error.userInfo.description : @"No error details supplied",
    };
    
    [self.reporter reportEvent:eventName parameters:parameters onFailure:nil];
}

- (void)reportExtendedCrashes
{
    for (id<AMACrashProcessingReporting> crashReporter in self.extendedCrashReporters) {
        if (crashReporter != nil) {
            [crashReporter reportCrash:@"Unhandled crash"];
        }
    }
}

- (NSDictionary *)descriptionParametersForException:(NSException *)exception
{
    if (exception == nil) {
        return nil;
    }

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"name"] = exception.name;
    parameters[@"reason"] = exception.reason;
    parameters[@"backtrace"] = exception.callStackSymbols;
    parameters[@"userInfo"] = exception.userInfo;

    return [parameters copy];
}

#pragma mark - AMATransactionReporter

- (void)reportFailedTransactionWithID:(NSString *)transactionID
                            ownerName:(NSString *)ownerName
                      rollbackContent:(NSString *)rollbackContent
                    rollbackException:(NSException *)rollbackException
                       rollbackFailed:(BOOL)rollbackFailed
{
    NSString *parametersKey = transactionID ?: @"Unknown";
    NSDictionary *exceptionParameters = [self descriptionParametersForException:rollbackException];

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"name"] = ownerName;
    parameters[@"exception"] = exceptionParameters;
    parameters[@"rollbackcontent"] = rollbackContent;
    parameters[@"rollback"] = rollbackFailed ? @"failed" : @"succeeded";

    [self.reporter reportEvent:@"TransactionFailure" parameters:@{ parametersKey: [parameters copy] } onFailure:nil];
}

@end
