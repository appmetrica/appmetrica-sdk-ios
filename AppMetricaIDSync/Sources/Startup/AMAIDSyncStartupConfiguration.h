
#import <Foundation/Foundation.h>

@protocol AMAKeyValueStoring;
@class AMAIDSyncStartupResponse;

NS_ASSUME_NONNULL_BEGIN

@interface AMAIDSyncStartupConfiguration : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, strong, readonly) id<AMAKeyValueStoring> storage;

@property (nonatomic, assign) BOOL idSyncEnabled;
@property (nonatomic, strong) NSNumber *launchDelaySeconds;
@property (nonatomic, copy) NSArray<NSDictionary *> *requests;

+ (NSArray<NSString *> *)allKeys;
- (instancetype)initWithStorage:(id<AMAKeyValueStoring>)storage;

@end

NS_ASSUME_NONNULL_END
