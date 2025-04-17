
#import <Foundation/Foundation.h>
#import "AMASessionSerializer.h"

@interface AMASessionSerializer (Migration)

- (instancetype)migrationTo500Init;
- (instancetype)migrationTo5100Init;

@end
