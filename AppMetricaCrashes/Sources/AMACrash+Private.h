
#import "AMACrash+Extended.h"

NS_ASSUME_NONNULL_BEGIN

@class AMAApplicationState;

@interface AMACrash ()

@property (nonatomic, copy, nullable, readonly) AMAApplicationState *appState;

- (instancetype)initWithRawData:(nullable NSData *)rawData
                           date:(nullable NSDate *)date
                       appState:(nullable AMAApplicationState *)appState
               errorEnvironment:(nullable NSDictionary *)errorEnvironment
                 appEnvironment:(nullable NSDictionary *)appEnvironment;

+ (instancetype)crashWithRawData:(nullable NSData *)rawData
                            date:(nullable NSDate *)date
                        appState:(nullable AMAApplicationState *)appState
                errorEnvironment:(nullable NSDictionary *)errorEnvironment
                  appEnvironment:(nullable NSDictionary *)appEnvironment;

@end

NS_ASSUME_NONNULL_END
