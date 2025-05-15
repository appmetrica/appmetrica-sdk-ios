#import <Foundation/Foundation.h>
#import "AMAAdRevenueSourceContainer.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAAdRevenueSourceContainerMock : NSObject<AMAAdRevenueSourceStorable>

@property (readwrite, copy, atomic) NSArray<NSString *> *nativeSupportedSources;
@property (readwrite, copy, atomic) NSArray<NSString *> *pluginSupportedSources;

- (void)addNativeSupportedSource:(NSString*)source;

@end

NS_ASSUME_NONNULL_END
