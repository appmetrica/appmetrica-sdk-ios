
#import "AMAEventStorage.h"

@interface AMAEventStorage (Migration)

- (BOOL)addMigratedEvent:(AMAEvent *)event error:(NSError **)error;

@end
