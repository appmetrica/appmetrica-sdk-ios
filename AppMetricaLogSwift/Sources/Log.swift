
import Foundation
import AppMetricaLog

public enum LogLevel {
    case info
    case warning
    case error
    case notify
}

public final class Logger: @unchecked Sendable {
    let channel: LogChannel
    var facade: LogFacade
    
    public convenience init(channel: LogChannel) {
        self.init(channel: channel, facade: LogFacade.sharedLog())
    }
    
    public init(channel: LogChannel, facade: LogFacade) {
        self.channel = channel
        self.facade = facade
    }
    
    func message(_ str: String,
                 level: LogLevel,
                 file: StaticString = #fileID,
                 line: UInt = #line,
                 function: StaticString = #function) {
        facade.logMessage(toChannel: channel as String,
                          level: level.appMetricaLogLevel,
                          file: file.utf8Start,
                          function: function.utf8Start,
                          line: line,
                          addBacktrace: false,
                          message: str)
    }
    
    public func info(_ str: String,
                     file: StaticString = #fileID,
                     line: UInt = #line,
                     function: StaticString = #function) {
        message(str, level: .info, file: file, line: line, function: function)
    }
    
    public func warning(_ str: String,
                        file: StaticString = #fileID,
                        line: UInt = #line,
                        function: StaticString = #function) {
        message(str, level: .warning, file: file, line: line, function: function)
    }
    
    public func error(_ str: String,
                      file: StaticString = #fileID,
                      line: UInt = #line,
                      function: StaticString = #function) {
        message(str, level: .error, file: file, line: line, function: function)
    }
    
    public func notify(_ str: String,
                       file: StaticString = #fileID,
                       line: UInt = #line,
                       function: StaticString = #function) {
        message(str, level: .notify, file: file, line: line, function: function)
    }
    
    public func error(_ error: Error,
                      file: StaticString = #fileID,
                      line: UInt = #line,
                      function: StaticString = #function) {
        message(String(describing: error), level: .error, file: file, line: line, function: function)
    }
}

private extension LogLevel {
    var appMetricaLogLevel: AppMetricaLog.LogLevel {
        switch self {
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        case .notify: return .notify
        }
    }
}
