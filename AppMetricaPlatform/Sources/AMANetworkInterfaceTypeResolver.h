
#import <Foundation/Foundation.h>

@interface AMANetworkInterfaceTypeResolver : NSObject

+ (void)isCellularConnection:(void (^)(BOOL isCellular))completion;

@end
