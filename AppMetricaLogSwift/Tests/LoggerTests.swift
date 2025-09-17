
import XCTest
@testable import AppMetricaLogSwift

final class LoggerTests: XCTestCase {
    
    private var logger: Logger!
    private var mock: LogFacadeMock!
    
    private let message = "Test message"
    
    override func setUp() {
        super.setUp()
        
        self.mock = LogFacadeMock()
        self.logger = Logger(channel: "test", facade: mock)
    }
    
    func testLogMessage() {
        let file: StaticString = "test.log"
        let line: UInt = 42
        let function: StaticString = "test()"
        logger.message(message, level: .error, file: file, line: line, function: function)
        
        XCTAssertEqual(mock.logs.count, 1)
        
        let log = mock.logs.first!
        XCTAssertEqual(log.message, message)
        XCTAssertEqual(log.level, .error)
        XCTAssertEqual(log.file, String(describing: file))
        XCTAssertTrue(log.line == line)
        XCTAssertEqual(log.function, String(describing: function))
    }

    func testLogLevels() {
        enum TestError: Error {
            case testError
        }
        
        logger.info(message)
        logger.warning(message)
        logger.error(message)
        logger.notify(message)
        logger.error(TestError.testError)
        
        XCTAssertEqual(mock.logs.count, 5)
        XCTAssertEqual(mock.logs[0].level, .info)
        XCTAssertEqual(mock.logs[1].level, .warning)
        XCTAssertEqual(mock.logs[2].level, .error)
        XCTAssertEqual(mock.logs[3].level, .notify)
        XCTAssertEqual(mock.logs[4].level, .error)
    }
    
    func testLogFile() {
        logger.info(message)
        let file: StaticString = #fileID
        
        XCTAssertEqual(mock.logs.count, 1)
        XCTAssertEqual(mock.logs[0].file, String(describing: file))
    }
    
    func testLogLine() {
        logger.info(message)
        let line: UInt = #line - 1
        
        XCTAssertEqual(mock.logs.count, 1)
        XCTAssertTrue(mock.logs[0].line == line)
    }
    
    func testLogFunction() {
        logger.info(message)
        let function: StaticString = #function
        
        XCTAssertEqual(mock.logs.count, 1)
        XCTAssertEqual(mock.logs[0].function, String(describing: function))
    }
}
