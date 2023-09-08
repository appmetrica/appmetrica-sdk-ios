
#import "AMASessionStorage.h"

@interface AMASessionStorage (AMATestUtilities)

- (AMASession *)amatest_existingOrNewBackgroundSessionCreatedAt:(NSDate *)date;
- (AMASession *)amatest_backgroundSession;
- (AMASession *)amatest_lastSessionWithType:(AMASessionType)type;
- (AMASession *)amatest_sessionWithOid:(NSNumber *)sessionOid;
- (NSArray *)amatest_allSessionsWithType:(AMASessionType)type;

@end
