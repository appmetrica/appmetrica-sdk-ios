
#import "AMACrashForwarder.h"
#import "AMACrashFilteringProxy.h"
#import "AMACrashEventConverter.h"
#import "AMACrashReporter.h"
#import "AMACrashEventType.h"
#import "AMADecodedCrash.h"
#import "AMADecodedCrashSerializer+CustomEventParameters.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>


@interface AMACrashForwarderEntry : NSObject
@property (nonatomic, strong) AMACrashEvent *crashEvent;
@property (nonatomic, strong) AMAEventPollingParameters *parameters;
@property (nonatomic, assign) BOOL isANR;
@end

@implementation AMACrashForwarderEntry
@end

@interface AMACrashForwarder ()

@property (nonatomic, strong) id<AMAAsyncExecuting, AMASyncExecuting> executor;
@property (nonatomic, strong) AMACrashEventConverter *converter;
@property (nonatomic, strong) AMADecodedCrashSerializer *serializer;
@property (nonatomic, strong) NSHashTable *handlers;
@property (nonatomic, strong) NSMutableDictionary<NSString *, AMACrashReporter *> *reporters;
@property (nonatomic, strong) NSMutableArray<AMACrashForwarderEntry *> *replayBuffer;

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
        _replayBuffer = [NSMutableArray array];
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
        if ([self.handlers containsObject:handler]) {
            return;
        }
        [self.handlers addObject:handler];
        for (AMACrashForwarderEntry *entry in self.replayBuffer) {
            if (entry.isANR) {
                if ([handler shouldReportANR:entry.crashEvent]) {
                    [[self reporterForAPIKey:handler.apiKey] reportANRWithParameters:entry.parameters];
                }
            } else {
                if ([handler shouldReportCrash:entry.crashEvent]) {
                    [[self reporterForAPIKey:handler.apiKey] reportCrashWithParameters:entry.parameters];
                }
            }
        }
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

        AMAEventPollingParameters *parameters =
            [self.serializer eventParametersFromDecodedData:decodedCrash
                                               forEventType:AMACrashEventTypeCrash
                                                      error:NULL];

        for (id<AMACrashFilteringProxy> handler in self.handlers) {
            if ([handler shouldReportCrash:crashEvent] && parameters != nil) {
                [[self reporterForAPIKey:handler.apiKey] reportCrashWithParameters:parameters];
            }
        }

        if (parameters != nil) {
            [self bufferCrashEvent:crashEvent parameters:parameters isANR:NO];
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

        AMAEventPollingParameters *parameters =
            [self.serializer eventParametersFromDecodedData:decodedCrash
                                               forEventType:AMACrashEventTypeANR
                                                      error:NULL];

        for (id<AMACrashFilteringProxy> handler in self.handlers) {
            if ([handler shouldReportANR:crashEvent] && parameters != nil) {
                [[self reporterForAPIKey:handler.apiKey] reportANRWithParameters:parameters];
            }
        }

        if (parameters != nil) {
            [self bufferCrashEvent:crashEvent parameters:parameters isANR:YES];
        }
    }];
}

#pragma mark - Private

- (void)bufferCrashEvent:(AMACrashEvent *)crashEvent
              parameters:(AMAEventPollingParameters *)parameters
                   isANR:(BOOL)isANR
{
    AMACrashForwarderEntry *entry = [[AMACrashForwarderEntry alloc] init];
    entry.crashEvent = crashEvent;
    entry.parameters = parameters;
    entry.isANR = isANR;
    [self.replayBuffer addObject:entry];
}

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
