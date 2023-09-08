
#import <Foundation/Foundation.h>

typedef void (^AMANotificationsListenerCallback)(NSNotification *);
@protocol AMAExecuting;

@interface AMANotificationsListener : NSObject

- (instancetype)initWithExecutor:(id<AMAExecuting>)executor;

- (void)subscribeObject:(id)object toNotification:(NSString *)notification withCallback:(AMANotificationsListenerCallback)callback;
- (void)unsubscribeObject:(id)object fromNotification:(NSString *)notification;
- (void)unsubscribeObject:(id)object;

@end
