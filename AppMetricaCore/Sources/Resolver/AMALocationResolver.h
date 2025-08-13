#import <Foundation/Foundation.h>
#import "AMAResolver.h"

@class AMALocationManager;

NS_ASSUME_NONNULL_BEGIN

@interface AMALocationResolver : AMAResolver

@property (nonatomic, strong) AMALocationManager *locationManager;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithLocationManager:(AMALocationManager *)locationManager;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
