#import <Foundation/Foundation.h>

@protocol AMAKeyValueStoring;
@class AMAScreenshotStartupResponse;

NS_ASSUME_NONNULL_BEGIN

@interface AMAScreenshotConfiguration : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype) initWithStorage:(id<AMAKeyValueStoring>)storage;

@property (nonatomic, strong, readonly) id<AMAKeyValueStoring> storage;
+ (NSArray<NSString *> *)allKeys;

@property (nonatomic) BOOL screenshotEnabled;
@property (nonatomic) BOOL captorEnabled;

- (void)updateStartupConfiguration:(AMAScreenshotStartupResponse*)response;

@end

NS_ASSUME_NONNULL_END
