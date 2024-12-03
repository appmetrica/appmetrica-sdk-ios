
#import <Foundation/Foundation.h>
@import AppMetricaIdentifiers;

NS_ASSUME_NONNULL_BEGIN

@interface AMAIdentifierProviderMock : NSObject<AMAIdentifierProviding>

@property (nonatomic, copy, nullable) NSString *mockDeviceID;
@property (nonatomic, copy, nullable) NSString *mockDeviceHashID;
@property (nonatomic, copy, nullable) NSString *mockMetricaUUID;

+ (instancetype)randomInstance;

- (void)fillRandom;

@end

NS_ASSUME_NONNULL_END
