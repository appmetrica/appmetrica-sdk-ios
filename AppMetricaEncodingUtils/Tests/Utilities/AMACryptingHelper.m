
#import "AMACryptingHelper.h"
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>

@implementation AMACryptingHelper

+ (AMARSAKey *)publicKey
{
    NSString *pem =
        @"-----BEGIN PUBLIC KEY-----"
        "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDbUydpDbmdohsX2eLiuIAitvTE"
        "HbGGZU7ZDyejL0ZR85TiJuGf+R3IdoNVs47xVzb7q+/wmfQ3cAhRjNW1Q1KFOPvp"
        "wxBtSWvSIiZJcQAsAfOa+bBliZ8vzuWkAmL+Qdf+vMkiw9XaiYY9Kcbrflgm5P3Z"
        "hJioO8muDYKkU6whjQIDAQAB"
        "-----END PUBLIC KEY-----";
    return [[AMARSAKey alloc] initWithData:[AMARSAUtility publicKeyFromPem:pem]
                                   keyType:AMARSAKeyTypePublic
                                 uniqueTag:@"AMACryptingHelperPublicKey"];
}

+ (AMARSAKey *)privateKey
{
    NSString *pem =
        @"-----BEGIN PRIVATE KEY-----"
        "MIICdgIBADANBgkqhkiG9w0BAQEFAASCAmAwggJcAgEAAoGBANtTJ2kNuZ2iGxfZ"
        "4uK4gCK29MQdsYZlTtkPJ6MvRlHzlOIm4Z/5Hch2g1WzjvFXNvur7/CZ9DdwCFGM"
        "1bVDUoU4++nDEG1Ja9IiJklxACwB85r5sGWJny/O5aQCYv5B1/68ySLD1dqJhj0p"
        "xut+WCbk/dmEmKg7ya4NgqRTrCGNAgMBAAECgYEAmECucCAmBYa+Fh2cglUgJnkp"
        "i2ctkKWNSeNaWc78mvFkHmZtZHc0NLAI1hqTFXi845LlOvo07bMpIyuIQ4/bnPTz"
        "oQKEF0RP2ycjPFX8AvgXyzI1PjVxNhAvY7EL3EcSR1YfQsBegsQn3YMJ/zDtWIa+"
        "k3WM43QoeSASm5OqceUCQQDySb+aOlxN2VAsInBsvFp+Qj84HHavW919uLRya875"
        "BRMx0xoppv9/NjTFcUOkNLVReIU9p1LpmR5x2U3PaCxrAkEA57y3K86CsNEn7d1t"
        "+SCMdwtvBeGmk127V7kJjn5ql+Wa444AovQ7nNMe/Y9y/4m9ZNJjxHwMxC/1ELXF"
        "G6dn5wJABEJHm+5qsPOg9SWl1EN7U7zWX6Ygb/StcAhPI7PBb58nNzj+vLyywQmy"
        "48WZ6skCZuw3a14FlxWZ82Zed8bdAQJAcesifIV7V6KqJ1OYEUT/6DGVtWV1NrJ4"
        "Oyp6WTMqAVvc5YpUI8c+WtyqOmm/VYGHuj120AtPV05gAYPpzqtf9wJAHCLKQJGm"
        "KC3/sCx7N0qfPhjVVCA24tArcQGtyuPJ5w3lfN5lfireVa2hVlwEbdcLLNAH2VPN"
        "ZnTaU+7kk1/OlA=="
        "-----END PRIVATE KEY-----";
    return [[AMARSAKey alloc] initWithData:[AMARSAUtility privateKeyFromPem:pem]
                                   keyType:AMARSAKeyTypePrivate
                                 uniqueTag:@"AMACryptingHelperPrivateKey"];
}

@end
