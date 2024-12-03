
#import <Foundation/Foundation.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(KeyValueStorageDataProvidingMock)
@interface AMAKeyValueStorageDataProvidingMock : NSObject<AMAKeyValueStorageDataProviding>

@property (nonatomic, strong) NSError *error;
@property (nonatomic, copy) NSDictionary<NSString *, id> *storage;

@end

NS_ASSUME_NONNULL_END
