
#import <Foundation/Foundation.h>
#import "AMAEventTypes.h"

@interface AMAEventCountByKeyHelper : NSObject

- (NSUInteger)getCountForKey:(NSString *)key;
- (void)setCount:(NSUInteger)count forKey:(NSString *)key;

@end
