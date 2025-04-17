
#import <Kiwi/Kiwi.h>
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import "AMALocationMigrationTo500EncoderFactory.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAAESUtility+Migration.h"
#import "AMAMigrationTo500Utils.h"
#import "AMALocationEncryptionDefaults.h"

SPEC_BEGIN(AMALocationMigrationTo500EncoderFactoryTests)

describe(@"AMALocationMigrationTo500EncoderFactory", ^{
    
    __auto_type *const encoderFactory = [[AMALocationMigrationTo500EncoderFactory alloc] init];
    AMAAESCrypter *__block crypterMock = nil;
    
    beforeEach(^{
        crypterMock = [AMAAESCrypter stubbedNullMockForInit:@selector(initWithKey:iv:)];
    });
    
    context(@"Encoder", ^{
        it(@"Should return encoder", ^{
            NSData *iv = [NSData nullMock];
            NSData *message = [NSData nullMock];
            [AMAAESUtility stub:@selector(migrationIv:) andReturn:iv withArguments:kAMAMigrationBundle];
            [AMALocationEncryptionDefaults stub:@selector(message) andReturn:message];
            
            [[crypterMock should] receive:@selector(initWithKey:iv:) withArguments:message, iv];

            id<AMADataEncoding> encoder = [encoderFactory encoder];
        });
    });
});

SPEC_END

