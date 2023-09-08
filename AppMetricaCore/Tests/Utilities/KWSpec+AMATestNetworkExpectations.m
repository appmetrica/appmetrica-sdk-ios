
#import "KWSpec+AMATestNetworkExpectations.h"
#import "AMATestNetwork.h"
#import <Kiwi/Kiwi.h>

@implementation KWSpec (AMATestNetworkExpectations)

+ (void)amatest_shouldExpectNetworkConnection:(BOOL)shouldExpect withBlock:(dispatch_block_t)block
{
    BOOL __block triggered = NO;
    [AMATestNetwork stubNetworkRequestWithBlock:^id(NSArray *params) {
        triggered = YES;
        return nil;
    }];
    block();
    [[theValue(triggered) should] equal:theValue(shouldExpect)];
}

+ (void)amatest_shouldExpectNetworkConnectionsCount:(NSUInteger)expectedCount withBlock:(dispatch_block_t)block
{
    NSUInteger __block count = 0;
    [AMATestNetwork stubNetworkRequestWithStatusCode:200 block:^{
        ++count;
    }];
    block();
    [[theValue(count) should] equal:theValue(expectedCount)];
}

+ (void)amatest_shouldExpectNetworkConnectionsCount:(NSUInteger)expectedCount
                                        statusCodes:(NSArray *)statusCodes
                                          withBlock:(dispatch_block_t)block
{
    NSUInteger __block count = 0;
    [AMATestNetwork clearNetworkRequestIndex];
    [AMATestNetwork stubNetworkRequestWithStatusCodes:statusCodes block:^{
        ++count;
    }];
    block();
    [[theValue(count) should] equal:theValue(expectedCount)];
}

@end
