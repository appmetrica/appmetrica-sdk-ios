
#import <Foundation/Foundation.h>
#import <AppMetricaCoreExtension.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMAAdProviderProxy : NSObject <AMAAdProviding>

+ (instancetype)sharedInstance;

@property (nonatomic, assign, getter=isEnabled) BOOL enabled;

- (void)setBackingProvider:(nullable id<AMAAdProviding>)backingProvider;

@end

NS_ASSUME_NONNULL_END
