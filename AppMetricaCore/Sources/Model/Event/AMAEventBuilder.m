
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import "AMACore.h"
#import "AMAEventBuilder.h"
#import "AMAEvent.h"
#import "AMAEventTypeResolver.h"
#import "AMAErrorsFactory.h"
#import "AMAAppMetricaPreloadInfo+AMAInternal.h"
#import "AMAReporterStateStorage.h"
#import "AMAEventValueFactory.h"
#import "AMAEventComposer.h"
#import "AMAEventComposerProvider.h"

@interface AMAEventBuilder ()

@property (nonatomic, strong, readonly) AMAReporterStateStorage *stateStorage;
@property (nonatomic, strong, readonly) AMAEventValueFactory *eventValueFactory;
@property (nonatomic, strong, readonly) id<AMAStringTruncating> nameTruncator;
@property (nonatomic, strong, readonly) id<AMADataEncoding> gZipEncoder;
@property (nonatomic, strong, readonly) AMAEventComposerProvider *eventComposerProvider;

@end

@implementation AMAEventBuilder

- (instancetype)initWithStateStorage:(AMAReporterStateStorage *)stateStorage
                         preloadInfo:(AMAAppMetricaPreloadInfo *)preloadInfo
{
    return [self initWithStateStorage:stateStorage
                          preloadInfo:preloadInfo
                    eventValueFactory:[[AMAEventValueFactory alloc] init]
                          gZipEncoder:[[AMAGZipDataEncoder alloc] init]
                eventComposerProvider:[[AMAEventComposerProvider alloc] initWithStateStorage:stateStorage]];
}

- (instancetype)initWithStateStorage:(AMAReporterStateStorage *)stateStorage
                         preloadInfo:(AMAAppMetricaPreloadInfo *)preloadInfo
                   eventValueFactory:(AMAEventValueFactory *)eventValueFactory
                         gZipEncoder:(id<AMADataEncoding>)gZipEncoder
               eventComposerProvider:(AMAEventComposerProvider *)eventComposerProvider
{
    self = [super init];
    if (self != nil) {
        _stateStorage = stateStorage;
        _preloadInfo = [preloadInfo copy];
        _eventValueFactory = eventValueFactory;
        _gZipEncoder = gZipEncoder;
        _nameTruncator = [AMATruncatorsFactory eventNameTruncator];
        _eventComposerProvider = eventComposerProvider;
    }
    return self;
}

#pragma mark - Public

- (AMAEvent *)clientEventNamed:(NSString *)eventName
                    parameters:(NSDictionary *)parameters
               firstOccurrence:(AMAOptionalBool)firstOccurrence
                         error:(NSError **)outError
{
    if (eventName.length == 0) {
        [AMAErrorUtilities fillError:outError
                           withError:[AMAErrorsFactory badEventNameError:eventName]];
        return nil;
    }

    NSError *error = nil;
    NSString *jsonValue = [self jsonStringFromDictionary:parameters error:&error];
    if (error != nil) {
        [AMAErrorUtilities fillError:outError withError:error];
        return nil;
    }

    AMAEvent *event = [self eventOfType:AMAEventTypeClient];
    [self fillEvent:event withName:eventName];
    [self fillEvent:event withStringValue:jsonValue];
    event.firstOccurrence = firstOccurrence;
    return event;
}

