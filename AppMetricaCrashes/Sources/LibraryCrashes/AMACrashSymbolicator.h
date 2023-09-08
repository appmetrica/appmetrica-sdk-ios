
#import <Foundation/Foundation.h>

@class AMADecodedCrash;
@class AMASymbolsCollection;

@interface AMACrashSymbolicator : NSObject

+ (BOOL)symbolicateCrash:(AMADecodedCrash *)crash
       symbolsCollection:(AMASymbolsCollection *)symbolsCollection;

@end
