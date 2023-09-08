
#import "AMAStartupItemsChangedNotifier.h"

@interface AMAStartupItemsChangedNotifier ()

- (void)dispatchBlock:(AMAIdentifiersCompletionBlock)block
  withAvailableFields:(NSDictionary *)availableFields
              toQueue:(dispatch_queue_t)queue
                error:(NSError *)error;

@end
