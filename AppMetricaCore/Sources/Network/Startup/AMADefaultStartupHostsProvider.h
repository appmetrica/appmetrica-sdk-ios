
#import <Foundation/Foundation.h>

@interface AMADefaultStartupHostsProvider : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (NSArray *)startupHostsWithAdditionalHosts:(NSArray *)additionalStartupHosts;
+ (NSArray *)resourceStartupHosts;
+ (NSArray *)predefinedStartupHostsWithAdditionalHosts:(NSArray *)additionalStartupHosts;

@end
