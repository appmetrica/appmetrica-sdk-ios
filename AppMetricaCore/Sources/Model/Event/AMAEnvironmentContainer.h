
#import <Foundation/Foundation.h>

@class AMAEnvironmentLimiter;
@class AMAEnvironmentContainer;

NS_ASSUME_NONNULL_BEGIN

typedef void (^AMAEnvironmentContainerDidChangeBlock)(id observer, AMAEnvironmentContainer *environment);
typedef void (^AMAEnvironmentContainerUpdatesBlock)(void);


@interface AMAEnvironmentContainer : NSObject

- (instancetype)initWithDictionaryEnvironment:(nullable NSDictionary *)dictionaryEnvironment;

- (instancetype)initWithDictionaryEnvironment:(nullable NSDictionary *)dictionaryEnvironment
                                      limiter:(AMAEnvironmentLimiter *)limiter NS_DESIGNATED_INITIALIZER;

- (void)addValue:(nullable NSString *)value forKey:(NSString *)key;
- (void)clearEnvironment;

- (void)performBatchUpdates:(AMAEnvironmentContainerUpdatesBlock)updatesBlock;

- (NSDictionary *)dictionaryEnvironment;

- (void)addObserver:(id)observer withBlock:(AMAEnvironmentContainerDidChangeBlock)block;
- (void)removeObserver:(id)observer;

@end

NS_ASSUME_NONNULL_END
