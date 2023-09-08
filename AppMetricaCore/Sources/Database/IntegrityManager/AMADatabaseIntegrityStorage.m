
#import "AMACore.h"
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMADatabaseIntegrityStorage.h"

static NSString *const kAMAIncidentsCountKey = @"incidents_count";
static NSString *const kAMAFirstIncidentDateKey = @"first_incident_date";
static NSString *const kAMALastIncidentDateKey = @"last_incident_date";

@interface AMADatabaseIntegrityStorage ()

@property (nonatomic, strong, readonly) id<AMAKeyValueStorageProviding> storageProvider;
@property (nonatomic, strong, readonly) id<AMADateProviding> dateProvider;

@property (nonatomic, strong, readonly) id<AMAKeyValueStoring> storage;

@end

@implementation AMADatabaseIntegrityStorage

- (instancetype)initWithStorageProvider:(id<AMAKeyValueStorageProviding>)storageProvider
{
    return [self initWithStorageProvider:storageProvider
                            dateProvider:[[AMADateProvider alloc] init]];
}

- (instancetype)initWithStorageProvider:(id<AMAKeyValueStorageProviding>)storageProvider
                           dateProvider:(id<AMADateProviding>) dateProvider
{
    self = [super init];
    if (self != nil) {
        _storageProvider = storageProvider;
        _dateProvider = dateProvider;
    }
    return self;
}

- (id<AMAKeyValueStoring>)storage
{
    return self.storageProvider.syncStorage;
}

#pragma mark - Properties

- (NSUInteger)incidentsCount
{
    return [self.storage unsignedLongLongNumberForKey:kAMAIncidentsCountKey error:NULL].unsignedIntegerValue;
}

- (NSDate *)firstIncidentDate
{
    return [self.storage dateForKey:kAMAFirstIncidentDateKey error:NULL];
}

- (NSDate *)lastIncidentDate
{
    return [self.storage dateForKey:kAMALastIncidentDateKey error:NULL];
}

#pragma mark - Methods

- (void)handleIncident
{
    NSDate *now = [self.dateProvider currentDate];

    id<AMAKeyValueStoring> storage = [self.storageProvider emptyNonPersistentStorage];
    [storage saveUnsignedLongLongNumber:@(self.incidentsCount + 1) forKey:kAMAIncidentsCountKey error:NULL];
    [storage saveDate:(self.firstIncidentDate ?: now) forKey:kAMAFirstIncidentDateKey error:NULL];
    [storage saveDate:now forKey:kAMALastIncidentDateKey error:NULL];
    [self.storageProvider saveStorage:storage error:NULL];
}

@end
