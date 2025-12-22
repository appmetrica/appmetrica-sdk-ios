
#import <XCTest/XCTest.h>
#import "AMATelegramLoginNormalizer.h"

@interface AMATelegramLoginNormalizerTests : XCTestCase

@property (nonatomic, strong) AMATelegramLoginNormalizer *normalizer;

@end

@implementation AMATelegramLoginNormalizerTests

- (void)setUp
{
    [super setUp];
    self.normalizer = [[AMATelegramLoginNormalizer alloc] init];
}

- (void)testNormalize
{
    NSString *login = @"login";
    NSString *normalized = [self.normalizer normalizeValue:login];

    XCTAssertEqualObjects(normalized, login);
}

@end
