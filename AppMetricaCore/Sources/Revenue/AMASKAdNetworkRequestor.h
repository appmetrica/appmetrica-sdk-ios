
#import <Foundation/Foundation.h>

@protocol AMADateProviding;

@interface AMASKAdNetworkRequestor : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)sharedInstance;

- (instancetype)initWithDateProvider:(id<AMADateProviding>)dateProvider;
#if !TARGET_OS_TV
- (void)registerForAdNetworkAttribution;
#endif
- (BOOL)updateConversionValue:(NSInteger)value;

@end
