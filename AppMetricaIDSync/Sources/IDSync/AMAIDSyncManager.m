
#import "AMAIDSyncManager.h"
#import "AMAIDSyncRequest.h"
#import "AMAIDSyncCore.h"
#import "AMAIDSyncStartupConfiguration.h"
#import "AMAIDSyncExecutionConditionProvider.h"
#import "AMAIDSyncRequestsConverter.h"
#import <AppMetricaNetwork/AppMetricaNetwork.h>
#import "AMAIDSyncNetworkRequest.h"
#import "AMAIDSyncReporter.h"
#import "AMAIDSyncPreconditionHandler.h"
#import "AMAIDSyncReportRequest.h"
#import "AMAIDSyncRequestResponse.h"

static NSUInteger const kAMAIDSyncDefaultRepeatInterval = 60;
static NSUInteger const AMAIDSyncDefaultLaunchDelaySeconds = 10;

@interface AMAIDSyncManager ()<AMATimerDelegate>

@property (nonatomic, assign) BOOL firstDelayPassed;

@property (nonatomic, strong, readwrite) AMAIDSyncStartupConfiguration *startup;
@property (nonatomic, strong, readonly) AMAIDSyncExecutionConditionProvider *conditionProvider;
@property (nonatomic, strong, readonly) AMAIDSyncRequestsConverter *converter;
@property (nonatomic, strong, readonly) AMAGenericRequestProcessor *requestProcessor;
@property (nonatomic, strong, readonly) AMAIDSyncReporter *reporter;
@property (nonatomic, strong, readonly) AMAIDSyncPreconditionHandler *preconditionHandler;

@property (nonatomic, strong) AMATimer *delayTimer;
@property (nonatomic, strong) NSTimer *repeatedTimer;
@property (nonatomic, strong) AMABlockTimer *reportRetryTimer;

@end

@implementation AMAIDSyncManager

- (instancetype)init
{
    return [self initWithConditionProvider:[[AMAIDSyncExecutionConditionProvider alloc] init]
                                 converter:[[AMAIDSyncRequestsConverter alloc] init]
                          requestProcessor:[[AMAGenericRequestProcessor alloc] init]
                                  reporter:[[AMAIDSyncReporter alloc] init]
                       preconditionHandler:[[AMAIDSyncPreconditionHandler alloc] init]
    ];
}

- (instancetype)initWithConditionProvider:(AMAIDSyncExecutionConditionProvider *)conditionProvider
                                converter:(AMAIDSyncRequestsConverter *)converter
                         requestProcessor:(AMAGenericRequestProcessor *)requestProcessor
                                 reporter:(AMAIDSyncReporter *)reporter
                      preconditionHandler:(AMAIDSyncPreconditionHandler *)preconditionHandler
{
    self = [super init];
    if (self) {
        _conditionProvider = conditionProvider;
        _converter = converter;
        _requestProcessor = requestProcessor;
        _reporter = reporter;
        _preconditionHandler = preconditionHandler;
        _firstDelayPassed = NO;
    }
    return self;
}

#pragma mark - Public -

- (void)startIfNeeded
{
    BOOL featureEnabled = self.startup.idSyncEnabled;
    AMALogInfo(@"Trying to launch id sync task with %@ feature", featureEnabled ? @"enabled" : @"disabled");
    if (featureEnabled) {
        if (self.firstDelayPassed) {
            [self launchRepeatedTimer];
            [self processRequests];
        } else {
            [self launchDelayTimer];
        }
    }
}

- (void)shutdown
{
    [self invalidateTimers];
}

#pragma mark - Private -

- (void)launchDelayTimer
{
    @synchronized (self) {
        AMALogInfo(@"Launch id sync delay timer");
        [self.delayTimer invalidate];
        self.delayTimer = nil;
        NSTimeInterval timeout = self.startup.launchDelaySeconds
        ? [self.startup.launchDelaySeconds integerValue]
        : AMAIDSyncDefaultLaunchDelaySeconds;
        AMATimer *timer = [[AMATimer alloc] initWithTimeout:timeout];
        timer.delegate = self;
        self.delayTimer = timer;
        [timer start];
    }
}

- (void)invalidateTimers
{
    AMALogInfo(@"Invalidating id sync timers");
    @synchronized (self) {
        [self.repeatedTimer invalidate];
        self.repeatedTimer = nil;
        [self.delayTimer invalidate];
        self.delayTimer = nil;
        [self invalidateReportRetryTimer];
    }
}

- (void)launchRepeatedTimer
{
    @synchronized (self) {
        AMALogInfo(@"Launch id sync repeated timer");
        [self invalidateTimers];
        self.repeatedTimer = [NSTimer scheduledTimerWithTimeInterval:kAMAIDSyncDefaultRepeatInterval
                                                              target:self
                                                            selector:@selector(processRequests)
                                                            userInfo:nil
                                                             repeats:YES];
    }
}

