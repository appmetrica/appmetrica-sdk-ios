
#import <Foundation/Foundation.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

@interface AMAHostProviderMock : NSObject <AMAResettableIterable>

@property (nonatomic, assign, readonly) NSUInteger numberOfTimesHitNext;
@property (nonatomic, assign, readonly) NSUInteger numberOfTimesHitReset;

- (instancetype)initWithItems:(NSArray *)items;

@end
