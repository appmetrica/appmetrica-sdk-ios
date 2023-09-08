
#import <Foundation/Foundation.h>

@class FMResultSet;

typedef id(^AMADatabaseObjectProviderBlock)(FMResultSet *rs, NSUInteger columdIdx);
