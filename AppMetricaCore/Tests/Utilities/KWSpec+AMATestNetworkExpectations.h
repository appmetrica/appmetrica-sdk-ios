
#import <Kiwi/KWSpec.h>

@interface KWSpec (AMATestNetworkExpectations)

+ (void)amatest_shouldExpectNetworkConnection:(BOOL)shouldExpect withBlock:(dispatch_block_t)block;
+ (void)amatest_shouldExpectNetworkConnectionsCount:(NSUInteger)expectedCount withBlock:(dispatch_block_t)block;
+ (void)amatest_shouldExpectNetworkConnectionsCount:(NSUInteger)expectedCount
                                        statusCodes:(NSArray *)statusCodes
                                          withBlock:(dispatch_block_t)block;

@end
