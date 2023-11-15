
#import <Foundation/Foundation.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

NS_SWIFT_NAME(IncrementableValueStorageMock)
@interface AMAIncrementableValueStorageMock : AMAIncrementableValueStorage

@property (nonatomic, strong) NSNumber *currentMockValue;

- (instancetype)init;

@end
