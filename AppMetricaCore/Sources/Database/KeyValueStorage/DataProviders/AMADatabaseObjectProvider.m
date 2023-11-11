
#import "AMADatabaseObjectProvider.h"
#import <AppMetrica_FMDB/AppMetrica_FMDB.h>

@implementation AMADatabaseObjectProvider

+ (AMADatabaseObjectProviderBlock)blockForStrings
{
    return ^(AMAFMResultSet *rs, NSUInteger columnIdx) {
        return [rs stringForColumnIndex:(int)columnIdx];
    };
}

+ (AMADatabaseObjectProviderBlock)blockForDataBlobs
{
    return ^(AMAFMResultSet *rs, NSUInteger columnIdx) {
        return [rs dataForColumnIndex:(int)columnIdx];
    };
}

@end
