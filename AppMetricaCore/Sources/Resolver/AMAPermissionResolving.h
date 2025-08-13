
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AMAPermissionResolvingInput<NSObject>

@property (nonatomic, copy, nullable) NSNumber *anonymousValue;
@property (nonatomic, copy, nullable) NSNumber *userValue;

@property (nonatomic, assign, setter=setAnonymousConfigurationActivated:) BOOL isAnonymousConfigurationActivated;

- (void)updateBoolValue:(NSNumber *)value isAnonymous:(BOOL)isAnonymous;

@end

@protocol AMAPermissionResolvingOutput<NSObject>

@property (nonatomic, readonly) BOOL resultValue;

@end


NS_ASSUME_NONNULL_END
