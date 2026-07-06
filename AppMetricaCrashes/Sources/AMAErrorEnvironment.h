#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMAErrorEnvironment : NSObject

- (void)addValue:(nullable NSString *)value forKey:(NSString *)key;
- (void)addValue:(nullable NSString *)value forKey:(NSString *)key replaceExisting:(BOOL)replaceExisting;
- (void)clearEnvironment;
- (NSDictionary *)currentEnvironment;

@end

NS_ASSUME_NONNULL_END
