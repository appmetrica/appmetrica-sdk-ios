
#import <Foundation/Foundation.h>

@protocol AMAKeyValueStoring;

NS_ASSUME_NONNULL_BEGIN

@interface AMAAppLovinStartupConfiguration : NSObject

@property (nonatomic, assign) BOOL aramEnabled;
@property (nonatomic, strong, readonly) id<AMAKeyValueStoring> storage;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithStorage:(id<AMAKeyValueStoring>)storage NS_DESIGNATED_INITIALIZER;

+ (NSArray<NSString *> *)allKeys;

@end

NS_ASSUME_NONNULL_END
