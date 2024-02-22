
#import "AMAReportControllingMock.h"

@implementation AMAReportControllingMock

@synthesize delegate;

- (void)cancelPendingRequests
{
    self.cancelCalled = YES;
}

- (void)reportRequestModelsFromArray:(nonnull NSArray<AMAReportRequestModel *> *)requestModels
{
    self.reportCalled = YES;
    self.reportModels = requestModels;
}

- (void)reset
{
    self.cancelCalled = NO;
    
    self.reportCalled = NO;
    self.reportModels = [NSArray array];
}

@end
