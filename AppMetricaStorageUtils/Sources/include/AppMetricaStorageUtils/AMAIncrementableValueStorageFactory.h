
#import <Foundation/Foundation.h>

@class AMAIncrementableValueStorage;

extern NSString *const kAMAAttributionIDStorageKey;
extern NSString *const kAMALastSessionIDStorageKey;
extern NSString *const kAMAGlobalEventNumberStorageKey;
extern NSString *const kAMARequestIdentifierStorageKey;
extern NSString *const kAMAOpenIDStorageKey;

@interface AMAIncrementableValueStorageFactory : NSObject

+ (AMAIncrementableValueStorage *)attributionIDStorage;
+ (AMAIncrementableValueStorage *)lastSessionIDStorage;
+ (AMAIncrementableValueStorage *)globalEventNumberStorage;
+ (AMAIncrementableValueStorage *)eventNumberOfTypeStorageForEventType:(NSUInteger)eventType;
+ (AMAIncrementableValueStorage *)requestIdentifierStorage;
+ (AMAIncrementableValueStorage *)openIDStorage;

@end
