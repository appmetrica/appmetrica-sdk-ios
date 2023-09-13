
#import <Foundation/Foundation.h>
#import "AMAReportHostProvider.h"

@interface AMAReportHostProviderMock : AMAReportHostProvider

@property (nonatomic, assign, readonly) NSUInteger numberOfTimesHitNext;
@property (nonatomic, assign, readonly) NSUInteger numberOfTimesHitReset;

- (instancetype)initWithItems:(NSArray *)items;

@end
