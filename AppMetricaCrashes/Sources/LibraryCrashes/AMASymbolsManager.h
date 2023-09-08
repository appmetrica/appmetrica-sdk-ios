
#import <Foundation/Foundation.h>

@class AMACrashMatchingRule;
@class AMASymbolsCollection;
@class AMABuildUID;

@interface AMASymbolsManager : NSObject

+ (void)registerSymbolsForApiKey:(NSString *)apiKey rule:(AMACrashMatchingRule *)rule;

+ (AMASymbolsCollection *)symbolsCollectionForApiKey:(NSString *)apiKey buildUID:(AMABuildUID *)buildUID;

+ (void)cleanup;

+ (NSArray *)registeredApiKeys;

@end
