#import <Foundation/Foundation.h>
#import "AMAEventPollingDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAEventPollingDelegateMock : NSObject <AMAEventPollingDelegate>

@property (class, nonatomic, strong) NSArray<AMACustomEventParameters *> *mockedEvents;

@end

NS_ASSUME_NONNULL_END
