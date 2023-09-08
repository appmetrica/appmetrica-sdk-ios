
#import <Foundation/Foundation.h>
#import "AMACore.h"

@interface AMAHostProviderMock : NSObject <AMAResettableIterable>

@property (nonatomic, assign, readonly) NSUInteger numberOfTimesHitNext;
@property (nonatomic, assign, readonly) NSUInteger numberOfTimesHitReset;

- (instancetype)initWithItems:(NSArray *)items;

@end
