
#import <Foundation/Foundation.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

@interface AMAIncrementableValueStorageMock : AMAIncrementableValueStorage

@property (nonatomic, strong) NSNumber *currentMockValue;

- (instancetype)init;

@end
