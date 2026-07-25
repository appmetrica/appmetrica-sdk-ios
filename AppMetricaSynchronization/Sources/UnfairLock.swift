
import Foundation

public final class UnfairLock: @unchecked Sendable {
    
    @usableFromInline
    var _lock = os_unfair_lock_s()
    
    public init() {
    }

    @inlinable
    @inline(__always)
    public func lock() {
      os_unfair_lock_lock(&_lock)
    }

    @inlinable
    @inline(__always)
    public func unlock() {
      os_unfair_lock_unlock(&_lock)
    }

    @inlinable
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

    @usableFromInline
    var _rawValue: T
    public let lock = UnfairLock()

    @inlinable
    public init(value: T) {
        self._rawValue = value
    }

    @inlinable
    public var value: T {
        get { lock.withLock { _rawValue } }
        set { lock.withLock { _rawValue = newValue } }
    }

    @inlinable
    @discardableResult
    public func updateValue(closure: (inout T) throws -> ()) rethrows -> T {
        try lock.withLock {
            try closure(&_rawValue)
            return _rawValue
        }
    }

    @inlinable
    @discardableResult
    public func updateAndReturn<N>(closure: (inout T) throws -> N) rethrows -> N {
        try lock.withLock {
            try closure(&_rawValue)
        }
    }

}

extension UnfairLocker: @unchecked Sendable where T: Sendable {}
