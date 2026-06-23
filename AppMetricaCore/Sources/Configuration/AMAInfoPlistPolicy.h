
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Generic policy that reads a single BOOL flag from Info.plist.
/// Lazily evaluated; result is cached after the first read.
@interface AMAInfoPlistPolicy : NSObject

- (instancetype)initWithBundle:(NSBundle *)bundle
                           key:(NSString *)key
                  defaultValue:(BOOL)defaultValue NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, readonly) BOOL isEnabled;

@end

NS_ASSUME_NONNULL_END
