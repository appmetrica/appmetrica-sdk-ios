
#import <Foundation/Foundation.h>

@protocol AMAAdRevenueSourceStorable <NSObject>

@property (readonly, copy, atomic) NSArray<NSString *> *nativeSupportedSources;
@property (readonly, copy, atomic) NSArray<NSString *> *pluginSupportedSources;

- (void)addNativeSupportedSource:(NSString*)source;

@end
