
enum KeychainValueState<T> {
    case none
    case locked
    case data(T)
    
    init(data: T?) {
        if let data = data {
            self = .data(data)
        } else {
            self = .none
        }
    }
    
    var data: T? {
        switch self {
        case .data(let d): return d
        default: return nil
        }
    }
    
    var isData: Bool {
        switch self {
        case .data: return true
        default: return false
        }
    }
    
    var isLocked: Bool {
        switch self {
        case .locked: return true
        default: return false
        }
    }
    
    var isNone: Bool {
        switch self {
        case .none: return true
        default: return false
        }
    }
    
}

extension KeychainValueState {
    
    func map<N>(_ transform: (T) throws -> N) rethrows -> KeychainValueState<N> {
        switch self {
        case .none: return .none
        case .locked: return .locked
        case .data(let data): return try .data(transform(data))
        }
    }
    
}

extension KeychainValueState: Equatable where T: Equatable {
    
    static func ==(lhs: Self, rhs: T) -> Bool {
        switch (lhs) {
        case .data(let d): return d == rhs
        default: return false
        }
    }
    
    static func ==(lhs: T, rhs: Self) -> Bool {
        switch (rhs) {
        case .data(let d): return d == lhs
        default: return false
        }
    }
    
    static func !=(lhs: Self, rhs: T) -> Bool {
        return !(lhs == rhs)
    }
    
    static func !=(lhs: T, rhs: Self) -> Bool {
        return !(lhs == rhs)
    }
    
}
