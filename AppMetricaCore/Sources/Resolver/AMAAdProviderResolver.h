#import <Foundation/Foundation.h>
#import "AMAResolver.h"

@class AMAAdProviderProxy;

NS_ASSUME_NONNULL_BEGIN

@interface AMAAdProviderResolver : AMAResolver

@property (nonatomic, strong) AMAAdProviderProxy *adProviderProxy;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithAdProviderProxy:(AMAAdProviderProxy *)adProviderProxy;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
