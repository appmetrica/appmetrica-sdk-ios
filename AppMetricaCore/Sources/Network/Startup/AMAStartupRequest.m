
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

- (void)setAdditionalStartupParameters:(NSDictionary *)parameters
{
    @synchronized (self) {
        self.additionalParameters = [parameters copy];
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
            parameters[key] = [NSString stringWithFormat:@"%@,%@", features, self.additionalParameters[key]];
        }
        else {
            parameters[key] = self.additionalParameters[key];
        }
    }
}


@end
