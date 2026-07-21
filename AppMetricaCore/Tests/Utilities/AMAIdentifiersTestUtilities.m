
#import <UIKit/UIKit.h>
#import "AMAIdentifiersTestUtilities.h"
#import "AMAStartupClientIdentifier.h"
#import <AdSupport/AdSupport.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAMetricaConfiguration.h"
#import "AMAStartupClientIdentifierFactory.h"
#import "AMAAdProviderProxy.h"
#import "AMAIdentifierProviderMock.h"

static AMAIdentifierProviderMock *identifierManagerMock;

@implementation AMAIdentifiersTestUtilities

+ (AMAIdentifierProviderMock *)stubIdentifierProviderIfNeeded
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        identifierManagerMock = [[AMAIdentifierProviderMock alloc] init];
    });
    
    AMAMetricaConfiguration *cfg = [AMAMetricaConfiguration sharedInstance];
    [cfg stub:@selector(identifierProvider) andReturn:identifierManagerMock];
    [cfg stub:@selector(appMetricaUUID) withBlock:^id(NSArray *params) {
        return identifierManagerMock.appMetricaUUID;
    }];
    [cfg stub:@selector(deviceID) withBlock:^id(NSArray *params) {
        return identifierManagerMock.deviceID;
    }];
    [cfg stub:@selector(deviceIDHash) withBlock:^id(NSArray *params) {
        return identifierManagerMock.deviceIDHash;
    }];
    return identifierManagerMock;
}

+ (void)stubIdfaWithEnabled:(BOOL)isEnabled value:(NSString *)UUID
{
    AMAAdProviderProxy *idfaMock = [AMAAdProviderProxy mock];
    [idfaMock stub:@selector(isAdvertisingTrackingEnabled) andReturn:theValue(isEnabled)];
    NSUUID *idfa = [[NSUUID alloc] initWithUUIDString:UUID];
    [idfaMock stub:@selector(advertisingIdentifier) andReturn:idfa];
    [idfaMock stub:@selector(setIsEnabled:)];
    [idfaMock stub:@selector(markActivationCompleted)];
    [AMAAdProviderProxy stub:@selector(sharedInstance) andReturn:idfaMock];
}

+ (void)stubUUID:(NSString *)UUID
{
    AMAIdentifierProviderMock *mock = [self stubIdentifierProviderIfNeeded];
    mock.mockMetricaUUID = UUID;
}

+ (void)stubDeviceID:(NSString *)deviceID
{
    AMAIdentifierProviderMock *mock = [self stubIdentifierProviderIfNeeded];
    mock.mockDeviceID = deviceID;
}

+ (void)stubIFV:(NSString *)UUID
{
    id deviceMock = [UIDevice nullMock];
    NSUUID *ifv = [[NSUUID alloc] initWithUUIDString:UUID];
    [deviceMock stub:@selector(identifierForVendor) andReturn:ifv];
    [UIDevice stub:@selector(currentDevice) andReturn:deviceMock];
}

+ (void)stubDeviceIDHash:(NSString *)deviceIDHash
{
    AMAIdentifierProviderMock *mock = [self stubIdentifierProviderIfNeeded];
    mock.mockDeviceHashID = deviceIDHash;
}

+ (void)stubClientIdentifiersProvider:(NSString *)UUID
                             deviceID:(NSString *)deviceID
                                  ifv:(NSString *)ifv
                         deviceIDHash:(NSString *)deviceIDHash
{
    AMAStartupClientIdentifier *startupClientID = [AMAStartupClientIdentifierFactory mock];
    [startupClientID stub:@selector(UUID) andReturn:UUID];
    [startupClientID stub:@selector(deviceID) andReturn:deviceID];
    [startupClientID stub:@selector(IFV) andReturn:ifv];
    [startupClientID stub:@selector(deviceIDHash) andReturn:deviceIDHash];
    [AMAStartupClientIdentifier stub:@selector(alloc) andReturn:startupClientID];
}

+ (void)destubIFV
{
    [UIDevice clearStubs];
}

+ (void)destubIDFA
{
    [AMAAdProviderProxy clearStubs];
}

+ (void)destubUUID
{
    [[AMAMetricaConfiguration sharedInstance] clearStubs];
}

+ (void)destubIdentifierProvider
{
    [AMAStartupClientIdentifier clearStubs];
    [[AMAMetricaConfiguration sharedInstance] clearStubs];
}

+ (void)destubAll
{
    [self destubIFV];
    [self destubIDFA];
    [self destubUUID];
    [self destubIdentifierProvider];
}

@end
