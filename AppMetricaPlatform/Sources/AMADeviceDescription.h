
#import <Foundation/Foundation.h>

@interface AMADeviceDescription : NSObject

+ (NSString *)appIdentifierPrefix;

+ (BOOL)isDeviceRooted;
+ (NSString *)appPlatform;

+ (BOOL)deviceTypeIsIPad;

+ (NSString *)screenDPI;
+ (NSString *)screenWidth;
+ (NSString *)screenHeight;
+ (NSString *)scalefactor;

+ (NSString *)manufacturer;
+ (NSString *)model;

+ (NSString *)OSVersion;

@end
