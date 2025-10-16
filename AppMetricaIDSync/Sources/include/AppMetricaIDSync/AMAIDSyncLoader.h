
#import <Foundation/Foundation.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMAIDSyncLoader : NSObject

+ (instancetype)sharedInstance;
- (void)start;

@end

NS_ASSUME_NONNULL_END