- (AMAEvent *)eventWithInternalParameters:(AMACustomEventParameters *)parameters
                                    error:(NSError **)error
{
    NSError *internalError = nil;
    BOOL gZipped = NO;
    NSData *data = parameters.data;
    
    if (parameters.GZipped) {
        NSData *gZippedData = [self.gZipEncoder encodeData:data error:&internalError];
        if (internalError == nil) {
            data = gZippedData;
            gZipped = YES;
        }
        else {
            AMALogWarn(@"Failed to gzip data: %@", internalError);
            [AMAErrorUtilities fillError:error withError:internalError];
        }
    }
    
    AMAEvent *event = [self eventOfType:parameters.eventType];
    
    NSUInteger bytesTruncated = 0;
    switch (parameters.valueType) {
        case AMAEventValueTypeFile: {
            AMAEventEncryptionType encryption = parameters.encrypted ? AMAEventEncryptionTypeAESv1 : AMAEventEncryptionTypeNoEncryption;
            AMAEventValueFactoryTruncationType truncation = parameters.truncated
                ? AMAEventValueFactoryTruncationTypeFull
                : AMAEventValueFactoryTruncationTypePartial;
            
            NSString *fileName = parameters.fileName ?: [NSString stringWithFormat:@"%@.event", NSUUID.UUID.UUIDString];
            event.value = [self.eventValueFactory fileEventValue:data
                                                        fileName:fileName
                                                  encryptionType:encryption
                                                  truncationType:truncation
                                                  bytesTruncated:&bytesTruncated
                                                           error:&internalError];
        }
            break;
        case AMAEventValueTypeBinary:
            event.value = [self.eventValueFactory binaryEventValue:data
                                                           gZipped:gZipped
                                                    bytesTruncated:&bytesTruncated];
            break;
        case AMAEventValueTypeString: {
            NSError *serializationError = nil;
            //TODO: rewrite event parameters
            NSString *stringValue = [AMAJSONSerialization stringWithJSONObject:data error:&serializationError];
            
            if (serializationError != nil) {
                [AMAErrorUtilities fillError:error withError:internalError];
                return nil;
            }
            event.value = [self.eventValueFactory stringEventValue:stringValue
                                                    bytesTruncated:&bytesTruncated];
        }
            break;
        default:
            internalError = [NSError errorWithDomain:@"AMAEventBuilderErrorDomain"
                                                code:0
                                            userInfo:@{NSLocalizedDescriptionKey: @"Invalid storage type"}];
            AMALogAssert(@"Invalid value type: %ld", (long)parameters.valueType);
            [AMAErrorUtilities fillError:error withError:internalError];
            return nil;
    }
    [self logTruncation:@"value" event:event bytesTruncated:bytesTruncated];
    
    [self fillEvent:event withName:parameters.name];
    event.bytesTruncated += (parameters.bytesTruncated + bytesTruncated);
    event.appEnvironment = parameters.appEnvironment;
    event.errorEnvironment = parameters.errorEnvironment;
    [self fillEvent:event withExtras:parameters.extras];
    event.createdAt = parameters.isPast ? parameters.creationDate : event.createdAt;

    return event;
}

- (AMAEvent *)eventReferrerWithValue:(NSString *)value
                               error:(NSError **)outError
{
    if (value.length == 0) {
        [AMAErrorUtilities fillError:outError
                          withError:[AMAErrorsFactory emptyReferrerValueError]];
        return nil;
    }
    AMAEvent *event = [self eventOfType:AMAEventTypeReferrer];
    [self fillEvent:event withStringValue:value];
    return event;
}

- (AMAEvent *)eventASATokenWithParameters:(NSDictionary *)parameters error:(NSError **)error
{
    NSError *internalError = nil;
    NSString *jsonValue = [self jsonStringFromDictionary:parameters error:&internalError];
    if (internalError != nil) {
        [AMAErrorUtilities fillError:error withError:internalError];
        return nil;
    }

    AMAEvent *event = [self eventOfType:AMAEventTypeASAToken];
    [self fillEvent:event withStringValue:jsonValue];
    return event;
}

- (AMAEvent *)eventOpen:(NSDictionary *)parameters
   attributionIDChanged:(BOOL)attributionIDChanged
                  error:(NSError **)outError
{
    NSError *error = nil;
    NSString *jsonValue = [self jsonStringFromDictionary:parameters error:&error];
    if (error != nil) {
        [AMAErrorUtilities fillError:outError withError:error];
        return nil;
    }

    AMAEvent *event = [self eventOfType:AMAEventTypeOpen];
    [self fillEvent:event withStringValue:jsonValue];
    event.attributionIDChanged = attributionIDChanged;
    return event;
}

- (AMAEvent *)eventInitWithParameters:(NSDictionary *)parameters error:(NSError **)outError
{
    return [self crucialEventWithType:AMAEventTypeInit parameters:parameters error:outError];
}

- (AMAEvent *)eventUpdateWithError:(NSError **)outError
{
    return [self crucialEventWithType:AMAEventTypeUpdate parameters:nil error:outError];
}

- (AMAEvent *)eventFirstWithError:(NSError **)outError
{
    return [self crucialEventWithType:AMAEventTypeFirst parameters:nil error:outError];
}

