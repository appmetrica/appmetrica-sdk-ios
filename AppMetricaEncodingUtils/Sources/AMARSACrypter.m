
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import "AMAEncodingUtilsLog.h"

NSString *const kAMARSACrypterErrorDomain = @"io.appmetrica.AMARSACrypter";

@implementation AMARSACrypter

+ (void)setError:(NSError **)pError withErrorStatus:(OSStatus)status
{
    if (pError != NULL) {
        *pError = [NSError errorWithDomain:kAMARSACrypterErrorDomain
                                      code:status
                                  userInfo:nil];
    }
}

+ (NSString *)message
{
    return @"-----BEGIN RSA PUBLIC KEY-----"
    "MIGJAoGBAOGYf+baqtGPEMc/v3gJ5pmkQ1A1jJ1/ymrJcmKWjpfEr6f6m+jbtXFZ"
    "8HdnXIeu0qjD55lcotDOtDzBkx9GAAOtgJAnbTLaEZkRQI3W0ZIz7GpUox4K1WLc"
    "29BrngLHuZPkQJWwfkMoSz9p5JwMc/noXNyARu05LDJFnx2wQzTDAgMBAAE="
    "-----END RSA PUBLIC KEY-----";
}

- (instancetype)initWithPublicKey:(AMARSAKey *)publicKey privateKey:(AMARSAKey *)privateKey
{
    self = [super init];
    if (self != nil) {
        _publicKey = publicKey;
        _privateKey = privateKey;
    }
    return self;
}

- (SecKeyRef)keyForKey:(AMARSAKey *)key error:(NSError **)error
{
    OSStatus status = noErr;
    SecKeyRef keyRef = [[AMARSAKeyProvider sharedInstanceForKey:key] keyWithStatus:&status];
    if (status != noErr) {
        [[self class] setError:error withErrorStatus:status];
    }
    return keyRef;
}

- (NSData *)processData:(NSData *)data
             withKeyRef:(SecKeyRef)keyRef
              encrypting:(BOOL)encrypting
                  error:(NSError **)error
{
    const uint8_t *sourceDataBytes = (const uint8_t *)[data bytes];
    size_t sourceSize = (size_t)data.length;

    size_t blockSize = SecKeyGetBlockSize(keyRef);
    size_t sourceBlockSize = encrypting ? blockSize - 11 : blockSize;

    NSMutableData *result = [[NSMutableData alloc] initWithCapacity:blockSize];
    NSUInteger position = 0;
    while (position != sourceSize) {
        size_t currentBlockSize = MIN(sourceBlockSize, sourceSize - position);
        NSData *block = [NSData dataWithBytes:sourceDataBytes + position length:currentBlockSize];
        CFErrorRef processingError = NULL;
        CFDataRef processedBlock = encrypting
            ? SecKeyCreateEncryptedData(keyRef, kSecKeyAlgorithmRSAEncryptionPKCS1,
                                        (__bridge CFDataRef)block, &processingError)
            : SecKeyCreateDecryptedData(keyRef, kSecKeyAlgorithmRSAEncryptionPKCS1,
                                        (__bridge CFDataRef)block, &processingError);
        if (processedBlock != NULL) {
            [result appendData:CFBridgingRelease(processedBlock)];
        }
        else {
            OSStatus status = processingError != NULL ? (OSStatus)CFErrorGetCode(processingError) : errSecInternalError;
            [[self class] setError:error withErrorStatus:status];
            result = nil;
        }
        if (processingError != NULL) {
            CFRelease(processingError);
        }
        if (result == nil) {
            break;
        }
        position += currentBlockSize;
    }
    
    return [result copy];
}

- (NSData *)encodeData:(NSData *)data error:(NSError **)error
{
    NSError *currentError = nil;
    NSData *encryptedData = nil;

    SecKeyRef keyRef = [self keyForKey:self.publicKey error:&currentError];
    if (currentError == nil) {
        encryptedData = [self processData:data withKeyRef:keyRef encrypting:YES error:&currentError];
        CFRelease(keyRef);
    }

    if (currentError != nil) {
        [AMAErrorUtilities fillError:error withError:currentError];
    }

    AMALogInfo(@"RSA encryption finished(%lu -> %lu), error: %@",
        (unsigned long)data.length, (unsigned long)encryptedData.length, currentError);
    return encryptedData;
}

- (NSData *)decodeData:(NSData *)data error:(NSError **)error
{
    NSError *currentError = nil;
    NSData *decryptedData = nil;

    SecKeyRef keyRef = [self keyForKey:self.privateKey error:&currentError];
    if (currentError == nil) {
        decryptedData = [self processData:data withKeyRef:keyRef encrypting:NO error:&currentError];
        CFRelease(keyRef);
    }

    if (currentError != nil) {
        [AMAErrorUtilities fillError:error withError:currentError];
    }

    AMALogInfo(@"RSA decryption finished(%lu -> %lu), error: %@",
        (unsigned long)data.length, (unsigned long)decryptedData.length, currentError);
    return decryptedData;
}

@end
