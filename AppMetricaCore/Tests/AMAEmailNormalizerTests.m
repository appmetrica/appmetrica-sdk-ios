
#import <XCTest/XCTest.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAEmailNormalizer.h"

@interface AMAEmailNormalizerTests : XCTestCase

@property (nonatomic, strong) AMAEmailNormalizer *normalizer;
@property (nonatomic, strong) NSArray<NSDictionary *> *testCases;

@end

@implementation AMAEmailNormalizerTests

- (void)setUp
{
    [super setUp];
    self.normalizer = [[AMAEmailNormalizer alloc] init];
    
    NSString *jsonPath = [AMAModuleBundleProvider.moduleBundle pathForResource:@"email_normalizer_test" ofType:@"json"];

    XCTAssertNotNil(jsonPath, @"Failed to find email_normalizer_test.json");

    NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
    XCTAssertNotNil(jsonData, @"Failed to load JSON data");

    NSError *error = nil;
    self.testCases = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];

    XCTAssertNil(error, @"JSON parsing error: %@", error);
    XCTAssertNotNil(self.testCases, @"Test cases should not be nil");
}

- (void)testNormalizeEmail_withValidEmail_returnsNormalizedEmail
{
    NSString *normalized = [self.normalizer normalizeValue:@"Test@Example.Com"];

    XCTAssertEqualObjects(normalized, @"test@example.com");
}

- (void)testNormalizeEmail_withNilInput_returnsNil
{
    NSString *normalized = [self.normalizer normalizeValue:nil];

    XCTAssertNil(normalized);
}

- (void)testNormalizeEmail_withEmptyString_returnsNil
{
    NSString *normalized = [self.normalizer normalizeValue:@""];

    XCTAssertNil(normalized);
}

- (void)testNormalizeEmail_withInvalidEmail_returnsNil
{
    NSString *normalized = [self.normalizer normalizeValue:@"not-an-email"];

    XCTAssertNil(normalized);
}

- (void)testNormalizeEmail_removesDotsForGmail
{
    NSString *normalized = [self.normalizer normalizeValue:@"test.user@gmail.com"];

    XCTAssertEqualObjects(normalized, @"testuser@gmail.com");
}

- (void)testNormalizeEmail_removesPlusAddressingForGmail
{
    NSString *normalized = [self.normalizer normalizeValue:@"test+tag@gmail.com"];

    XCTAssertEqualObjects(normalized, @"test@gmail.com");
}

- (void)testNormalizeEmail_removesDotsAndPlusForGmail
{
    NSString *normalized = [self.normalizer normalizeValue:@"test.user+tag@gmail.com"];

    XCTAssertEqualObjects(normalized, @"testuser@gmail.com");
}

- (void)testNormalizeEmail_removesPlusAddressingForYandex
{
    NSString *normalized = [self.normalizer normalizeValue:@"test+tag@yandex.ru"];

    XCTAssertEqualObjects(normalized, @"test@yandex.ru");
}

- (void)testNormalizeEmail_ReplaceDotAndTLDForYandex
{
    NSString *normalized = [self.normalizer normalizeValue:@"test.user@yandex.com"];

    XCTAssertEqualObjects(normalized, @"test-user@yandex.ru");
}

- (void)testNormalizeEmail_removesPlusAddressingForOtherDomains
{
    NSString *normalized = [self.normalizer normalizeValue:@"test+tag@example.com"];

    XCTAssertEqualObjects(normalized, @"test@example.com");
}

- (void)testNormalizeEmail_keepsDotsForOtherDomains
{
    NSString *normalized = [self.normalizer normalizeValue:@"test.user@example.com"];

    XCTAssertEqualObjects(normalized, @"test.user@example.com");
}

- (void)testIsValidEmail_withValidEmail_returnsYES
{
    BOOL isValid = [self.normalizer normalizeValue:@"test@example.com"];

    XCTAssertTrue(isValid);
}

- (void)testIsValidEmail_withInvalidEmail_returnsNO
{
    BOOL isValid = [self.normalizer normalizeValue:@"not-an-email"];

    XCTAssertFalse(isValid);
}

- (void)testIsValidEmail_withNilInput_returnsNO
{
    BOOL isValid = [self.normalizer normalizeValue:nil];

    XCTAssertFalse(isValid);
}

#pragma mark - Data driven tests
- (void)testEmailNormalization
{
    NSInteger totalTests = 0;
    NSInteger passedTests = 0;
    NSInteger failedTests = 0;
    NSInteger skippedTests = 0;
    NSMutableArray<NSString *> *failures = [NSMutableArray array];

    for (NSDictionary *testCase in self.testCases) {
        NSNumber *skip = testCase[@"skip"];
        if (skip != nil && [skip boolValue]) {
            skippedTests += 1;
            continue;
        }

        totalTests += 1;

        NSString *description = testCase[@"description"];
        NSString *initial = testCase[@"initial"];
        NSString *expectedNormalized = testCase[@"normalized"];
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
