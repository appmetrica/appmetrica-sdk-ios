
#import <Foundation/Foundation.h>
#import "AMACore.h"
#import "AMAStartupCompletionObserving.h"

@class AMAInstantFeaturesConfiguration;
@class AMAJSONFileKVSDataProvider;

@protocol AMAInstantFeaturesObserver <NSObject>

- (void)instantFeaturesConfigurationDidUpdate:(AMAInstantFeaturesConfiguration *)configuration;

@end

@interface AMAInstantFeaturesConfiguration : NSObject <AMAStartupCompletionObserving, AMABroadcasting>

@property (nonatomic, assign) BOOL dynamicLibraryCrashHookEnabled;
@property (nonatomic, copy) NSString *UUID;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)sharedInstance;
- (instancetype)initWithJSONDataProvider:(AMAJSONFileKVSDataProvider *)provider;

@end
