
#import <Foundation/Foundation.h>

@class AMARSAKey;

@interface AMACryptingHelper : NSObject

+ (AMARSAKey *)publicKey;
+ (AMARSAKey *)privateKey;

@end
