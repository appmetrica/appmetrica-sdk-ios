
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(UserDefaultsMock)
@interface AMAUserDefaultsMock : NSObject

@property (nonatomic, assign, readonly) BOOL synchronized;
@property (nonatomic, strong, readonly) NSMutableDictionary *store;
@property (nonatomic, nullable, strong, readonly) NSString *suitename;

- (instancetype)initWithSuiteName:(nullable NSString *)suitename;

- (id)objectForKey:(NSString *)defaultName;
- (void)setObject:(nullable id)value forKey:(NSString *)defaultName;
- (NSDictionary<NSString *, id> *)dictionaryForKey:(NSString *)defaultName;
- (void)synchronize;

@end

NS_ASSUME_NONNULL_END
