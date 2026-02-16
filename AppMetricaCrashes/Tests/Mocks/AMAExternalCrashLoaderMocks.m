
#import "AMAExternalCrashLoaderMocks.h"
#import "AMACrashEvent.h"

#pragma mark - Mock Pull Provider

@implementation AMAExternalLoaderMockPullProvider

@synthesize delegate = _delegate;

- (NSArray<AMACrashEvent *> *)pendingCrashReports
{
    return self.reports;
}

- (void)didProcessCrashReports:(NSArray<AMACrashEvent *> *)processedReports
{
    self.processedEvents = processedReports;
}

@end

#pragma mark - Mock Push Provider

@implementation AMAExternalLoaderMockPushProvider

- (void)didProcessCrashReports:(NSArray<AMACrashEvent *> *)processedReports
{
    self.processedEvents = processedReports;
}

@end

#pragma mark - Mock Delegate

@implementation AMAExternalLoaderMockDelegate

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _receivedCrashes = [NSMutableArray array];
        _receivedANRs = [NSMutableArray array];
        _receivedLoaders = [NSMutableArray array];
    }
    return self;
}

- (void)crashLoader:(id<AMACrashLoading>)crashLoader
       didLoadCrash:(AMADecodedCrash *)decodedCrash
          withError:(NSError *)error
{
    if (decodedCrash != nil) {
        [self.receivedCrashes addObject:decodedCrash];
    }
    [self.receivedLoaders addObject:crashLoader];
    [self.didLoadCrashExpectation fulfill];
}

- (void)crashLoader:(id<AMACrashLoading>)crashLoader
         didLoadANR:(AMADecodedCrash *)decodedCrash
          withError:(NSError *)error
{
    if (decodedCrash != nil) {
        [self.receivedANRs addObject:decodedCrash];
    }
    [self.receivedLoaders addObject:crashLoader];
    [self.didLoadANRExpectation fulfill];
}

- (void)crashLoader:(id<AMACrashLoading>)crashLoader
didDetectProbableUnhandledCrash:(AMAUnhandledCrashType)crashType
{
}

@end
