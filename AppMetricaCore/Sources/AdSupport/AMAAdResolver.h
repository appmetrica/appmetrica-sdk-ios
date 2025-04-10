#import <Foundation/Foundation.h>

@class AMAAdProvider;
@protocol AMAAdProviding;

NS_ASSUME_NONNULL_BEGIN

@interface AMAAdResolver : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDestination:(AMAAdProvider*)adProvider;

@property (nonatomic, strong, readonly) AMAAdProvider *destination;
@property (nonatomic, strong, nullable) id<AMAAdProviding> adProvider;

- (void)setEnabledAdProvider:(BOOL)enableAdProvider;
- (void)setEnabledForAnonymousActivation:(BOOL)enabledAdProvider;

@end

NS_ASSUME_NONNULL_END
