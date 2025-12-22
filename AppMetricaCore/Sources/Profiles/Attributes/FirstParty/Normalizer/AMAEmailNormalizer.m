
#import <Foundation/Foundation.h>
#import "AMAEmailNormalizer.h"

// see https://nda.ya.ru/t/iN7J7tXE7Mpbnu and https://nda.ya.ru/t/omArXm6n7NDTjp

static NSInteger const kAMAMinEmailLength = 5;
static NSInteger const kAMAMaxEmailLength = 100;
static NSInteger const kAMAMaxDomainSize = 255;
static NSInteger const kAMAMinDomainLevel = 2;
static NSInteger const kAMAMaxDomainLabelSize = 63;
static NSInteger const kAMAMinDomainLabelSize = 1;
static NSInteger const kAMAMinDomainTLDLabelSize = 2;
static NSInteger const kAMAMinLocalPartSize = 1;
static NSInteger const kAMAMaxLocalPartSize = 64;
static NSString *const kAMAEmailLocalPartRegexString = @"^[a-zA-Z0-9'!#$%&*+-/=?^_`{|}~]+$";
static NSString *const kAMAYndxDomainRegexString = @"(?:^|\\.)(?:(ya\\.ru)|(?:yandex)\\.(\\w+|com?\\.\\w+))$";
static NSString *const kAMAYndxRuDomain = @"yandex.ru";
static NSString *const kAMAGmailDomain = @"gmail.com";
static NSString *const kAMAGoogleEmailDomain = @"googlemail.com";

@interface AMAEmailNormalizer ()

@property (nonatomic, copy, readonly) NSArray *yndxWhiteListTLD;
@property (nonatomic, strong, readonly) NSRegularExpression *emailLocalPartRegex;
@property (nonatomic, strong, readonly) NSRegularExpression *yndxDomainRegex;

@end

@implementation AMAEmailNormalizer

- (instancetype)init
{
    self = [super init];
    if (self) {
        _emailLocalPartRegex = [NSRegularExpression regularExpressionWithPattern:kAMAEmailLocalPartRegexString
                                                                         options:NSRegularExpressionCaseInsensitive
                                                                           error:nil];
        
        _yndxDomainRegex = [NSRegularExpression regularExpressionWithPattern:kAMAYndxDomainRegexString
                                                                     options:NSRegularExpressionCaseInsensitive
                                                                       error:nil];
        
        _yndxWhiteListTLD = @[
            @"ru", @"by", @"kz", @"az", @"kg", @"lv", @"md", @"tj", @"tm", @"uz",
            @"ee", @"fr", @"lt", @"com", @"co.il", @"com.ge", @"com.am", @"com.tr", @"com.ru"
        ];
    }
    return self;
}

- (NSString *)normalizeValue:(NSString *)value
{
    if (value == nil) return nil;
    
    NSString *email = [[self trim:value] lowercaseString];
    email = [email stringByReplacingOccurrencesOfString:@"^\\++"
                                             withString:@""
                                                options:NSRegularExpressionSearch
                                                  range:NSMakeRange(0, email.length)];
    
    NSRange atRange = [email rangeOfString:@"@" options:NSBackwardsSearch];
    if (atRange.location == NSNotFound) {
        return nil;
    }
    
    NSString *local = [email substringToIndex:atRange.location];
    NSString *domain = [email substringFromIndex:atRange.location + 1];
    
    if ([self validateEmail:local domain:domain] == NO) {
        return nil;
    }
    
    if ([domain isEqualToString:kAMAGoogleEmailDomain]) {
        domain = kAMAGmailDomain;
    }
    if ([self isYandexSearchDomain:domain]) {
        domain = kAMAYndxRuDomain;
    }
    
    if ([domain isEqualToString:kAMAYndxRuDomain]) {
        local = [local stringByReplacingOccurrencesOfString:@"." withString:@"-"];
    } else if ([domain isEqualToString:kAMAGmailDomain]) {
        local = [local stringByReplacingOccurrencesOfString:@"." withString:@""];
    }
    
    NSRange plusRange = [local rangeOfString:@"+"];
    if (plusRange.location != NSNotFound) {
        local = [local substringToIndex:plusRange.location];
    }
    
    NSString *normalizedEmail = [NSString stringWithFormat:@"%@@%@", local, domain];
    return [self checkEmailLength:normalizedEmail];
}

#pragma mark - Helpers

