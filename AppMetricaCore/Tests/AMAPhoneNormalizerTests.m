
#import <XCTest/XCTest.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAPhoneNormalizer.h"

@interface AMAPhoneNormalizerTests : XCTestCase

@property (nonatomic, strong) AMAPhoneNormalizer *normalizer;
@property (nonatomic, strong) NSArray<NSDictionary *> *testCases;

@end

@implementation AMAPhoneNormalizerTests

- (void)setUp
{
    [super setUp];
    self.normalizer = [[AMAPhoneNormalizer alloc] init];
    
    NSString *jsonPath = [AMAModuleBundleProvider.moduleBundle pathForResource:@"phone_normalizer_test" ofType:@"json"];

    XCTAssertNotNil(jsonPath, @"Failed to find phone_normalizer_test.json");

    NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
    XCTAssertNotNil(jsonData, @"Failed to load JSON data");

    NSError *error = nil;
    self.testCases = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];

    XCTAssertNil(error, @"JSON parsing error: %@", error);
    XCTAssertNotNil(self.testCases, @"Test cases should not be nil");
}

- (void)testNormalizePhone_withValidPhone_returnsNormalizedPhone
{
    NSString *normalized = [self.normalizer normalizeValue:@"+1-234-567-8900"];

    XCTAssertEqualObjects(normalized, @"12345678900");
}

- (void)testNormalizePhone_withNilInput_returnsNil
{
    NSString *normalized = [self.normalizer normalizeValue:nil];

    XCTAssertNil(normalized);
}

- (void)testNormalizePhone_withEmptyString_returnsNil
{
    NSString *normalized = [self.normalizer normalizeValue:@""];

    XCTAssertNil(normalized);
}

- (void)testNormalizePhone_withTooFewDigits_returnsNil
{
    NSString *normalized = [self.normalizer normalizeValue:@"123456789"];

    XCTAssertNil(normalized);
}

- (void)testNormalizePhone_withTooManyDigits_returnsNil
{
    NSString *normalized = [self.normalizer normalizeValue:@"12345678901234"];

    XCTAssertNil(normalized);
}

- (void)testNormalizePhone_extractsDigitsOnly
{
    NSString *normalized = [self.normalizer normalizeValue:@"+1 (234) 567-8900"];

    XCTAssertEqualObjects(normalized, @"12345678900");
}

- (void)testNormalizePhone_prependsCountryCodeForRussianMobile
{
    NSString *normalized = [self.normalizer normalizeValue:@"9123456789"];

    XCTAssertEqualObjects(normalized, @"79123456789");
}

- (void)testNormalizePhone_replacesEightWithSevenForRussian
{
    NSString *normalized = [self.normalizer normalizeValue:@"89123456789"];

    XCTAssertEqualObjects(normalized, @"79123456789");
}

- (void)testNormalizePhone_with10DigitsReplace7
{
    NSString *normalized = [self.normalizer normalizeValue:@"1234567890"];

    XCTAssertEqualObjects(normalized, @"71234567890");
}

- (void)testNormalizePhone_with11Digits_isValid
{
    NSString *normalized = [self.normalizer normalizeValue:@"12345678901"];

    XCTAssertEqualObjects(normalized, @"12345678901");
}

- (void)testNormalizePhone_with13Digits_isValid
{
    NSString *normalized = [self.normalizer normalizeValue:@"1234567890123"];

    XCTAssertEqualObjects(normalized, @"1234567890123");
}

#pragma mark - Data driven tests
- (void)testPhoneNormalization
{
    NSInteger totalTests = 0;
    NSInteger passedTests = 0;
    NSInteger failedTests = 0;
    NSInteger skippedTests = 0;
    NSMutableArray<NSString *> *failures = [NSMutableArray array];

    for (NSDictionary *testCase in self.testCases) {
        NSNumber *skip = testCase[@"skip"];
        if (skip != nil && [skip boolValue]) {
            skippedTests++;
            continue;
        }

        totalTests++;

        NSString *description = testCase[@"description"];
        NSString *initial = testCase[@"initial"];
        NSString *expectedNormalized = [testCase[@"normalized"] stringByReplacingOccurrencesOfString:@"+" withString:@""];
        BOOL expectedValid = [testCase[@"isValid"] boolValue];

        NSString *actualNormalized = [self.normalizer normalizeValue:initial];
        BOOL actualValid = actualNormalized != nil;

        BOOL normalizationMatches = NO;
        if (expectedValid) {
            normalizationMatches = [actualNormalized isEqualToString:expectedNormalized];
        } else {
            normalizationMatches = (actualNormalized == nil);
        }

        BOOL validityMatches = (actualValid == expectedValid);

        if (normalizationMatches && validityMatches) {
            passedTests++;
        } else {
            failedTests++;
            NSString *failureMessage = [NSString stringWithFormat:
                @"\n[%@]\n  Input: '%@'\n  Expected normalized: '%@' (valid: %@)\n  Actual normalized: '%@' (valid: %@)",
                description,
                initial,
                expectedNormalized,
                expectedValid ? @"YES" : @"NO",
                actualNormalized ?: @"nil",
                actualValid ? @"YES" : @"NO"
            ];
            [failures addObject:failureMessage];
        }
    }
    
    if (failures.count > 0) {
        NSLog(@"Failed test cases:");
        for (NSString *failure in failures) {
            XCTFail(@"%@", failure);
        }
        XCTFail(@"%ld out of %ld tests failed", (long)failedTests, (long)totalTests);
    }
}

@end
