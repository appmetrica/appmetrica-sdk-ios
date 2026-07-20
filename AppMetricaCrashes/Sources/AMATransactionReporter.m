
#import "AMATransactionReporter.h"
#import "AMACrashReporter.h"
#import <AppMetricaCore/AppMetricaCore.h>

@interface AMATransactionReporter ()

@property (nonatomic, strong, readonly) id<AMAAppMetricaReporting> libraryReporter;
@property (nonatomic, copy, readonly) NSString *apiKey;

@end

@implementation AMATransactionReporter

@synthesize libraryReporter = _libraryReporter;

- (instancetype)init
{
    return [self initWithApiKey:kAppMetricaLibraryAPIKey];
}

- (instancetype)initWithApiKey:(NSString *)apiKey
{
    self = [super init];
    if (self != nil) {
        _apiKey = [apiKey copy];
    }
    return self;
}

- (id<AMAAppMetricaReporting>)libraryReporter
{
    @synchronized (self) {
        if (_libraryReporter == nil) {
            _libraryReporter = [AMAAppMetrica reporterForAPIKey:self.apiKey];
        }
        return _libraryReporter;
    }
}


#pragma mark - AMATransactionReporting

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
    
    [self.libraryReporter reportEvent:@"TransactionFailure"
                           parameters:@{ parametersKey: [parameters copy] }
                            onFailure:nil];
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

@end
