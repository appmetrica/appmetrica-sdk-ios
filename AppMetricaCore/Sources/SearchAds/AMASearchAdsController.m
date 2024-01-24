
#import "AMACore.h"
#import "AMASearchAdsController.h"
#import "AMASearchAdsRequester.h"
#import "AMASearchAdsReporter.h"
#import "AMAReporterStateStorage.h"

@interface AMASearchAdsController () <AMASearchAdsRequesterDelegate>

@property (nonatomic, strong, readonly) id<AMAAsyncExecuting> executor;
@property (nonatomic, strong, readonly) AMAReporterStateStorage *reporterStateStorage;
@property (nonatomic, strong, readonly) AMASearchAdsRequester *requester;
@property (nonatomic, strong, readonly) AMASearchAdsReporter *reporter;

@property (nonatomic, assign) BOOL inProgress;

@end

@implementation AMASearchAdsController

- (instancetype)initWithApiKey:(NSString *)apiKey
                      executor:(id<AMAAsyncExecuting>)executor
          reporterStateStorage:(AMAReporterStateStorage *)reporterStateStorage
{
    AMASearchAdsRequester *requester = [[AMASearchAdsRequester alloc] init];
    AMASearchAdsReporter *reporter = [[AMASearchAdsReporter alloc] initWithApiKey:apiKey];
    return [self initWithExecutor:executor
             reporterStateStorage:reporterStateStorage
                        requester:requester
                         reporter:reporter];
}

- (instancetype)initWithExecutor:(id<AMAAsyncExecuting>)executor
            reporterStateStorage:(AMAReporterStateStorage *)reporterStateStorage
                       requester:(AMASearchAdsRequester *)requester
                        reporter:(AMASearchAdsReporter *)reporter
{
    if (reporter == nil) {
        return nil;
    }
    
    self = [super init];
    if (self != nil) {
        _executor = executor;
        _reporterStateStorage = reporterStateStorage;
        _requester = requester;
        _reporter = reporter;

        requester.delegate = self;
    }
    return self;
}

- (void)trigger
{
    __weak __typeof(self) weakSelf = self;
    [self.executor execute:^{
        [weakSelf requestIfNeeded];
    }];
}

- (void)requestIfNeeded
{
    if ([self shouldRequest]) {
        [self request];
    }
}

- (BOOL)shouldRequest
{
    if (self.inProgress) {
        AMALogInfo(@"Another request is in progress");
        return NO;
    }

    if ([AMASearchAdsRequester isAPIAvailable] == NO) {
        AMALogInfo(@"Search Ads API is not available");
        return NO;
    }

    if (self.reporterStateStorage.emptyReferrerEventSent) {
        AMALogInfo(@"Attribution information has already been sent");
        return NO;
    }
    if (self.reporterStateStorage.referrerEventSent) {
        AMALogInfo(@"Attribution information has been marked as unavailable");
        return NO;
    }

    return YES;
}

- (void)request
{
    self.inProgress = YES;
    [self.reporter reportAttributionAttempt];
    [self.requester request];
}

- (void)markNoAttributionInfoWillBeSent
{
    [self.reporterStateStorage markEmptyReferrerEventSent];
}

- (void)complete
{
    self.inProgress = NO;
}

#pragma mark - AMASearchAdsRequesterDelegate

- (void)searchAdsRequester:(AMASearchAdsRequester *)requester didSucceededWithInfo:(NSDictionary *)info
{
    [self.executor execute:^{
        [self.reporter reportAttributionSuccessWithInfo:info];
        [self complete];
    }];
}

- (void)searchAdsRequester:(AMASearchAdsRequester *)requester didFailedWithError:(NSError *)error
{
    [self.executor execute:^{
        if ([error.domain isEqualToString:kAMASearchAdsRequesterErrorDomain]) {
            AMASearchAdsRequesterErrorCode errorCode = error.code;
            NSString *description = error.userInfo[kAMASearchAdsRequesterErrorDescriptionKey];
            if (errorCode == AMASearchAdsRequesterErrorAdTrackingLimited) {
                [self markNoAttributionInfoWillBeSent];
            }
            [self.reporter reportAttributionErrorWithCode:errorCode description:description];
        }
        [self complete];
    }];
}

@end
