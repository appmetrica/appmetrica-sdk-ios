
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import "AMALocationEncoderFactory.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAAESUtility+Migration.h"
#import "AMAMigrationTo500Utils.h"
#import "AMALocationEncryptionDefaults.h"

SPEC_BEGIN(AMALocationEncoderFactoryTests)

describe(@"AMALocationEncoderFactory", ^{
    
    __auto_type *const encoderFactory = [[AMALocationEncoderFactory alloc] init];
    AMAAESCrypter *__block crypterMock = nil;
    
    beforeEach(^{
        crypterMock = [AMAAESCrypter stubbedNullMockForInit:@selector(initWithKey:iv:)];
    });
    afterEach(^{
        [AMAAESCrypter clearStubs];
    });
    
    context(@"Encoder", ^{
        it(@"Should return encoder", ^{
            NSData *iv = [NSData nullMock];
            NSData *message = [NSData nullMock];
            [AMAAESUtility stub:@selector(defaultIv) andReturn:iv];
            [AMALocationEncryptionDefaults stub:@selector(message) andReturn:message];
            
            [[crypterMock should] receive:@selector(initWithKey:iv:) withArguments:message, iv];

            id<AMADataEncoding> encoder = [encoderFactory encoder];
            
            [AMAAESUtility clearStubs];
            [AMALocationEncryptionDefaults clearStubs];
        });
    });
});

SPEC_END

