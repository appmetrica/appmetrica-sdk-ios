
#import "AMAEventLogger.h"
#import "AMAEvent.h"
#import "AMACore.h"

static NSUInteger const kAMAEventLogAPIKeyPrefixLength = 8;
static NSUInteger const kAMAEventLogAPIKeySuffixLength = 4;
static NSString *const kAMAEventLogAPIKeyMiddleMask = @"-xxxx-xxxx-xxxx-xxxxxxxx";
static NSUInteger const kAMAEventLogAPIKeyRequiredLength = 36;

@interface AMAEventLogger ()

@property (nonatomic, copy, readonly) NSString *apiKey;
@property (nonatomic, copy, readonly) NSString *secureApiKeyString;

@end

@implementation AMAEventLogger

- (instancetype)initWithApiKey:(NSString *)apiKey
{
    self = [super init];
    if (self != nil) {
        _apiKey = [apiKey copy];

        if (apiKey.length == kAMAEventLogAPIKeyRequiredLength) {
            NSString *apiKeyPrefix = [apiKey substringToIndex:kAMAEventLogAPIKeyPrefixLength];
            NSString *apiKeySuffix = [apiKey substringFromIndex:apiKey.length - kAMAEventLogAPIKeySuffixLength];
            _secureApiKeyString =
                [NSString stringWithFormat:@"%@%@%@", apiKeyPrefix, kAMAEventLogAPIKeyMiddleMask, apiKeySuffix];
        }
    }
    return self;
}

- (NSString *)nameForEventType:(AMAEventType)type
{
    switch (type) {
        case AMAEventTypeInit:
            return @"Init";
        case AMAEventTypeStart:
            return @"Start";
        case AMAEventTypeProtobufCrash:
            return @"Crash (protobuf)";
        case AMAEventTypeProtobufANR:
            return @"Application not responding (protobuf)";
        case AMAEventTypeClient:
            return @"Client";
        case AMAEventTypeReferrer:
            return @"Referrer";
        case AMAEventTypeProtobufError:
            return @"Error";
        case AMAEventTypeAlive:
            return @"Alive";
        case AMAEventTypeFirst:
            return @"First";
        case AMAEventTypeOpen:
            return @"Open";
        case AMAEventTypeUpdate:
            return @"Update";
        case AMAEventTypeProfile:
            return @"Profile";
        case AMAEventTypeRevenue:
            return @"Revenue";
        case AMAEventTypeCleanup:
            return @"Cleanup";
        case AMAEventTypeECommerce:
            return @"E-Commerce";
        case AMAEventTypeAdRevenue:
            return @"AdRevenue";
        default:
            return nil;
    }
}

- (NSString *)eventDescriptionWithEventName:(NSString *)name
                                   eventOid:(NSNumber *)eventOid
                                 sessionOid:(NSNumber *)sessionOid
                             sequenceNumber:(NSNumber *)sequenceNumber
{
    return [NSString stringWithFormat:@"eventOid %@, "
                                       "sessionOid %@, "
                                       "sequenceNumber %@, "
                                       "name '%@'",
            eventOid, sessionOid, sequenceNumber, name];
}

- (void)logAction:(NSString *)action eventType:(AMAEventType)eventType eventName:(NSString *)eventName
{
    NSString *description = [self eventDescriptionWithEventName:eventName
                                                       eventOid:nil
                                                     sessionOid:nil
                                                 sequenceNumber:nil];
    [self logAction:action eventType:eventType description:description];
}

- (void)logAction:(NSString *)action event:(AMAEvent *)event
{
    NSString *description = [self eventDescriptionWithEventName:event.name
                                                       eventOid:event.oid
                                                     sessionOid:event.sessionOid
                                                 sequenceNumber:@(event.sequenceNumber)];
    [self logAction:action eventType:event.type description:description];
}

- (void)logAction:(NSString *)action
        eventType:(AMAEventType)eventType
      description:(NSString *)description
{
    NSMutableString *message = [NSMutableString string];
    NSString *typeName = [self nameForEventType:eventType];
    if (typeName != nil) {
        [message appendFormat:@"%@ event", typeName];
    }
    else {
        [message appendFormat:@"Event [%lu]", (unsigned long)eventType];
    }
    [message appendFormat:@" is %@", action];
    if (description.length > 0) {
        [message appendFormat:@": %@", description];
    }
    if (self.secureApiKeyString.length > 0) {
        [message appendFormat:@". (apiKey: %@)", self.secureApiKeyString];
    }
    [message appendString:@"."];

    AMALogInfo(@"%@", message);
}

- (void)logEventReceivedWithName:(NSString *)name type:(AMAEventType)type
{
    [self logAction:@"received" eventType:type eventName:name];
}

- (void)logClientEventReceivedWithName:(NSString *)name
{
    [self logEventReceivedWithName:name type:AMAEventTypeClient];
}

- (void)logProfileEventReceived
{
    [self logEventReceivedWithName:nil type:AMAEventTypeProfile];
}

- (void)logRevenueEventReceived
{
    [self logEventReceivedWithName:nil type:AMAEventTypeRevenue];
}

- (void)logECommerceEventReceived
{
    [self logEventReceivedWithName:nil type:AMAEventTypeECommerce];
}

- (void)logAdRevenueEventReceived
{
    [self logEventReceivedWithName:nil type:AMAEventTypeAdRevenue];
}

- (void)logEventBuilt:(AMAEvent *)event
{
    [self logAction:@"built" event:event];
}

- (void)logEventSaved:(AMAEvent *)event
{
    [self logAction:@"saved to db" event:event];
}

- (void)logEventPurged:(AMAEvent *)event
{
    [self logAction:@"removed from db" event:event];
}

- (void)logEventSent:(AMAEvent *)event
{
    [self logAction:@"sent" event:event];
}

+ (instancetype)sharedInstanceForApiKey:(NSString *)apiKey
{
    if (apiKey == nil) {
        return nil;
    }

    static NSMutableDictionary *instances = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instances = [NSMutableDictionary dictionary];
    });

    AMAEventLogger *logger = nil;
    @synchronized (self) {
        logger = instances[apiKey];
        if (logger == nil) {
            logger = [[AMAEventLogger alloc] initWithApiKey:apiKey];
            instances[apiKey] = logger;
        }
    }
    return logger;
}

@end
