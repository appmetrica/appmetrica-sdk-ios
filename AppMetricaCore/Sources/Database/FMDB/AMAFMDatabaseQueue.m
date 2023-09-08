
#import "AMACore.h"
#import "AMAFMDatabaseQueue.h"
#import "AMAFMDatabase.h"

@implementation AMAFMDatabaseQueue

+ (Class)databaseClass
{
    return [AMAFMDatabase class];
}

@end
