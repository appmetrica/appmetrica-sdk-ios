
#import <Foundation/Foundation.h>
#import "AMAEventSerializer.h"

@interface AMAEventSerializer (Migration)

- (instancetype)migrationTo500Init;
- (instancetype)migrationTo5100Init;

@end
