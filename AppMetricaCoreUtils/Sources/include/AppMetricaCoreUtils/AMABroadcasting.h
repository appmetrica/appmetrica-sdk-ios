
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AMABroadcasting <NSObject>

@property (nonatomic, copy, readonly) NSArray *observers;

- (void)addAMAObserver:(id)observer;
- (void)removeAMAObserver:(id)observer;

@end

NS_ASSUME_NONNULL_END
