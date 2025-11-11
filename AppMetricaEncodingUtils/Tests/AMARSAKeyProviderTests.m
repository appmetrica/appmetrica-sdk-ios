
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>

@interface AMARSAKeyProvider ()

- (instancetype)initWithKey:(AMARSAKey *)key;

@end

SPEC_BEGIN(AMARSAKeyProviderTests)

describe(@"AMARSAKeyProvider", ^{

    NSString *const publicKeyString =
        @"MIGeMA0GCSqGSIb3DQEBAQUAA4GMADCBiAKBgHF87N36h0rN0SevA4ujbGgH9x1x"
         "EVk51ttazf91To0gX18FWgk+2WQOAGzAhHdUFtNfFzsUZO7vNC6EtCoq0xW48UiK"
         "tqNZrllIPa67VKtFu2BuGQCAmhkSDzJTtygaf3jsMivN/JPqrve5DIB3lbCUbZlz"
         "JvUd+KWUqfHNromZAgMBAAE=";
    NSString *const privateKeyString =
        @"MIICWwIBAAKBgHF87N36h0rN0SevA4ujbGgH9x1xEVk51ttazf91To0gX18FWgk+"
         "2WQOAGzAhHdUFtNfFzsUZO7vNC6EtCoq0xW48UiKtqNZrllIPa67VKtFu2BuGQCA"
         "mhkSDzJTtygaf3jsMivN/JPqrve5DIB3lbCUbZlzJvUd+KWUqfHNromZAgMBAAEC"
         "gYAcnL1vXbl8b5Wa5rIDI6myNMflwVr5Xu6/kQ48qMusIwxIfaXsjM7sPed3g7Yi"
         "C65RjjjiKUslPmOuksCFnRRooHs7Ri/fBVZSHk/zJcxs2nsS+qFq+FoIFCmDQrUz"
         "HrnZyYt3NHe5eJNkIdSyyXi6e82tS3FlTt9hXOh73SWOTQJBALY/B9k/FFw/8UdN"
         "jzJVhLaMcbj/BQZvaP6O4nqzIxoaucBusxoD8ANPwA2tf+roCGbU1kLof8Wp24XY"
         "owio5OMCQQCfanGhgaRCZz2+MNEwKctVsBhX2uoM7+oA6k/v8GRRrFWjYqf5kcOV"
         "Xd/Ba8pN0CF8AdKeQMVRirruhBNrZpxTAkAZExkIWfZ6Ls4KqnAuU7fbyf0HoAbX"
         "+NIwXAZrLWSB/fVataBszufh/MIG370+28f0JgqI0CZsUs+CXekoktxTAkEAhPZ9"
         "TF4bKR9/ShDhibByXkgAJdb7fErm/Fhy0AfLRKveyeXRgMFpRj4EEQnctMYyB4Jl"
         "r4UKjxaND7+titkM7QJAcLqZwvPKQ8HpQffPAAEuNVOXp1Ug4zCtAQU5mnlyHJME"
         "deehE402nC2Nn9WAPtli4XoCWu3xE/CwU/m4ArSRcQ==";
    NSString *const tag = @"UNIQUE_TAG";

    AMARSAKey *__block key = nil;
    AMARSAKeyProvider *__block provider = nil;

    context(@"Public key", ^{
        beforeEach(^{
            NSData *data = [[NSData alloc] initWithBase64EncodedString:publicKeyString options:0];
            key = [[AMARSAKey alloc] initWithData:data keyType:AMARSAKeyTypePublic uniqueTag:tag];
            provider = [[AMARSAKeyProvider alloc] initWithKey:key];
        });
        it(@"Should return noErr status", ^{
            OSStatus status = noErr;
            SecKeyRef keyRef = [provider keyWithStatus:&status];
            [[theValue(status) should] equal:theValue(noErr)];
            CFRelease(keyRef);
        });
        it(@"Should return non-nil key", ^{
            OSStatus status = noErr;
            SecKeyRef keyRef = [provider keyWithStatus:&status];
            [[thePointerValue(keyRef) shouldNot] beNil];
            CFRelease(keyRef);
        });
    });
    context(@"Private key", ^{
        beforeEach(^{
            NSData *data = [[NSData alloc] initWithBase64EncodedString:privateKeyString options:0];
            key = [[AMARSAKey alloc] initWithData:data keyType:AMARSAKeyTypePrivate uniqueTag:tag];
            provider = [[AMARSAKeyProvider alloc] initWithKey:key];
        });
        it(@"Should return noErr status", ^{
            OSStatus status = noErr;
            SecKeyRef keyRef = [provider keyWithStatus:&status];
            [[theValue(status) should] equal:theValue(noErr)];
            CFRelease(keyRef);
        });
        it(@"Should return non-nil key", ^{
            OSStatus status = noErr;
            SecKeyRef keyRef = [provider keyWithStatus:&status];
            [[thePointerValue(keyRef) shouldNot] beNil];
            CFRelease(keyRef);
        });
    });

});

SPEC_END
