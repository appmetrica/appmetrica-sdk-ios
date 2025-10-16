
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMAIDSyncPreconditionHandler : NSObject

- (void)canExecuteRequestWithPreconditions:(NSDictionary *)preconditions
                                completion:(void (^)(BOOL))completion;

@end

NS_ASSUME_NONNULL_END
