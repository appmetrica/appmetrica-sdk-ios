
#import "AMAIdentifierProviderMock.h"

@implementation AMAIdentifierProviderMock

- (instancetype)init 
{
    self = [super init];
    if (self) {
        self.mockDeviceID = nil;
        self.mockDeviceHashID = nil;
        self.mockMetricaUUID = nil;
    }
    return self;
}

+ (instancetype)randomInstance
{
    AMAIdentifierProviderMock *mock = [self new];
    [mock fillRandom];
    return mock;
}

- (void)fillRandom
{
    self.mockDeviceID = [[NSUUID UUID] UUIDString];
    
    NSMutableString *newUUID = [NSMutableString stringWithCapacity:32];
    for (int i = 0; i < 4; i++) {
        [newUUID appendFormat:@"%02x", arc4random()];
    }
    self.mockMetricaUUID = newUUID;
    
    self.mockDeviceHashID = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
}

- (NSString * _Nullable)deviceIDHash
{
    return self.mockDeviceHashID;
}

- (NSString * _Nullable)deviceID
{
    return self.mockDeviceID;
}

- (NSString * _Nullable)appMetricaUUID
{
    return self.mockMetricaUUID;
}

- (void)updateAppMigrationDataWithDeviceID:(NSString *)deviceID deviceIDHash:(NSString *)deviceIDHash
{
    if (self.mockDeviceID == nil) {
        self.mockDeviceID = deviceID;
        self.mockDeviceHashID = deviceIDHash;
    }
}

- (void)updateAppMigrationDataWithUuid:(NSString *)uuid
{
    if (self.mockMetricaUUID == nil) {
        self.mockMetricaUUID = uuid;
    }
}

- (void)updateWithDeviceID:(NSString * _Nonnull)deviceID
              deviceIDHash:(NSString * _Nullable)deviceIDHash
{
    self.mockDeviceID = deviceID;
    self.mockDeviceHashID = deviceIDHash;
}


@end
