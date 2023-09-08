
#import <Foundation/Foundation.h>

@interface AMADeviceDescription : NSObject

+ (NSString *)appIdentifierPrefix;

+ (BOOL)isDeviceRooted;
+ (BOOL)appPlatformIsIPad;

+ (BOOL)deviceTypeIsIPad;
//TODO: Are `appPlatformIsIPad` and `deviceTypeIsIPad` the same?

+ (NSString *)screenDPI;
+ (NSString *)screenWidth;
+ (NSString *)screenHeight;
+ (NSString *)scalefactor;

+ (NSString *)manufacturer;
+ (NSString *)model;

+ (NSString *)OSVersion;

@end
