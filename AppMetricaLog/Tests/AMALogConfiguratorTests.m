
#import <XCTest/XCTest.h>
#import "AMALogConfigurator+Private.h"
#import "AMALogOutput.h"
#import "AMALogMessageFormatterFactory.h"
#import "Mocks/AMALogFacadeMock.h"
#import "Mocks/AMALogOutputFactoryMock.h"
#import "Mocks/AMALogMessageFormatterFactorySpy.h"


static NSString *const kAMATestChannel = @"TestChannel";

@interface AMALogConfiguratorTests : XCTestCase

@property (nonatomic, strong) AMALogConfigurator *configurator;
@property (nonatomic, strong) AMALogFacadeMock *logMock;
@property (nonatomic, strong) AMALogOutputFactoryMock *outputFactory;
@property (nonatomic, strong) AMALogMessageFormatterFactorySpy *formatterFactory;

@end

@implementation AMALogConfiguratorTests

- (void)setUp
{
    [super setUp];

    self.logMock = [[AMALogFacadeMock alloc] init];
    self.outputFactory = [[AMALogOutputFactoryMock alloc] init];
    self.formatterFactory = [[AMALogMessageFormatterFactorySpy alloc] init];

    self.configurator = [[AMALogConfigurator alloc] initWithLog:self.logMock
                                               logOutputFactory:self.outputFactory
                                               formatterFactory:self.formatterFactory];
}


- (void)testOSLogAvailability
{
    [self.configurator setupLogWithChannel:kAMATestChannel];
    XCTAssertEqual(self.logMock.OSOutputs.count, 1);
}

- (void)testOSLogConfigurations
{
    [self.configurator setupLogWithChannel:kAMATestChannel];
    AMALogOutput *output = self.logMock.OSOutputs.firstObject;
    
    XCTAssertEqual(output.channel, kAMATestChannel);
    BOOL contains = [self.formatterFactory.calls containsObject:@[@(AMALogFormatPartOrigin),
                                                                  @(AMALogFormatPartContent),
                                                                  @(AMALogFormatPartBacktrace)]];
    XCTAssertTrue(contains);
}

#ifdef AMA_ENABLE_FILE_LOG
- (void)testFileLogAvailability
{
    [self.configurator setupLogWithChannel:kAMATestChannel];
    XCTAssertEqual(self.logMock.fileOutputs.count, 1);
}

- (void)testFileLogConfiguration
{
    [self.configurator setupLogWithChannel:kAMATestChannel];
    AMALogOutput *output = self.logMock.fileOutputs.firstObject;
    
    XCTAssertEqual(output.channel, kAMATestChannel);
    BOOL contains = [self.formatterFactory.calls containsObject:@[@(AMALogFormatPartDate),
                                                                  @(AMALogFormatPartOrigin),
                                                                  @(AMALogFormatPartContent),
                                                                  @(AMALogFormatPartBacktrace)]];
    XCTAssertTrue(contains);
}
#endif //AMA_ENABLE_FILE_LOG

/* We don't test TTY output as it is depends on execution condition
- (void)testTTYLogAvailability
{
    [self.configurator setupLogWithChannel:kAMATestChannel];
    XCTAssertEqual(self.logMock.TTYOutputs.count, 1);
}
 */

- (void)testChannelDeduplication
{
    [self.configurator setupLogWithChannel:kAMATestChannel];
    NSUInteger expected = self.logMock.outputs.count;

    [self.configurator setupLogWithChannel:kAMATestChannel];
    XCTAssertEqual(self.logMock.outputs.count, expected);
}

- (void)testSecondChannel
{
    [self.configurator setupLogWithChannel:kAMATestChannel];
    NSUInteger expected = self.logMock.outputs.count * 2;

    [self.configurator setupLogWithChannel:@"AnotherChannel"];
    XCTAssertEqual(self.logMock.outputs.count, expected);
}

- (void)testDefaultLogLevelMask
{
    [self.configurator setupLogWithChannel:kAMATestChannel];
    for (AMALogOutput *output in [self.logMock outputsWithChannel:kAMATestChannel]) {
        XCTAssertEqual(output.logLevel, AMALogLevelError | AMALogLevelNotify);
    }
}

- (void)testChannelEnabling
{
    [self.configurator setupLogWithChannel:kAMATestChannel];
    NSSet *expected = [NSSet setWithArray:self.logMock.outputs];
    
    [self.configurator setChannel:kAMATestChannel enabled:YES];
    
    XCTAssertFalse([expected intersectsSet:[NSSet setWithArray:self.logMock.outputs]]);
    for (AMALogOutput *output in [self.logMock outputsWithChannel:kAMATestChannel]) {
        XCTAssertEqual(output.logLevel, AMALogLevelInfo | AMALogLevelWarning | AMALogLevelError | AMALogLevelNotify);
    }
}

- (void)testChannelDisabling
{
    [self.configurator setupLogWithChannel:kAMATestChannel];
    [self.configurator setChannel:kAMATestChannel enabled:YES];
    NSSet *expected = [NSSet setWithArray:self.logMock.outputs];
    
    [self.configurator setChannel:kAMATestChannel enabled:NO];
    
    XCTAssertFalse([expected intersectsSet:[NSSet setWithArray:self.logMock.outputs]]);
    for (AMALogOutput *output in [self.logMock outputsWithChannel:kAMATestChannel]) {
        XCTAssertEqual(output.logLevel, AMALogLevelError | AMALogLevelNotify);
    }
}

- (void)testChannelIsolation
{
    [self.configurator setupLogWithChannel:kAMATestChannel];
    NSSet *expected = [NSSet setWithArray:self.logMock.outputs];
    [self.configurator setupLogWithChannel:@"AnotherChannel"];
    XCTAssertTrue([expected isSubsetOfSet:[NSSet setWithArray:self.logMock.outputs]]);
}

@end
