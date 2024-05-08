
#import <XCTest/XCTest.h>
#import "AMAFileLogMiddleware.h"

#ifdef AMA_ENABLE_FILE_LOG
static const NSUInteger maxBufferLength = 1024;

@interface AMAFileLogMiddlewareTests : XCTestCase {
    char *_buffer;
    int _out_pipe[2];

    FILE *_stream;
}

@property (nonatomic, strong) AMAFileLogMiddleware *middleware;
@property (nonatomic, strong) NSFileHandle *handle;

@end

@implementation AMAFileLogMiddlewareTests

- (void)setUp
{
    [super setUp];

    if( pipe(_out_pipe) != 0 ) {
        @throw [NSException exceptionWithName:@"Open pipe error"
                                       reason:@"Failed to create output pipe"
                                     userInfo:nil];
    }

    // non-blocking descriptor
    int flags = fcntl(_out_pipe[0], F_GETFL, 0);
    fcntl(_out_pipe[0], F_SETFL, flags | O_NONBLOCK);

    _stream = fdopen(_out_pipe[1], "wr");

    _buffer = calloc(maxBufferLength, sizeof(char));

    NSFileHandle *handle = [[NSFileHandle alloc] initWithFileDescriptor:_out_pipe[1] closeOnDealloc:NO];
    self.handle = [NSFileHandle fileHandleWithStandardOutput];

    self.middleware = [[AMAFileLogMiddleware alloc] initWithFileHandle:handle];
}

- (void)tearDown
{
    self.handle = nil;
    close(_out_pipe[0]);
    close(_out_pipe[1]);
    free(_buffer);

    [super tearDown];
}

- (NSString *)bufferString
{
    fflush(_stream);
    [self.handle synchronizeFile];
    read(_out_pipe[0], _buffer, maxBufferLength);
    NSString *str = [NSString stringWithCString:_buffer encoding:NSUTF8StringEncoding];
    return str;
}

- (void)testAppendNewLine
{
    [self.middleware logMessage:@"" level:AMALogLevelNotify];

    NSString *loggedString = self.bufferString;
    XCTAssertEqualObjects(loggedString, @"\n");
}

- (void)testLogAsciiMessages
{
    [self.middleware logMessage:@"Hello log" level:AMALogLevelNotify];

    NSString *log = self.bufferString;
    XCTAssertEqualObjects(log, @ "Hello log\n");
}

- (void)testLogCyrillicMessages
{
    [self.middleware logMessage:@"Привет йогурт" level:AMALogLevelNotify];

    NSString *log = self.bufferString;
    XCTAssertEqualObjects(log, @"Привет йогурт\n");
}

- (void)testLogNilStrings
{
    [self.middleware logMessage:nil level:AMALogLevelNotify];

    NSString *log = self.bufferString;
    XCTAssertEqualObjects(log, @"");
}

- (void)testConformance
{
    XCTAssertTrue([self.middleware conformsToProtocol:@protocol(AMALogMiddleware)],
                  @"Should conform to AMALogMiddleware");
}

@end

#endif //AMA_ENABLE_FILE_LOG
