
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AMAKeyValueStorageProviding;
@protocol AMAKeyValueStoring;

@protocol AMAReporterStorageControlling <NSObject>

- (void)setupWithReporter:(id<AMAKeyValueStorageProviding>)stateStorageProvider forAPIKey:(NSString *)apiKey;
- (void)setupWithMainReporter:(id<AMAKeyValueStorageProviding>)stateStorageProvider forAPIKey:(NSString *)apiKey;
- (void)restoreState;

@end

NS_ASSUME_NONNULL_END
