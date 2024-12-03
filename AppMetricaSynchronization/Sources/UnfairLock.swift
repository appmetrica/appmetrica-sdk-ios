
import Foundation

public final class UnfairLock {
    
    @usableFromInline
    var _lock = os_unfair_lock_s()
    
    public init() {
    }

    @inline(__always)
    public func lock() {
      os_unfair_lock_lock(&_lock)
    }

    @inline(__always)
    public func unlock() {
      os_unfair_lock_unlock(&_lock)
    }

    @inline(__always)
    public func withLock<T>(closure: () throws -> T) rethrows -> T {
      lock()
      defer {
        unlock()
      }
      return try closure()
    }
}

public final class UnfairLocker<T> {
    
    public var rawValue: T
    public let lock = UnfairLock()
    
    public init(value: T) {
        self.rawValue = value
    }
    
    public var value: T {
        get { lock.withLock { rawValue } }
        set { lock.withLock { rawValue = newValue } }
    }
    
    @discardableResult
    public func updateValue(closure: (inout T) throws -> ()) rethrows -> T {
        try lock.withLock {
            try closure(&rawValue)
            return rawValue
        }
    }
    
    @discardableResult
    public func updateAndReturn<N>(closure: (inout T) throws -> N) rethrows -> N {
        try lock.withLock {
            try closure(&rawValue)
        }
    }
    
}
