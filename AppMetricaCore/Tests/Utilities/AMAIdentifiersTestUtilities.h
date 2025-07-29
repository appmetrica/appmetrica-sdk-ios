
#import <Foundation/Foundation.h>

@class AMAIdentifierProviderMock;

@interface AMAIdentifiersTestUtilities : NSObject

+ (AMAIdentifierProviderMock *)stubIdentifierProviderIfNeeded;
+ (void)stubIdfaWithEnabled:(BOOL)isEnabled value:(NSString *)UUID;
+ (void)stubUUID:(NSString *)UUID;
+ (void)stubIFV:(NSString *)UUID;
+ (void)stubDeviceIDHash:(NSString *)deviceIDHash;
+ (void)stubClientIdentifiersProvider:(NSString *)UUID
                             deviceID:(NSString *)deviceID
                                  ifv:(NSString *)ifv
                         deviceIDHash:(NSString *)deviceIDHash;
+ (void)destubIFV;
+ (void)destubIDFA;
+ (void)destubUUID;
+ (void)destubIdentifierProvider;
+ (void)destubAll;

@end
