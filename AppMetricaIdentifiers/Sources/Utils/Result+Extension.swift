
public extension Result {
    
    var value: Success? {
        switch self {
        case .success(let v): return v
        case .failure: return nil
        }
    }
    
    var error: Failure? {
        switch self {
        case .success: return nil
        case .failure(let v): return v
        }
    }
    
}


