
#import <Foundation/Foundation.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(KeyValueStorageMock)
@interface AMAKeyValueStorageMock : NSObject<AMAKeyValueStoring>

@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *storage;
@property (nonatomic, strong, nullable) NSError *error;

@end

NS_ASSUME_NONNULL_END
