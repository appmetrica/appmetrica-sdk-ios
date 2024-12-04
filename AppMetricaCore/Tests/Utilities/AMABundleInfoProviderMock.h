
#import <Foundation/Foundation.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMABundleInfoProviderMock : NSObject<AMABundleInfoProvider>

@property (nonatomic) NSString *appID;
@property (nonatomic) NSString *appBuildNumber;
@property (nonatomic) NSString *appVersion;
@property (nonatomic) NSString *appVersionName;

- (instancetype)initWithAppID:(NSString*)appID
               appBuildNumber:(NSString*)appBuildNumber
                   appVersion:(NSString*)appVersion
               appVersionName:(NSString*)appVersionName;

- (instancetype)initWithAppID:(NSString*)appID
      copyOtherPropertiesFrom:(id<AMABundleInfoProvider>)otherProp;

@end

NS_ASSUME_NONNULL_END
