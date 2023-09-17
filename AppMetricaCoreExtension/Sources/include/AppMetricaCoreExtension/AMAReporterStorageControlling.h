
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AMAKeyValueStorageProviding;
@protocol AMAKeyValueStoring;

@protocol AMAReporterStorageControlling <NSObject>

- (void)setupWithReporter:(id<AMAKeyValueStorageProviding>)stateStorageProvider main:(BOOL)main forAPIKey:(NSString *)apiKey;

@end

NS_ASSUME_NONNULL_END
