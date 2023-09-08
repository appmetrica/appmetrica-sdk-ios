
#import "AMAEvent.h"

@interface AMAEvent ()

+ (NSString *)eventsCountQueryWithLimit:(NSInteger)limit eventTypes:(NSArray *)types;
+ (NSString *)typesSQLQuery:(NSArray *)types;

@end
