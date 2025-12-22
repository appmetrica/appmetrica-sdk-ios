
#import "AMAPhoneNormalizer.h"

// see https://nda.ya.ru/t/0rX8ReVs7MpdUK

static const NSUInteger kAMAPhoneMinValidDigitCount = 10;
static const NSUInteger kAMAPhoneMaxValidDigitCount = 13;
static NSString *const kAMAAllowedCharactersRegexString = @"^[0-9()\\-+\\s]+$";

@interface AMAPhoneNormalizer ()

@property (nonatomic, copy, readonly) NSRegularExpression *allowedCharactersRegex;

@end

@implementation AMAPhoneNormalizer

- (instancetype)init
{
    self = [super init];
    if (self) {
        _allowedCharactersRegex = [NSRegularExpression regularExpressionWithPattern:kAMAAllowedCharactersRegexString
                                                                            options:NSRegularExpressionCaseInsensitive
                                                                              error:nil];
    }
    return self;
}

- (NSString *)normalizeValue:(NSString *)value
{
    if (value.length == 0) return nil;
    if ([self containsOnlyAllowedCharacters:value] == NO) return nil;
    
    NSString *digitsOnly = [self extractDigits:value];
    
    if ([self isValidPhoneDigits:digitsOnly] == NO) {
        return nil;
    }
    
    unichar firstChar = [value characterAtIndex:0];
    unichar firstDigit = [digitsOnly characterAtIndex:0];
    
    if (firstDigit == '0') {
        return nil;
    }
    
    if (digitsOnly.length == 10 && firstChar != '+') {
        digitsOnly = [@"7" stringByAppendingString:digitsOnly];
    }
    else if (digitsOnly.length == 11) {
        if (firstChar == '+' && firstDigit == '8') {
            return nil;
        }
        if (firstDigit == '8') {
            digitsOnly = [@"7" stringByAppendingString:[digitsOnly substringFromIndex:1]];
        }
    }
    else if (digitsOnly.length >= 12 && firstChar == '+' && firstDigit == '7') {
        return nil;
    }
    
    return digitsOnly;
}

#pragma mark - Helpers

- (NSString *)extractDigits:(NSString *)string
{
    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSArray<NSString *> *components = [string componentsSeparatedByCharactersInSet:nonDigits];
    return [components componentsJoinedByString:@""];
}

- (BOOL)isValidPhoneDigits:(NSString *)digits
{
    return digits.length >= kAMAPhoneMinValidDigitCount && digits.length <= kAMAPhoneMaxValidDigitCount;
}

- (BOOL)containsOnlyAllowedCharacters:(NSString *)phone
{
    return [self.allowedCharactersRegex firstMatchInString:phone options:0 range:NSMakeRange(0, phone.length)] != nil;
}

@end
