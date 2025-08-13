#import <Foundation/Foundation.h>
#import "AMAResolver.h"

@class AMAAdProvider;

NS_ASSUME_NONNULL_BEGIN

@interface AMAAdProviderResolver : AMAResolver

@property (nonatomic, strong) AMAAdProvider *adProvider;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithAdProvider:(AMAAdProvider *)adProvider;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
