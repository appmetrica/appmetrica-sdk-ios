#import "AMAStartupStorageMockProvider.h"
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

@interface AMAStartupStorageMockProvider ()
@property (nonatomic, copy, readwrite, nullable) NSArray<NSString *> *startupStorageKeys;
@end

@implementation AMAStartupStorageMockProvider

- (void)saveStorage:(nonnull id<AMAKeyValueStoring>)storage
{
    [self.saveStorageExpectation fulfill];
}

- (nonnull id<AMAKeyValueStoring>)startupStorageForKeys:(nonnull NSArray<NSString *> *)keys
{
    self.startupStorageKeys = keys;
    [self.startupStorageExpectation fulfill];
    return self.mockedStartupStorage;
}

@end
