
#import <Foundation/Foundation.h>
#import "AMAProxyReportsController.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAReportControllingMock : NSObject<AMAReportsControlling>

@property (nonatomic) BOOL cancelCalled;
@property (nonatomic) BOOL reportCalled;
@property (nonatomic, copy) NSArray<AMAReportRequestModel *> *reportModels;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
