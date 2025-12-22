
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import <CommonCrypto/CommonDigest.h>

static const NSUInteger kSHA256DigestLength = CC_SHA256_DIGEST_LENGTH;

@implementation AMAHashUtility

+ (NSString *)sha256HashForData:(NSData *)jsonData
{
    unsigned char hash[kSHA256DigestLength];
    CC_SHA256(jsonData.bytes, (CC_LONG)jsonData.length, hash);

    return [self hexStringFromBytes:hash length:kSHA256DigestLength];
}

+ (NSString *)sha256HashForString:(NSString *)string
{
    const char *cString = [string UTF8String];
    if (cString == NULL) return nil;
    
    unsigned char hash[kSHA256DigestLength];
    CC_SHA256(cString, (CC_LONG)strlen(cString), hash);

    return [self hexStringFromBytes:hash length:kSHA256DigestLength];
}

+ (NSData *)sha256DataForString:(NSString *)string
{
    const char *cString = [string UTF8String];
    if (cString == nil) return nil;

    unsigned char sha256Buffer[kSHA256DigestLength];
    CC_SHA256(cString, (CC_LONG)strlen(cString), sha256Buffer);

    return [NSData dataWithBytes:sha256Buffer length:kSHA256DigestLength];
}

#pragma mark - Helpers

+ (NSString *)hexStringFromBytes:(const unsigned char *)bytes length:(NSUInteger)length
{
    NSMutableString *hexString = [NSMutableString stringWithCapacity:length * 2];
    for (NSUInteger i = 0; i < length; i++) {
        [hexString appendFormat:@"%02x", bytes[i]];
    }
    return [hexString copy];
}

@end
