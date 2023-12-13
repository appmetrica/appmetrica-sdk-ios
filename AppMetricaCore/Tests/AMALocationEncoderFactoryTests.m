
#import <Kiwi/Kiwi.h>
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import "AMALocationEncoderFactory+Migration.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAAESUtility+Migration.h"
#import "AMAMigrationTo500Utils.h"

SPEC_BEGIN(AMALocationEncoderFactoryTests)

describe(@"AMALocationEncoderFactory", ^{
    
    context(@"Encoder", ^{
        it(@"Should return aes encoder with migration iv", ^{
            [[AMAAESUtility should] receive:@selector(defaultIv)];
            
            id<AMADataEncoding> encoder = [AMALocationEncoderFactory encoder];
        });
    });
    
    context(@"Migration encoder", ^{
        it(@"Should return aes encoder with migration iv", ^{
            [[AMAAESUtility should] receive:@selector(migrationIv:) withArguments:kAMAMigrationBundle];
            
            id<AMADataEncoding> encoder = [AMALocationEncoderFactory migrationEncoder];
        });
    });
});

SPEC_END

