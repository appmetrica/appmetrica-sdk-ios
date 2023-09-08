
#import "AMACrash+Private.h"
#import "AMACrashLogging.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>

@implementation AMACrash

#pragma mark - Initializing

- (instancetype)initWithRawData:(nullable NSData *)rawData
                           date:(nullable NSDate *)date
                       appState:(nullable AMAApplicationState *)appState
               errorEnvironment:(nullable NSDictionary *)errorEnvironment
                 appEnvironment:(nullable NSDictionary *)appEnvironment
{
    self = [super init];
    if (self != nil) {
        _rawData = [rawData copy];
        _date = date;
        _appState = [appState copy];
        _errorEnvironment = [errorEnvironment copy];
        _appEnvironment = [appEnvironment copy];
    }
    return self;
}

- (instancetype)initWithRawData:(nullable NSData *)rawData
                           date:(nullable NSDate *)date
               errorEnvironment:(nullable NSDictionary *)errorEnvironment
                 appEnvironment:(nullable NSDictionary *)appEnvironment
{
    return [self initWithRawData:rawData
                            date:date
                        appState:nil
                errorEnvironment:errorEnvironment
                  appEnvironment:appEnvironment];
}

- (instancetype)initWithRawData:(nullable NSData *)rawData
                           date:(nullable NSDate *)date
               errorEnvironment:(nullable NSDictionary *)errorEnvironment
{
    return [self initWithRawData:rawData
                            date:date
                errorEnvironment:errorEnvironment
                  appEnvironment:nil];
}

+ (instancetype)crashWithRawData:(nullable NSData *)rawData
                            date:(nullable NSDate *)date
                        appState:(nullable AMAApplicationState *)appState
                errorEnvironment:(nullable NSDictionary *)errorEnvironment
                  appEnvironment:(nullable NSDictionary *)appEnvironment
{
    return [[self alloc] initWithRawData:rawData
                                    date:date
                                appState:appState
                        errorEnvironment:errorEnvironment
                          appEnvironment:appEnvironment];
}

+ (instancetype)crashWithRawData:(nullable NSData *)rawData
                            date:(nullable NSDate *)date
                errorEnvironment:(nullable NSDictionary *)errorEnvironment
                  appEnvironment:(nullable NSDictionary *)appEnvironment
{
    return [[self alloc] initWithRawData:rawData
                                    date:date
                        errorEnvironment:errorEnvironment
                          appEnvironment:appEnvironment];
}

+ (instancetype)crashWithRawData:(nullable NSData *)rawData
                            date:(nullable NSDate *)date
                errorEnvironment:(nullable NSDictionary *)errorEnvironment
{
    return [[self alloc] initWithRawData:rawData
                                    date:date
                        errorEnvironment:errorEnvironment];
}

#pragma mark Deprecated

- (instancetype)initWithRawContent:(NSString *)rawContent
                              date:(NSDate *)date
                  errorEnvironment:(NSDictionary *)errorEnvironment
{
    return [self initWithRawContent:rawContent
                               date:date
                   errorEnvironment:errorEnvironment
                     appEnvironment:nil];
}

- (instancetype)initWithRawContent:(NSString *)rawContent
                              date:(NSDate *)date
                  errorEnvironment:(NSDictionary *)errorEnvironment
                    appEnvironment:(NSDictionary *)appEnvironment
{
    self = [super init];
    if (self != nil) {
        _rawContent = rawContent ? [rawContent copy] : @"";
        _date = date;
        _errorEnvironment = [errorEnvironment copy];
        _appEnvironment = [appEnvironment copy];
    }
    return self;
}

+ (instancetype)crashWithRawContent:(NSString *)rawContent
                               date:(NSDate *)date
                   errorEnvironment:(NSDictionary *)errorEnvironment
                     appEnvironment:(NSDictionary *)appEnvironment
{
    return [[self alloc] initWithRawContent:rawContent
                                       date:date
                           errorEnvironment:errorEnvironment
                             appEnvironment:appEnvironment];
}

+ (instancetype)crashWithRawContent:(NSString *)rawContent
                               date:(NSDate *)date
                   errorEnvironment:(NSDictionary *)errorEnvironment
{
    return [[self alloc] initWithRawContent:rawContent date:date errorEnvironment:errorEnvironment];
}


@end