- (BOOL)isDigitString:(NSString *)string
{
    return [string rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound;
}

- (BOOL)isLetterOrDigit:(unichar)c
{
    return [[NSCharacterSet alphanumericCharacterSet] characterIsMember:c];
}

- (NSString *)trim:(NSString *)string
{
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (nullable NSString *)checkEmailLength:(NSString *)email
{
    NSInteger len = email.length;
    if (len < kAMAMinEmailLength || len > kAMAMaxEmailLength) {
        return nil;
    }
    return email;
}

- (BOOL)validateEmail:(NSString *)local domain:(NSString *)domain
{
    return [self validateLocalPart:local] && [self validateDomain:domain];
}

- (BOOL)validateLocalPart:(NSString *)local
{
    NSInteger localLen = local.length;
    if (localLen < kAMAMinLocalPartSize || localLen > kAMAMaxLocalPartSize) {
        return NO;
    }
    
    NSArray<NSString *> *parts = [local componentsSeparatedByString:@"."];
    for (NSString *part in parts) {
        NSInteger partLen = part.length;
        if (partLen < kAMAMinLocalPartSize) {
            return NO;
        }
        
        if ([part hasPrefix:@"\""] && [part hasSuffix:@"\""] && partLen > 2) {
            if ([self validateLocalQuoted:part] == NO) {
                return NO;
            }
        } else {
            if ([self.emailLocalPartRegex firstMatchInString:part
                                                     options:0
                                                       range:NSMakeRange(0, part.length)] == nil) {
                return NO;
            }
        }
    }
    return YES;
}

- (BOOL)validateLocalQuoted:(NSString *)part
{
    NSInteger pos = 1;
    while (pos + 2 < part.length) {
        unichar c = [part characterAtIndex:pos];
        int charCode = (int)c;
        
        if (charCode < 32 || charCode == 34 || charCode > 126) {
            return NO;
        }
        
        if (charCode == 92) {
            if (pos + 2 == part.length) {
                return NO;
            }
            unichar next = [part characterAtIndex:pos + 1];
            if ((int)next < 32) {
                return NO;
            }
            pos += 1;
        }
        pos += 1;
    }
    
    return YES;
}

- (BOOL)isYandexSearchDomain:(NSString *)host
{
    NSTextCheckingResult *match = [self.yndxDomainRegex firstMatchInString:host
                                                                   options:0
                                                                     range:NSMakeRange(0, host.length)];
    if (match == nil) return NO;
    
    NSInteger numRanges = match.numberOfRanges;
    if (numRanges < 3) return NO;

    NSRange range1 = [match rangeAtIndex:1];
    NSRange range2 = [match rangeAtIndex:2];

    NSString *matchedYaRu = (range1.location != NSNotFound) ? [host substringWithRange:range1] : @"";
    NSString *matchedYndxTld = (range2.location != NSNotFound) ? [host substringWithRange:range2] : @"";


    
    if (matchedYndxTld.length > 0) {
        return [self.yndxWhiteListTLD containsObject:matchedYndxTld];
    }
    
    return matchedYaRu.length > 0;
}

- (BOOL)verifyLabel:(NSString *)label
{
    NSInteger len = label.length;
    if (len > kAMAMaxDomainLabelSize || len < kAMAMinDomainLabelSize) {
        return NO;
    }
    
    unichar first = [label characterAtIndex:0];
    unichar last = [label characterAtIndex:len - 1];
    if ([self isLetterOrDigit:first] == NO || [self isLetterOrDigit:last] == NO) {
        return NO;
    }
    
    for (NSInteger i = 0; i < len; i++) {
        unichar c = [label characterAtIndex:i];
        if ([self isLetterOrDigit:c] == NO && c != '-') {
            return NO;
        }
    }
    return YES;
}

- (BOOL)verifyTld:(NSString *)tld
{
    return (tld.length >= kAMAMinDomainTLDLabelSize) && [self verifyLabel:tld] && [self isDigitString:tld] == NO;
}

- (BOOL)validateDomain:(NSString *)domain
{
    if (domain.length > kAMAMaxDomainSize) {
        return NO;
    }
    
    NSArray<NSString *> *labels = [domain componentsSeparatedByString:@"."];
    if (labels.count < kAMAMinDomainLevel) {
        return NO;
    }
    
    for (NSInteger i = 0; i < labels.count - 1; i++) {
        NSString *label = labels[i];
        if ([self verifyLabel:label] == NO) {
            return NO;
        }
    }
    
    NSString *tld = labels.lastObject;
    return [self verifyTld:tld];
}

@end
