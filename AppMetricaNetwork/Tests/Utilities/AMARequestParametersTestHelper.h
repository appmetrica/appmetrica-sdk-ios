
#import <Foundation/Foundation.h>

@protocol AMABundleInfoProvider;

@interface AMARequestParametersTestHelper : NSObject

@property (nonatomic, copy) NSString *deviceType;
@property (nonatomic, copy) NSString *appPlatform;
@property (nonatomic, copy) NSString *manufacturer;
@property (nonatomic, copy) NSString *model;
@property (nonatomic, copy) NSString *screenWidth;
@property (nonatomic, copy) NSString *screenHeight;
@property (nonatomic, copy) NSString *scalefactor;
@property (nonatomic, copy) NSString *screenDPI;
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *mainAppID;
@property (nonatomic, copy) NSString *extensionAppID;
@property (nonatomic, copy) NSString *APIKey;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *appFramework;

@property (nonatomic) id<AMABundleInfoProvider> appInfoProvider;
@property (nonatomic) id<AMABundleInfoProvider> mainAppInfoProvider;
@property (nonatomic) id<AMABundleInfoProvider> extensionAppInfoProvider;

- (void)configureStubs;

@end
