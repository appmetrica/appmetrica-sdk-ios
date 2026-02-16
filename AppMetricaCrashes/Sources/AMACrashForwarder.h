
#import <Foundation/Foundation.h>

@class AMADecodedCrash;
@class AMADecodedCrashSerializer;
@protocol AMACrashFilteringProxy;

NS_ASSUME_NONNULL_BEGIN

@interface AMACrashForwarder : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSerializer:(AMADecodedCrashSerializer *)serializer NS_DESIGNATED_INITIALIZER;

- (void)registerHandler:(nullable id<AMACrashFilteringProxy>)handler;

- (void)processCrash:(AMADecodedCrash *)decodedCrash;
- (void)processANR:(AMADecodedCrash *)decodedCrash;

@end

NS_ASSUME_NONNULL_END
