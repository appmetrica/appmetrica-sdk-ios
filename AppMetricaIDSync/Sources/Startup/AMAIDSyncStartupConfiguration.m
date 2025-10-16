
#import "AMAIDSyncStartupConfiguration.h"
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMAIDSyncKeys.h"

@implementation AMAIDSyncStartupConfiguration

- (instancetype)initWithStorage:(id<AMAKeyValueStoring>)storage
{
    self = [super init];
    if (self) {
        _storage = storage;
    }
    return self;
}

+ (NSArray<NSString *> *)allKeys
{
    return @[
        AMAIDSyncStorageEnabledKey,
        AMAIDSyncStorageRequestsKey,
        AMAIDSyncStorageLaunchDelaySecondsKey,
    ];
}

- (BOOL)idSyncEnabled
{
    return [self.storage boolNumberForKey:AMAIDSyncStorageEnabledKey error:NULL].boolValue;
}

- (void)setIdSyncEnabled:(BOOL)idSyncEnabled
{
    [self.storage saveBoolNumber:@(idSyncEnabled) forKey:AMAIDSyncStorageEnabledKey error:NULL];
}

- (NSArray<NSDictionary *> *)requests
{
    return [self jsonArrayForKey:AMAIDSyncStorageRequestsKey valueClass:NSDictionary.class];
}

- (void)setRequests:(NSArray<NSDictionary *> *)requests
{
    [self.storage saveJSONArray:requests forKey:AMAIDSyncStorageRequestsKey error:NULL];
}

- (NSNumber *)launchDelaySeconds
{
    return [self.storage longLongNumberForKey:AMAIDSyncStorageLaunchDelaySecondsKey error:NULL];
}

- (void)setLaunchDelaySeconds:(NSNumber *)launchDelaySeconds
{
    [self.storage saveLongLongNumber:launchDelaySeconds forKey:AMAIDSyncStorageLaunchDelaySecondsKey error:NULL];
}

- (NSArray *)jsonArrayForKey:(NSString *)key
                  valueClass:(Class)valueClass
{
    NSArray *array = [self.storage jsonArrayForKey:key error:NULL];
    BOOL isValid = [AMAValidationUtilities validateJSONArray:array
                                                  valueClass:valueClass];
    
    if (isValid == NO) {
        return nil;
    }
    return array;
}

#if AMA_ALLOW_DESCRIPTIONS

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", super.description];
    [description appendFormat:@", self.launchDelaySeconds=%@", self.launchDelaySeconds];
    [description appendFormat:@", self.requests=%@", self.requests];
    [description appendString:@">"];
    return description;
}
#endif

@end
