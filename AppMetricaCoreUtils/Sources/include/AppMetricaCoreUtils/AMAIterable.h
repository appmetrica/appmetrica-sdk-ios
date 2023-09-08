
#import <Foundation/Foundation.h>

@protocol AMAIterable <NSObject>

- (id)current;
- (id)next;

@end

@protocol AMAResettableIterable <AMAIterable>

- (void)reset;

@end