- (void)processRequests
{
    NSArray<AMAIDSyncRequest *> *requests = [self.converter convertDictToRequests:self.startup.requests];
    for (AMAIDSyncRequest *request in requests) {
        id<AMAExecutionCondition> condition = [self.conditionProvider executionConditionWithRequest:request];
        if ([condition shouldExecute]) {
            AMALogInfo(@"Trying to process id sync http request with url: %@", request.url);
            [self.preconditionHandler canExecuteRequestWithPreconditions:request.preconditions
                                                              completion:^(BOOL isAllowed) {
                if (isAllowed) {
                    [self performRequest:request];
                }
            }];
        }
    }
}

- (void)performRequest:(AMAIDSyncRequest *)request
{
    AMAIDSyncNetworkRequest *networkRequest = [[AMAIDSyncNetworkRequest alloc] initWithURL:request.url
                                                                                   headers:request.headers];
    [self.requestProcessor processRequest:networkRequest
                                 callback:^(NSData * _Nullable data,
                                            NSHTTPURLResponse * _Nullable response,
                                            NSError * _Nullable error) {
        BOOL isNetworkError = (error != nil && [error.domain isEqualToString:NSURLErrorDomain]);

        if (isNetworkError == NO) {
            NSInteger statusCode = response.statusCode;
            NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSDictionary *responseHeaders = [self responseHeaders:response];
            NSString *responseURLString = response.URL.absoluteString ?: request.url;
            
            __auto_type *requestResponse = [[AMAIDSyncRequestResponse alloc] initWithRequest:request
                                                                                        code:statusCode
                                                                                        body:responseBody
                                                                                     headers:responseHeaders
                                                                                 responseURL:responseURLString];
            
            if (request.reportEventEnabled) {
                [self.reporter reportEventForResponse:requestResponse];
            }

            if (request.reportUrl != nil && request.reportUrl.length > 0) {
                [self sendReportRequestForResponse:requestResponse];
            }

            [self.conditionProvider execute:request statusCode:@(statusCode)];
        }
    }];
}

#pragma mark - AMATimerDelegate -

- (void)timerDidFire:(AMATimer *)timer
{
    @synchronized (self) {
        self.firstDelayPassed = YES;
        [self launchRepeatedTimer];
        [self processRequests];
    }
}

#pragma mark - Startup update -

- (void)startupUpdatedWithConfiguration:(AMAIDSyncStartupConfiguration *)configuration
{
    @synchronized (self) {
        self.startup = configuration;
        [self invalidateTimers];
        [self startIfNeeded];
    }
}

#pragma mark - Report request -

- (void)sendReportRequestForResponse:(AMAIDSyncRequestResponse *)response
{
    [self performReportRequestForResponse:response interval:1.0];
}

- (void)performReportRequestForResponse:(AMAIDSyncRequestResponse *)response
                               interval:(NSTimeInterval)interval
{
    AMAIDSyncReportRequest *reportRequest = [[AMAIDSyncReportRequest alloc] initWithResponse:response];

    [self.requestProcessor processRequest:reportRequest
                                 callback:^(NSData * _Nullable responseData,
                                            NSHTTPURLResponse * _Nullable httpResponse,
                                            NSError * _Nullable error) {
        [self handleReportResponse:httpResponse
                             error:error
                          response:response
                          interval:interval];
    }];
}

- (void)handleReportResponse:(NSHTTPURLResponse *)httpResponse
                       error:(NSError *)error
                    response:(AMAIDSyncRequestResponse *)response
                    interval:(NSTimeInterval)interval
{
    NSInteger statusCode = httpResponse.statusCode;
    
    BOOL success = (statusCode >= 200 && statusCode < 300);
    BOOL clientError = (statusCode >= 400 && statusCode < 500);
    
    BOOL shouldRetry = success == NO && clientError == NO;
    
    if (shouldRetry) {
        [self launchRetryTimerWithResponse:response interval:interval];
    }
}

- (void)launchRetryTimerWithResponse:(AMAIDSyncRequestResponse *)response
                            interval:(NSTimeInterval)interval
{
    [self invalidateReportRetryTimer];
    if (interval < 60) {
        [self launchReportRetryTimer:interval response:response];
    }
}

- (void)invalidateReportRetryTimer
{
    @synchronized (self) {
        [self.reportRetryTimer invalidate];
        self.reportRetryTimer = nil;
    }
}

- (void)launchReportRetryTimer:(NSTimeInterval)interval
                      response:(AMAIDSyncRequestResponse *)response
{
    @synchronized (self) {
        __weak typeof(self) weakSelf = self;
        self.reportRetryTimer = [[AMABlockTimer alloc] initWithTimeout:interval
                                                         callbackQueue:nil
                                                                 block:^(AMABlockTimer * _Nonnull sender) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf performReportRequestForResponse:response interval:interval * 2];
            }
        }];
        [self.reportRetryTimer start];
    }
}

#pragma mark - Helpers -

- (NSDictionary<NSString *, NSArray<NSString *> *> *)responseHeaders:(NSHTTPURLResponse *)response
{
    NSDictionary *rawHeaders = response.allHeaderFields;
    NSMutableDictionary *normalizedHeaders = [NSMutableDictionary dictionary];
    [rawHeaders enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (key && obj) {
            NSString *headerName = [key description];
            NSString *headerValue = [obj description];
            normalizedHeaders[headerName] = @[headerValue];
        }
    }];
    return normalizedHeaders;
}

@end
