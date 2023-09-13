
#import "AMADatabaseObjectProvider.h"
#import "FMDB.h"

@implementation AMADatabaseObjectProvider

+ (AMADatabaseObjectProviderBlock)blockForStrings
{
    return ^(FMResultSet *rs, NSUInteger columnIdx) {
        return [rs stringForColumnIndex:(int)columnIdx];
    };
}

+ (AMADatabaseObjectProviderBlock)blockForDataBlobs
{
    return ^(FMResultSet *rs, NSUInteger columnIdx) {
        return [rs dataForColumnIndex:(int)columnIdx];
    };
}

@end
