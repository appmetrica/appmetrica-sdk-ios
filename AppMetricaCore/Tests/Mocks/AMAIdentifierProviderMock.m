
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

- (void)updateAppMetricaUUID:(NSString *)uuid
{
    self.mockMetricaUUID = uuid;
    return YES;
}

- (void)updateDeviceID:(NSString * _Nonnull)deviceID 
{
    self.mockDeviceID = deviceID;
}


- (void)updateDeviceIdHash:(NSString * _Nonnull)deviceHashID 
{
    self.mockDeviceHashID = deviceHashID;
}


@end
