
#import <Foundation/Foundation.h>

@class AMAInstantFeaturesConfiguration;
@class AMAJSONFileKVSDataProvider;

@interface AMAInstantFeaturesConfiguration : NSObject

@property (nonatomic, copy) NSString *UUID;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)sharedInstance;
- (instancetype)initWithJSONDataProvider:(AMAJSONFileKVSDataProvider *)provider;

@end
