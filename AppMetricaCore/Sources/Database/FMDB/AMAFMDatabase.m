
#import "AMAFMDatabase.h"

@interface FMDatabase ()

- (void)setCachedStatement:(FMStatement *)statement forQuery:(NSString *)query;

@end

@implementation AMAFMDatabase

- (void)setCachedStatement:(FMStatement *)statement forQuery:(NSString *)query
{
    if (query != nil) {
        [super setCachedStatement:statement forQuery:query];    
    }
}

@end
