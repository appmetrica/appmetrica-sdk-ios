#import <Foundation/Foundation.h>
#import "AMAEventPollingDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAEventPollingDelegateMock : NSObject <AMAEventPollingDelegate>

@property (class, nonatomic, strong) NSArray<AMAEventPollingParameters *> *mockedEvents;

@end

NS_ASSUME_NONNULL_END