- (AMAEvent *)permissionsEventWithJSON:(NSString *)permissions error:(NSError **)outError;
{
    AMAEvent *event = [self eventOfType:AMAEventTypePermissions];
    [self fillEvent:event withStringValue:permissions];
    return event;
}

- (AMAEvent *)crucialEventWithType:(AMAEventType)type parameters:(NSDictionary *)parameters error:(NSError **)outError
{
    NSError *error = nil;

    AMAEvent *event = [self eventOfType:type];
    [self addPreloadInfo:self.preloadInfo parameters:parameters toEvent:event error:&error];

    if (error != nil) {
        [AMAErrorUtilities fillError:outError withError:error];
    }

    // Deliberately return inconsistent event if error occurs
    // Why? This event is crucial for statistics, so it's ok to lose preloadInfo is this case
    return event;
}

- (AMAEvent *)eventWithType:(NSUInteger)eventType
                       name:(NSString *)name
                      value:(NSString *)value
           eventEnvironment:(NSDictionary *)eventEnvironment
                     extras:(NSDictionary<NSString *, NSData *> *)extras
                      error:(NSError **)outError
{
    if ([AMAEventTypeResolver isEventTypeReserved:eventType]) {
        [AMAErrorUtilities fillError:outError
                          withError:[AMAErrorsFactory eventTypeReservedError:eventType]];
        return nil;
    }
    AMAEvent *event = [self eventOfType:eventType];
    [self fillEvent:event withName:name];
    [self fillEvent:event withStringValue:value];
    [self fillEvent:event withExtras:extras];
    event.errorEnvironment = eventEnvironment;

    return event;
}

- (AMAEvent *)binaryEventWithType:(NSUInteger)eventType
                             data:(NSData *)data
                          gZipped:(BOOL)gZipped
                      environment:(NSDictionary *)environment
                           extras:(NSDictionary<NSString *,NSData *> *)extras
                            error:(NSError **)outError
{
    if ([AMAEventTypeResolver isEventTypeReserved:eventType]) {
        [AMAErrorUtilities fillError:outError
                           withError:[AMAErrorsFactory eventTypeReservedError:eventType]];
        return nil;
    }
    
    NSError *internalError = nil;
    BOOL gZippedValid = NO;
    NSData *validData = data;
    if (gZipped) {
        NSData *gZippedData = [self gzipData:data error:&internalError];
        if (internalError == nil) {
            validData = gZippedData;
            gZippedValid = YES;
        }
        else {
            [AMAErrorUtilities fillError:outError withError:internalError];
        }
    }
    
    AMAEvent *event = [self eventOfType:eventType];
    
    [self fillEvent:event withBinaryValue:validData gZipped:gZippedValid];
    
    [self fillEvent:event withExtras:extras];
    event.errorEnvironment = environment;
    
    return event;
}

- (AMAEvent *)fileEventWithType:(NSUInteger)eventType
                           data:(NSData *)data
                       fileName:(NSString *)fileName
                        gZipped:(BOOL)gZipped
                      encrypted:(BOOL)encrypted
                      truncated:(BOOL)truncated
                    environment:(NSDictionary *)environment
                         extras:(NSDictionary<NSString *,NSData *> *)extras
                          error:(NSError **)outError
{
    if ([AMAEventTypeResolver isEventTypeReserved:eventType]) {
        [AMAErrorUtilities fillError:outError
                          withError:[AMAErrorsFactory eventTypeReservedError:eventType]];
        return nil;
    }
    
    NSError *internalError = nil;
    NSData *validData = data;
    if (gZipped) {
        NSData *gZippedData = [self gzipData:data error:&internalError];
        if (internalError == nil) {
            validData = gZippedData;
        }
        else {
            [AMAErrorUtilities fillError:outError withError:internalError];
        }
    }
    
    AMAEvent *event = [self eventOfType:eventType];
    
    NSString *validFileName = fileName.length == 0
        ? [NSString stringWithFormat:@"%@.event", NSUUID.UUID.UUIDString]
        : fileName;
    
    [self fillEvent:event
      withFileValue:validData
           fileName:validFileName
          encrypted:encrypted
          truncated:truncated
              error:outError];
    
    [self fillEvent:event withExtras:extras];
    event.errorEnvironment = environment;

    return event;
}

