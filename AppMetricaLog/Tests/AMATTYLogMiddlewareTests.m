
#import <XCTest/XCTest.h>
#import "AMATTYLogMiddleware.h"

static const NSUInteger maxBufferLength = 1024;

@interface AMATTYLogMiddlewareTests : XCTestCase {
    int _out_pipe[2];
    char *_buffer;

    FILE *_stream;
    int _outputDescriptor;
}

@property (nonatomic, strong) AMATTYLogMiddleware *middleware;

@end

@implementation AMATTYLogMiddlewareTests

- (void)setUp {
    [super setUp];

    if( pipe(_out_pipe) != 0 ) {
        @throw [NSException exceptionWithName:@"Open pipe error"
                                       reason:@"Failed to create output pipe"
                                     userInfo:nil];
    }

    _outputDescriptor = _out_pipe[1];

    // non-blocking descriptor
    int flags = fcntl(_out_pipe[0], F_GETFL, 0);
    fcntl(_out_pipe[0], F_SETFL, flags | O_NONBLOCK);

    _stream = fdopen(_out_pipe[1], "wr");

    _buffer = calloc(maxBufferLength, sizeof(char));
    
    self.middleware = [[AMATTYLogMiddleware alloc] initWithOutputDescriptor:_outputDescriptor];
}

- (void)tearDown {
    close(_out_pipe[0]);
    close(_out_pipe[1]);
    free(_buffer);

    [super tearDown];
}

- (NSString *)bufferString {
    fflush(_stream);
    read(_out_pipe[0], _buffer, maxBufferLength);
    NSString *str = [NSString stringWithCString:_buffer encoding:NSUTF8StringEncoding];
    return str;
}

- (void)testAppendNewLine {
    [self.middleware logMessage:@"" level:AMALogLevelNotify];

    NSString *loggedString = self.bufferString;
    XCTAssertEqualObjects(loggedString, @"\n");
}

- (void)testLogAsciiMessages {
    [self.middleware logMessage:@"Hello log" level:AMALogLevelNotify];

    NSString *log = self.bufferString;
    XCTAssertEqualObjects(log, @ "Hello log\n");
}

- (void)testLogCyrillicMessages {
    [self.middleware logMessage:@"Привет йогурт" level:AMALogLevelNotify];

    NSString *log = self.bufferString;
    XCTAssertEqualObjects(log, @"Привет йогурт\n");
}

- (void)testLogNilStrings {
    [self.middleware logMessage:nil level:AMALogLevelNotify];

    NSString *log = self.bufferString;
    XCTAssertEqualObjects(log, @"");
}

@end
