
import AppMetricaLog

final class LogFacadeMock: LogFacade {

    struct LogMock: Equatable {
        let channel: String
        let level: AppMetricaLog.LogLevel
        let file: String
        let function: String
        let line: UInt
        let addBacktrace: Bool
        let message: String
    }
    
    private(set) var logs: [LogMock] = []
    
    override func logMessage(toChannel: String,
                             level: AppMetricaLog.LogLevel,
                             file: UnsafePointer<CChar>,
                             function: UnsafePointer<CChar>,
                             line: UInt,
                             addBacktrace: Bool,
                             message: String) {
        logs.append(
            LogMock(channel: toChannel,
                    level: level,
                    file: String(cString: file),
                    function: String(cString: function),
                    line: line,
                    addBacktrace: addBacktrace,
                    message: message)
        )
    }
}