- (void)addPreloadInfo:(AMAAppMetricaPreloadInfo *)info
            parameters:(NSDictionary *)parameters
               toEvent:(AMAEvent *)event
                 error:(NSError **)outError
{
    NSMutableDictionary *combined = [NSMutableDictionary dictionary];
    if (parameters != nil) {
        [combined addEntriesFromDictionary:parameters];
    }
    if (info != nil) {
        [combined addEntriesFromDictionary:info.preloadInfoJSONObject];
    }

    if (combined.count > 0) {
        NSString *jsonValue = [self jsonStringFromDictionary:combined error:outError];
        [self fillEvent:event withStringValue:jsonValue];
    }
}

- (AMAEvent *)eventStartWithData:(NSData *)data
{
    AMAEvent *event = [self eventOfType:AMAEventTypeStart];
    [self fillEvent:event withBinaryValue:data gZipped:NO];
    return event;
}

- (AMAEvent *)eventAlive
{
    return [self eventOfType:AMAEventTypeAlive];
}

- (AMAEvent *)eventProfile:(NSData *)profileData
{
    AMAEvent *event = [self eventOfType:AMAEventTypeProfile];
    [self fillEvent:event withBinaryValue:profileData gZipped:NO];
    return event;
}

- (AMAEvent *)eventRevenue:(NSData *)revenueData
            bytesTruncated:(NSUInteger)bytesTruncated
{
    AMAEvent *event = [self eventOfType:AMAEventTypeRevenue];
    event.bytesTruncated += bytesTruncated;
    [self fillEvent:event withBinaryValue:revenueData gZipped:NO];
    return event;
}

- (AMAEvent *)eventCleanup:(NSDictionary *)parameters
                     error:(NSError **)outError
{
    NSError *error = nil;
    NSString *jsonValue = [self jsonStringFromDictionary:parameters error:&error];
    if (error != nil) {
        [AMAErrorUtilities fillError:outError withError:error];
        return nil;
    }

    AMAEvent *event = [self eventOfType:AMAEventTypeCleanup];
    [self fillEvent:event withStringValue:jsonValue];
    return event;
}

- (AMAEvent *)eventECommerce:(NSData *)eCommerceData
              bytesTruncated:(NSUInteger)bytesTruncated
{
    AMAEvent *event = [self eventOfType:AMAEventTypeECommerce];
    event.bytesTruncated += bytesTruncated;
    [self fillEvent:event withBinaryValue:eCommerceData gZipped:NO];
    return event;
}

- (AMAEvent *)eventAdRevenue:(NSData *)adRevenueData
              bytesTruncated:(NSUInteger)bytesTruncated
{
    AMAEvent *event = [self eventOfType:AMAEventTypeAdRevenue];
    event.bytesTruncated += bytesTruncated;
    [self fillEvent:event withBinaryValue:adRevenueData gZipped:NO];
    return event;
}

- (AMAEvent *)jsEvent:(NSString *)name value:(NSString *)value
{
    if (name.length == 0) {
        AMALogWarn(@"Ignoring event from JS: event name is empty.");
        return nil;
    }
    AMAEvent *event = [self eventOfType:AMAEventTypeClient];
    [self fillEvent:event withStringValue:value];
    event.name = name;
    event.source = AMAEventSourceJs;
    return event;
}

- (AMAEvent *)jsInitEvent:(NSString *)value
{
    if (value.length == 0) {
        AMALogWarn(@"Ignoring init event from JS: value is empty.");
        return nil;
    }
    AMAEvent *event = [self eventOfType:AMAEventTypeWebViewSync];
    [self fillEvent:event withStringValue:value];
    event.source = AMAEventSourceJs;
    return event;
}

- (AMAEvent *)attributionEventWithName:(NSString *)name value:(NSDictionary *)value
{
    AMAEvent *event = [self eventOfType:AMAEventTypeAttribution];
    [self fillEvent:event withName:name];
    NSError *internalError = nil;
    NSString *jsonValue = [self jsonStringFromDictionary:value error:&internalError];
    if (internalError != nil) {
        AMALogError(@"Failed to serialize auto app open event value: %@", internalError);
        return nil;
    }
    [self fillEvent:event withStringValue:jsonValue];
    return event;
}

#pragma mark - Private -

- (void)fillEvent:(AMAEvent *)event withName:(NSString *)name
{
    NSUInteger __block bytesTruncated = 0;
    event.name = [self.nameTruncator truncatedString:name onTruncation:^(NSUInteger truncated) {
        bytesTruncated = truncated;
    }];
    event.bytesTruncated += bytesTruncated;
    [self logTruncation:@"name" event:event bytesTruncated:bytesTruncated];
}

