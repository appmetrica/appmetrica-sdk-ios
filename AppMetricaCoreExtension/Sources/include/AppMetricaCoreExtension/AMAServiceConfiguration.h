
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AMAStartupProviding;
@protocol AMAReporterStorageControlling;

@interface AMAServiceConfiguration : NSObject

@property (nonatomic, nullable, strong, readonly) id<AMAStartupProviding> startupProvider;
@property (nonatomic, nullable, strong, readonly) id<AMAReporterStorageControlling> reporterStorageController;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initStartupProvider:(nullable id<AMAStartupProviding>)startupProvider
          reporterStorageController:(nullable id<AMAReporterStorageControlling>)reporterStorageController;

@end

NS_ASSUME_NONNULL_END
