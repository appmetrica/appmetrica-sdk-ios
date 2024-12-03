#import <Foundation/Foundation.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMAAppGroupIdentifierProvider.h"


NS_ASSUME_NONNULL_BEGIN

@interface AMABundleInfoMock : NSBundle

@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *mockedInfo;

@end

NS_ASSUME_NONNULL_END
