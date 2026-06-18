
#import <Foundation/Foundation.h>

@class AMAModulesController;

NS_ASSUME_NONNULL_BEGIN

@interface AMACoreModuleComponentsInitializer : NSObject

+ (void)discoverAndRegisterInController:(AMAModulesController *)controller
                            classLookup:(nullable Class (^)(NSString *className))classLookup;

@end

NS_ASSUME_NONNULL_END
