
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kAMADeepLinkTypeOpen;

@interface AMADeepLinkProcessor : NSObject

// Call on the owning reporter's executor. Returns nil for invalid or already consumed URLs.
- (nullable NSDictionary *)consumeURL:(nullable NSURL *)url
                               ofType:(NSString *)type
                               isAuto:(BOOL)isAuto
                        reattribution:(BOOL * _Nullable)reattribution;

@end

NS_ASSUME_NONNULL_END
