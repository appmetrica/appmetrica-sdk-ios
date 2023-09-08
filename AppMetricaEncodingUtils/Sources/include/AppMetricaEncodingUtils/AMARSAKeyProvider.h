
#import <Foundation/Foundation.h>

@class AMARSAKey;

NS_ASSUME_NONNULL_BEGIN

@interface AMARSAKeyProvider : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (SecKeyRef)keyWithStatus:(OSStatus *)status;

+ (instancetype)sharedInstanceForKey:(AMARSAKey *)key;

@end

NS_ASSUME_NONNULL_END
