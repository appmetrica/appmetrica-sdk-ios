#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@interface AMATestExpectationsBag () {
    NSMutableArray<XCTestExpectation *> *_expectations;
}

@property (nonnull, assign, nonatomic) XCTestCase *testCase;

@end

@implementation AMATestExpectationsBag

- (instancetype)initWithTestCase:(XCTestCase*)testCase;
{
    self = [super init];
    if (self) {
        _expectations = [NSMutableArray array];
        self.testCase = testCase;
        _defaultTimeout = 60;
    }
    return self;
}

+ (instancetype)expectationBagWithTestCase:(XCTestCase *)testCase
{
    return [[self alloc] initWithTestCase:testCase];
}

- (NSArray<XCTestExpectation *> *)expectations
{
    return [_expectations copy];
}

- (XCTestExpectation*)expectationWithDescription:(NSString*)description
{
    XCTestExpectation *expectation = [self.testCase expectationWithDescription:description];
    [_expectations addObject:expectation];
    return expectation;
}
- (XCTestExpectation*)expectationWithDescription:(NSString*)description inverted:(BOOL)inverted
{
    XCTestExpectation *expectation = [self.testCase expectationWithDescription:description];
    expectation.inverted = inverted;
    [_expectations addObject:expectation];
    return expectation;
}
- (XCTestExpectation*)expectationWithDescription:(NSString*)description inverted:(BOOL)inverted count:(NSUInteger)count
{
    XCTestExpectation *expectation = [self.testCase expectationWithDescription:description];
    expectation.inverted = inverted;
    expectation.expectedFulfillmentCount = count;
    [_expectations addObject:expectation];
    return expectation;
}

- (void)waitForExpectations
{
    [self.testCase waitForExpectations:_expectations timeout:self.defaultTimeout];
    [_expectations removeAllObjects];
}

- (void)waitForExpectationsWithTimeout:(NSTimeInterval)timeInterval
{
    [self.testCase waitForExpectations:_expectations timeout:timeInterval];
    [_expectations removeAllObjects];
}

- (void)clear
{
    [_expectations removeAllObjects];
}

@end
