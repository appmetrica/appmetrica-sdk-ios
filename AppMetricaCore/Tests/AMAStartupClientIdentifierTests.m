
#import <Kiwi/Kiwi.h>
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAIdentifiersTestUtilities.h"
#import "AMAStartupClientIdentifierFactory.h"
#import "AMAStartupClientIdentifier.h"

SPEC_BEGIN(AMAStartupClientIdentifierTests)

describe(@"AMAStartupClientIdentifier", ^{
    NSString *UUID = @"78753A44-4D6F-1226-9C60-0050E4C00067";
    NSString *UUDIDString = @"68753A44-4D6F-1226-9C60-0050E4C00067";
    NSString *IFV = @"98753A44-4D6F-1226-9C60-0050E4C00067";
    NSString *deviceIDHash = @"deviceIDHash";
    it(@"Should return ifv as device id", ^{
        [AMAMetricaConfigurationTestUtilities stubConfiguration];
        [[AMAMetricaConfiguration sharedInstance].persistent stub:@selector(deviceID) andReturn:IFV];

        [AMAIdentifiersTestUtilities stubIdfaWithEnabled:NO value:UUDIDString];
        AMAStartupClientIdentifier *identifier = [AMAStartupClientIdentifierFactory startupClientIdentifier];
        [[[identifier deviceID] should] equal:IFV];
    });

    it(@"Should take uuid from configuration", ^{
        [AMAIdentifiersTestUtilities stubUUID:UUID];
        AMAStartupClientIdentifier *identifier = [AMAStartupClientIdentifierFactory startupClientIdentifier];
        [[[identifier UUID] should] equal:UUID];
    });

    it(@"Should take ifv from system", ^{
        [AMAIdentifiersTestUtilities stubIFV:IFV];
        AMAStartupClientIdentifier *identifier = [AMAStartupClientIdentifierFactory startupClientIdentifier];
        [[[identifier IFV] should] equal:IFV];
    });

    it(@"Should take deviceIDHash from configuration", ^{
        [AMAIdentifiersTestUtilities stubDeviceIDHash:deviceIDHash];
        AMAStartupClientIdentifier *identifier = [AMAStartupClientIdentifierFactory startupClientIdentifier];
        [[[identifier deviceIDHash] should] equal:deviceIDHash];
    });
});

SPEC_END
