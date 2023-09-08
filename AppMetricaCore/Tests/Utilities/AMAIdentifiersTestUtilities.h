
#import <Foundation/Foundation.h>

@interface AMAIdentifiersTestUtilities : NSObject

+ (void)stubIdfaWithEnabled:(BOOL)isEnabled value:(NSString *)UUID;
+ (void)stubUUID:(NSString *)UUID;
+ (void)stubIFV:(NSString *)UUID;
+ (void)stubDeviceIDHash:(NSString *)deviceIDHash;
+ (void)stubClientIdentifiersProvider:(NSString *)UUID
                             deviceID:(NSString *)deviceID
                                  ifv:(NSString *)ifv
                         deviceIDHash:(NSString *)deviceIDHash;

@end