- (void)fillEvent:(AMAEvent *)event withStringValue:(NSString *)value
{
    NSUInteger bytesTruncated = 0;
    event.value = [self.eventValueFactory stringEventValue:value bytesTruncated:&bytesTruncated];
    event.bytesTruncated += bytesTruncated;
    [self logTruncation:@"value" event:event bytesTruncated:bytesTruncated];
}

- (void)fillEvent:(AMAEvent *)event
  withBinaryValue:(NSData *)value
          gZipped:(BOOL)gZipped
{
    NSUInteger bytesTruncated = 0;
    event.value = [self.eventValueFactory binaryEventValue:value gZipped:gZipped bytesTruncated:&bytesTruncated];
    event.bytesTruncated += bytesTruncated;
    [self logTruncation:@"value" event:event bytesTruncated:bytesTruncated];
}

- (void)fillEvent:(AMAEvent *)event
    withFileValue:(NSData *)value
         fileName:(NSString *)fileName
        encrypted:(BOOL)encrypted
        truncated:(BOOL)truncated
            error:(NSError **)outError
{
    NSError *internalError = nil;
    NSUInteger bytesTruncated = 0;
    
    AMAEventEncryptionType encryption = encrypted ? AMAEventEncryptionTypeAESv1 : AMAEventEncryptionTypeNoEncryption;
    AMAEventValueFactoryTruncationType truncation = truncated
        ? AMAEventValueFactoryTruncationTypePartial
        : AMAEventValueFactoryTruncationTypeFull;
    
    event.value = [self.eventValueFactory fileEventValue:value
                                                fileName:fileName
                                          encryptionType:encryption
                                          truncationType:truncation
                                          bytesTruncated:&bytesTruncated
                                                   error:&internalError];
    if (internalError != nil) {
        event = nil;
        AMALogError(@"Failed to create file event value: %@", internalError);
        [AMAErrorUtilities fillError:outError withError:internalError];
    }
    else {
        event.bytesTruncated += bytesTruncated;
        [self logTruncation:@"value" event:event bytesTruncated:bytesTruncated];
    }
}

- (void)fillEvent:(AMAEvent *)event
       withExtras:(NSDictionary<NSString *, NSData *> *)eventExtras
{
    // event.extras contains session extras
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:event.extras];
    
    // merge it with event extras, session extras has priority over event extras
    for (NSString *key in eventExtras) {
        if ([self eventHasSessionExtrasPriority:event]) {
            result[key] = result[key] ?: eventExtras[key];
        }
        // Event extras has higher priority
        else if ([eventExtras objectForKey:key] != nil) {
            result[key] = eventExtras[key];
        }
    }
    
    event.extras = [result copy];
}

- (void)logTruncation:(NSString *)fieldName
                event:(AMAEvent *)event
       bytesTruncated:(NSUInteger)bytesTruncated
{
    if (bytesTruncated == 0) {
        return;
    }
    AMALogWarn(@"Event %@ truncated, it is too long", fieldName);
    AMALogWarn(@"Truncated event %@", event);
}

- (AMAEvent *)eventOfType:(NSUInteger)type
{
    AMAEvent *event = [[AMAEvent alloc] init];
    event.type = type;
    [[self.eventComposerProvider composerForType:type] compose:event];
    return event;
}

- (NSString *)jsonStringFromDictionary:(NSDictionary *)dictionary error:(NSError **)error
{
    return dictionary.count != 0
        ? [AMAJSONSerialization stringWithJSONObject:dictionary error:error]
        : nil;
}

- (NSData *)gzipData:(NSData *)data error:(NSError **)error
{
    NSError *internalError = nil;
    NSData *gZippedData = [self.gZipEncoder encodeData:data error:&internalError];
    if (internalError != nil) {
        AMALogWarn(@"Failed to gzip data: %@", internalError);
        [AMAErrorUtilities fillError:error withError:internalError];
    }
    return gZippedData;
}

- (BOOL)eventHasSessionExtrasPriority:(AMAEvent *)event
{
    NSArray<NSNumber *> *excludedEventTypes = @[ @(12) ];
    return [excludedEventTypes containsObject:@(event.type)] == NO;
}

@end
