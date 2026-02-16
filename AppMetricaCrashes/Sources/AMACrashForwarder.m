
#import "AMACrashForwarder.h"
#import "AMACrashFilteringProxy.h"
#import "AMACrashEventConverter.h"
#import "AMACrashReporter.h"
#import "AMACrashEventType.h"
#import "AMADecodedCrash.h"
#import "AMADecodedCrashSerializer+CustomEventParameters.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

@interface AMACrashForwarder ()

@property (nonatomic, strong) id<AMAAsyncExecuting, AMASyncExecuting> executor;
@property (nonatomic, strong) AMACrashEventConverter *converter;
@property (nonatomic, strong) AMADecodedCrashSerializer *serializer;
@property (nonatomic, strong) NSHashTable *handlers;
@property (nonatomic, strong) NSMutableDictionary<NSString *, AMACrashReporter *> *reporters;

@end

@implementation AMACrashForwarder

- (instancetype)initWithSerializer:(AMADecodedCrashSerializer *)serializer
{
    self = [super init];
    if (self != nil) {
        _executor = [[AMAExecutor alloc] initWithIdentifier:self];
        _converter = [[AMACrashEventConverter alloc] init];
        _serializer = serializer;
        _handlers = [NSHashTable weakObjectsHashTable];
        _reporters = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Registration

- (void)registerHandler:(id<AMACrashFilteringProxy>)handler
{
    if (handler == nil) {
        return;
    }
    [self.executor execute:^{
        [self.handlers addObject:handler];
    }];
}

#pragma mark - Processing

- (void)processCrash:(AMADecodedCrash *)decodedCrash
{
    if (decodedCrash == nil) {
        return;
    }

    [self.executor execute:^{
        AMACrashEvent *crashEvent = [self.converter crashEventFromDecodedCrash:decodedCrash];
        if (crashEvent == nil) {
            return;
        }

        AMAEventPollingParameters *__block parameters = nil;

        for (id<AMACrashFilteringProxy> handler in self.handlers) {
            if ([handler shouldReportCrash:crashEvent]) {
                if (parameters == nil) {
                    parameters = [self.serializer eventParametersFromDecodedData:decodedCrash
                                                                   forEventType:AMACrashEventTypeCrash
                                                                          error:NULL];
                }
                if (parameters != nil) {
                    [[self reporterForAPIKey:handler.apiKey] reportCrashWithParameters:parameters];
                }
            }
        }
    }];
}

- (void)processANR:(AMADecodedCrash *)decodedCrash
{
    if (decodedCrash == nil) {
        return;
    }

    [self.executor execute:^{
        AMACrashEvent *crashEvent = [self.converter crashEventFromDecodedCrash:decodedCrash];
        if (crashEvent == nil) {
            return;
        }

        AMAEventPollingParameters *__block parameters = nil;

        for (id<AMACrashFilteringProxy> handler in self.handlers) {
            if ([handler shouldReportANR:crashEvent]) {
                if (parameters == nil) {
                    parameters = [self.serializer eventParametersFromDecodedData:decodedCrash
                                                                   forEventType:AMACrashEventTypeANR
                                                                          error:NULL];
                }
                if (parameters != nil) {
                    [[self reporterForAPIKey:handler.apiKey] reportANRWithParameters:parameters];
                }
            }
        }
    }];
}

#pragma mark - Private

- (AMACrashReporter *)reporterForAPIKey:(NSString *)apiKey
{
    AMACrashReporter *reporter = self.reporters[apiKey];
    if (reporter == nil) {
        reporter = [[AMACrashReporter alloc] initWithApiKey:apiKey];
        self.reporters[apiKey] = reporter;
    }
    return reporter;
}

@end
