
#import "AMAIDSyncStartupResponseParser.h"
#import "AMAIDSyncStartupResponse.h"
#import "AMAIDSyncStartupController.h"
#import "AMAIDSyncStartupConfiguration.h"
#import "AMAIDSyncRequest.h"
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

@implementation AMAIDSyncStartupResponseParser

- (nullable AMAIDSyncStartupResponse *)parseStartupResponse:(NSDictionary *)startupDictionary
{
    AMAIDSyncStartupResponse *result = nil;
    if (startupDictionary != nil) {
        id<AMAKeyValueStoring> storage = [[AMAIDSyncStartupController sharedInstance] storage];
        if (storage != nil) {
            AMAIDSyncStartupConfiguration *configuration = [[AMAIDSyncStartupConfiguration alloc] initWithStorage:storage];
            result = [[AMAIDSyncStartupResponse alloc] initWithStartupConfiguration:configuration];
            
            NSDictionary *features = startupDictionary[@"features"][@"list"];
            
            configuration.idSyncEnabled =
                [self enabledPropertyValueFromDictionary:features[@"id_sync"]];
            
            NSDictionary *idSync = startupDictionary[@"id_sync"];
            if (idSync != nil) {
                configuration.launchDelaySeconds = idSync[@"launch_delay_seconds"];
                
                NSArray *requestsArray = idSync[@"requests"];
                if (requestsArray != nil) {
                    configuration.requests = [requestsArray copy];
                }
            }
        }
    }
    return result;
}

- (BOOL)enabledPropertyValueFromDictionary:(NSDictionary *)dictionary
{
    return [[self enabledPropertyFromDictionary:dictionary] boolValue];
}

- (NSNumber *)enabledPropertyFromDictionary:(NSDictionary *)dictionary
{
    id value = dictionary[@"enabled"];
    if ([value isKindOfClass:NSNumber.class]) {
        return value;
    }
    else {
        return nil;
    }
}

@end
