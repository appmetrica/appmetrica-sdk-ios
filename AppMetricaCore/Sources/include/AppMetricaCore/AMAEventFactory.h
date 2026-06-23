
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Factory for creating AppMetrica events.
 * Modules extend this class with category methods to add event types.
 */
NS_SWIFT_NAME(EventFactory)
@interface AMAEventFactory : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
