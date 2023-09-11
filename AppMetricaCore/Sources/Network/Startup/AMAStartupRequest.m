
#import "AMACore.h"
#import "AMAStartupRequest.h"
#import "AMAStartupParameters.h"

@interface AMAStartupRequest ()

@property (nonatomic, copy) NSMutableDictionary *additionalParameters;

@end

@implementation AMAStartupRequest

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _additionalParameters = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addAdditionalStartupParameters:(NSDictionary *)parameters
{
    @synchronized (self) {
        for (NSString *key in parameters) {
            id value = parameters[key];
            if ([key isEqual:@"features"] && [value isKindOfClass:[NSString class]]) {
                NSString *currentFeatures = self.additionalParameters[key];
                if (currentFeatures != nil) {
                    self.additionalParameters[key] = [NSString stringWithFormat:@"%@,%@", currentFeatures, value];
                }
                else {
                    self.additionalParameters[key] = value;
                }
            }
            else {
                if ([key isKindOfClass:[NSString class]] && [value isKindOfClass:[NSString class]]) {
                    self.additionalParameters[key] = value;
                }
            }
        }
    }
}

- (NSDictionary *)headerComponents
{
    NSMutableDictionary *startupHeaders = [super headerComponents].mutableCopy;
    [AMANetworkingUtilities addUserAgentHeadersToDictionary:startupHeaders];
    [startupHeaders addEntriesFromDictionary:@{
        @"Accept": @"application/json",
        @"Accept-Encoding": @"encrypted",
    }];
    return startupHeaders.copy;
}

- (NSMutableArray *)pathComponents
{
    NSMutableArray *pathComponents = [super pathComponents].mutableCopy;
    [pathComponents addObjectsFromArray:@[ @"analytics", @"startup" ]];
    return pathComponents;
}

- (NSDictionary *)GETParameters
{
    NSMutableDictionary *parameters = [[super GETParameters] mutableCopy];
    [parameters addEntriesFromDictionary:[AMAStartupParameters parameters]];
    [self appendAdditionalParameters:parameters];
    return parameters;
}

#pragma mark - Private

- (void)appendAdditionalParameters:(NSMutableDictionary *)parameters
{
    for (NSString *key in self.additionalParameters) {
        if ([key isEqual:@"features"]) {
            NSString *features = parameters[key];
            NSArray *additionalFeatures = [self.additionalParameters[key] componentsSeparatedByString:@","];
            NSArray *allFeatures = [[features componentsSeparatedByString:@","] arrayByAddingObjectsFromArray:additionalFeatures];
            NSArray *uniqueFeatures = [[NSSet setWithArray:allFeatures] allObjects];
            parameters[key] = [NSString stringWithFormat:@"%@", [uniqueFeatures componentsJoinedByString:@","]];
        }
        else {
            parameters[key] = self.additionalParameters[key];
        }
    }
}


@end
