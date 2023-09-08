
#import <Kiwi/Kiwi.h>
#import "AMAEventNameHashProvider.h"

SPEC_BEGIN(AMAEventNameHashProviderTests)

describe(@"AMAEventNameHashProvider", ^{

    AMAEventNameHashProvider *__block provider = nil;

    beforeEach(^{
        provider = [[AMAEventNameHashProvider alloc] init];
    });

    it(@"Should return 0 for nil", ^{
        [[[provider hashForEventName:nil] should] equal:@0];
    });

    it(@"Should return part of SHA hash", ^{
        /*
         printf 'SAMPLE' | shasum
         05993e69c1712b1a21928277c8abfdc2ae39c214  -

         So first 8 bytes of SHA hash for 'SAMPLE' string are: 0x14 0xC2 0x39 0xAE 0xC2 0xFD 0xAB 0xC8
         */
        unsigned long long value = 0x14C239AEC2FDABC8;
        [[[provider hashForEventName:@"SAMPLE"] should] equal:[NSNumber numberWithUnsignedLongLong:value]];
    });

    it(@"Should return valid hash for empty string", ^{
        unsigned long long value = 0x0907d8af90186095;
        [[[provider hashForEventName:@""] should] equal:[NSNumber numberWithUnsignedLongLong:value]];
    });

});

SPEC_END
