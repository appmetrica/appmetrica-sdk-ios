
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kAMADeviceTypeTV;
extern NSString *const kAMADeviceTypeTablet;
extern NSString *const kAMADeviceTypePhone;
extern NSString *const kAMADeviceTypeWatch;

typedef NS_ENUM(NSUInteger, AMAAppBuildType) {
    AMAAppBuildTypeUnknown,
    AMAAppBuildTypeDebug,
    AMAAppBuildTypeAdHoc,
    AMAAppBuildTypeTestFlight,
    AMAAppBuildTypeAppStore,
};

@interface AMAPlatformDescription : NSObject

// SDK //
+ (NSString *)SDKVersionName;
+ (NSUInteger)SDKBuildNumber;
+ (NSString *)SDKBuildType;
+ (NSString *)SDKBundleName;
+ (NSString *)SDKUserAgent;

// Application //
+ (NSString *)appVersion;
+ (NSString *)appVersionName;
+ (NSString *)appBuildNumber;
+ (NSString *)appID;
+ (NSString *)appIdentifierPrefix;
+ (BOOL)appPlatformIsIPad;
+ (NSString *)appFramework;
+ (BOOL)appDebuggable;
+ (BOOL)isDebuggerAttached;
+ (BOOL)isExtension;
+ (AMAAppBuildType)appBuildType;

// OS //
+ (NSString *)OSName;
+ (NSString *)OSVersion;
+ (NSInteger)OSAPILevel;
+ (BOOL)isDeviceRooted;
+ (NSNumber *)bootTimestamp;

// Device //
+ (NSString *)manufacturer;
+ (NSString *)model;
+ (NSString *)screenDPI;
+ (NSString *)screenWidth;
+ (NSString *)screenHeight;
+ (NSString *)scalefactor;
+ (BOOL)deviceTypeIsIPad;
+ (NSString *)deviceType;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
