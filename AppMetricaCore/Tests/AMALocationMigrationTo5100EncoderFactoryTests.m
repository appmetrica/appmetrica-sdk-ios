
#import <Kiwi/Kiwi.h>
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import "AMALocationMigrationTo5100EncoderFactory.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAAESUtility+Migration.h"
#import "AMAMigrationTo500Utils.h"
#import "AMALocationEncryptionDefaults.h"

SPEC_BEGIN(AMALocationMigrationTo5100EncoderFactoryTests)

describe(@"AMALocationMigrationTo5100EncoderFactory", ^{
    
    __auto_type *const encoderFactory = [[AMALocationMigrationTo5100EncoderFactory alloc] init];
    AMAAESCrypter *__block crypterMock = nil;
    
    beforeEach(^{
        crypterMock = [AMAAESCrypter stubbedNullMockForInit:@selector(initWithKey:iv:)];
    });
    
    context(@"Encoder", ^{
        it(@"Should return encoder", ^{
            NSData *iv = [NSData nullMock];
            NSData *message = [NSData nullMock];
            [AMAAESUtility stub:@selector(md5_migrationIv) andReturn:iv];
            [AMALocationEncryptionDefaults stub:@selector(message) andReturn:message];
            
            [[crypterMock should] receive:@selector(initWithKey:iv:) withArguments:message, iv];

            id<AMADataEncoding> encoder = [encoderFactory encoder];
        });
    });
});

SPEC_END

