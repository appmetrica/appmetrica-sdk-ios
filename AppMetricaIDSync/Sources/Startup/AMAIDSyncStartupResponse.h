
#import <Foundation/Foundation.h>

@class AMAIDSyncStartupConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface AMAIDSyncStartupResponse : NSObject

@property (nonatomic, strong, readonly) AMAIDSyncStartupConfiguration *configuration;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithStartupConfiguration:(AMAIDSyncStartupConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END
