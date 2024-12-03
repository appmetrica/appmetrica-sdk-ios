
import Foundation
import Darwin

public enum FileLockError: Error {
    case system(code: Int32)
}

public final class FileLock {
    
    public let filePath: String
    private let fd: Int32
    
    init(filePath: String, fd: Int32) {
        self.filePath = filePath
        self.fd = fd
    }
    
    deinit {
        let result = Darwin.close(fd)
        if result == -1 {
            logger.error("close \(filePath) error: \(errno) \(String(cString: strerror(errno)))")
        }
    }
    
    private func flockWithBlocking(mode: Int32) {
        let result = flock(fd, mode)
        if result == -1 {
            logger.error("flock \(filePath) mode: \(mode) error: \(errno) \(String(cString: strerror(errno)))")
        }
    }
    
    private func flockWithNonBlocking(mode: Int32) -> Bool {
        let result = flock(fd, mode | LOCK_NB)
        if result == -1 {
            switch errno {
            case EWOULDBLOCK:
                return false
            default:
                logger.error("flock: mode: \(mode) error: \(errno) \(String(cString: strerror(errno)))")
                return false
            }
        }
        return true
    }
    
    public func lockExclusive() {
        flockWithBlocking(mode: LOCK_EX)
    }
    
    public func lockShared() {
        flockWithBlocking(mode: LOCK_SH)
    }
    
    public func unlock() {
        flockWithBlocking(mode: LOCK_UN)
    }
    
    public func tryLockExculusive() -> Bool {
        flockWithNonBlocking(mode: LOCK_EX)
    }
    
    public func tryLockShared() -> Bool {
        flockWithNonBlocking(mode: LOCK_SH)
    }
    
    public func withExclusiveLock(_ closure: () throws -> ()) rethrows {
        lockExclusive()
        defer { unlock() }
        try closure()
    }
    
    public func withSharedLock(_ closure: () throws -> ()) rethrows {
        lockShared()
        defer { unlock() }
        try closure()
    }
    
}

public struct FileLockFactory {
    
    public let filePath: String
    
    public init(filePath: String) {
        self.filePath = filePath
    }
    
    public func open() throws -> FileLock {
        let result = filePath.withCString { Darwin.open($0, O_CREAT, S_IRWXU) }
        if result == -1 {
            throw FileLockError.system(code: errno)
        }
        return FileLock(filePath: filePath, fd: result)
    }
    
    
}
