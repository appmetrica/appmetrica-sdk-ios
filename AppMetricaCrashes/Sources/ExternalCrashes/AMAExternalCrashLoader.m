
#import "AMAExternalCrashLoader.h"
#import "AMACrashLoaderDelegate.h"
#import "AMACrashProviding.h"
#import "AMACrashEventConverter.h"
#import "AMACrashSafeTransactor.h"
#import "AMADecodedCrash.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaCrashes/AppMetricaCrashes.h>

static NSString *const kAMAExternalLoadingTransactionID = @"ExternalCrashLoadingReports";
static NSString *const kAMAExternalNotifyTransactionID = @"ExternalCrashNotifyReports";

@interface AMAExternalCrashLoader ()

@property (nonatomic, strong) id<AMAAsyncExecuting> executor;
@property (nonatomic, strong) NSHashTable *providers;
@property (nonatomic, strong) AMACrashSafeTransactor *transactor;
@property (nonatomic, strong) AMACrashEventConverter *converter;

@end

@implementation AMAExternalCrashLoader

@synthesize delegate = _delegate;

- (instancetype)initWithExecutor:(id<AMAAsyncExecuting>)executor
                      transactor:(AMACrashSafeTransactor *)transactor
                       converter:(AMACrashEventConverter *)converter
{
    self = [super init];
    if (self != nil) {
        _executor = executor;
        _providers = [NSHashTable weakObjectsHashTable];
        _transactor = transactor;
        _converter = converter;
    }
    return self;
}

#pragma mark - Provider Registration

- (void)registerProvider:(id<AMACrashProviding>)provider
{
    if (provider == nil) {
        return;
    }
    [self.executor execute:^{
        [self.providers addObject:provider];

        if ([provider respondsToSelector:@selector(setDelegate:)]) {
            provider.delegate = self;
        }
    }];
}

#pragma mark - AMACrashLoading

- (void)loadCrashReports
{
    [self.executor execute:^{
        for (id<AMACrashProviding> provider in self.providers) {
            [self processPendingReportsFromProvider:provider];
        }
    }];
}

#pragma mark - AMACrashProviderDelegate

- (void)crashProvider:(id<AMACrashProviding>)provider
       didDetectCrash:(AMACrashEvent *)report
{
    [self.executor execute:^{
        [self processCrash:report fromProvider:provider isANR:NO];
    }];
}

- (void)crashProvider:(id<AMACrashProviding>)provider
         didDetectANR:(AMACrashEvent *)report
{
    [self.executor execute:^{
        [self processCrash:report fromProvider:provider isANR:YES];
    }];
}

#pragma mark - Private

- (void)processPendingReportsFromProvider:(id<AMACrashProviding>)provider
{
    if ([provider respondsToSelector:@selector(pendingCrashReports)] == NO) {
        return;
    }
    
    NSArray<AMACrashEvent *> *reports = [provider pendingCrashReports];
    if (reports.count == 0) {
        return;
    }
    
    NSMutableArray<AMACrashEvent *> *processedReports = [NSMutableArray array];
    
    for (AMACrashEvent *report in reports) {
        NSString *identifier = report.info.identifier ?: [[NSUUID UUID] UUIDString];
        NSString *transactionName = [NSString stringWithFormat:@"PendingReport_%@", identifier];
        
        [self.transactor processTransactionWithID:kAMAExternalLoadingTransactionID
                                             name:transactionName
                                      transaction:^{
            AMADecodedCrash *decoded = [self.converter decodedCrashFromCrashEvent:report];
            [self.delegate crashLoader:self didLoadCrash:decoded withError:nil];
            [processedReports addObject:report];
        }];
    }
    
    [self notifyProvider:provider didProcessReports:processedReports];
}

- (void)processCrash:(AMACrashEvent *)event
        fromProvider:(id<AMACrashProviding>)provider
               isANR:(BOOL)isANR
{
    NSString *identifier = event.info.identifier ?: [[NSUUID UUID] UUIDString];
    NSString *transactionName = [NSString stringWithFormat:@"NotifyReport_%@", identifier];

    __block BOOL processed = NO;
    [self.transactor processTransactionWithID:kAMAExternalNotifyTransactionID
                                         name:transactionName
                                  transaction:^{
        AMADecodedCrash *decoded = [self.converter decodedCrashFromCrashEvent:event];
        if (isANR == YES) {
            [self.delegate crashLoader:self didLoadANR:decoded withError:nil];
        }
        else {
            [self.delegate crashLoader:self didLoadCrash:decoded withError:nil];
        }
        processed = YES;
    }];

    if (processed) {
        [self notifyProvider:provider didProcessReports:@[event]];
    }
}

- (void)notifyProvider:(id<AMACrashProviding>)provider
    didProcessReports:(NSArray<AMACrashEvent *> *)reports
{
    if (reports.count > 0 && [provider respondsToSelector:@selector(didProcessCrashReports:)]) {
        [provider didProcessCrashReports:reports];
    }
}

@end
