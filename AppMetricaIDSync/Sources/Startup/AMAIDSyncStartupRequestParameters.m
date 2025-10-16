
#import "AMAIDSyncStartupRequestParameters.h"

@implementation AMAIDSyncStartupRequestParameters

+ (NSDictionary *)parameters
{
    NSString *features = [[[self class] featureParameters] componentsJoinedByString:@","];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{ @"features" : features}];
    [dict addEntriesFromDictionary:[[self class] blockParameters]];
    return dict;
}

+ (NSArray *)featureParameters
{
    return @[@"is"]; // id sync
}

+ (NSDictionary *)blockParameters
{
    return @{@"is" : @"1"};
}

@end
