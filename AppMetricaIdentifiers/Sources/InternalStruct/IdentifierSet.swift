
struct IdentifierSet<T>: Sequence {
    typealias Element = InternalArray.Element
    typealias Iterator = InternalArray.Iterator
    
    typealias InternalArray = [T?]
    private var elements: InternalArray
    
    fileprivate init(elements: InternalArray) {
        self.elements = elements
    }
    
    init() {
        elements = Array<T?>(repeating: nil, count: IdentifierSource.allCases.count)
    }
    
    init(appKeychain: T?, appSettings: T?, groupKeychain: T?, groupSettings: T?, vendorKeychain: T?) {
        var newContent = Array<T?>(repeating: nil, count: IdentifierSource.allCases.count)
        newContent[IdentifierSource.privateKeychain.rawValue] = appKeychain
        newContent[IdentifierSource.privateFile.rawValue] = appSettings
        newContent[IdentifierSource.groupKeychain.rawValue] = groupKeychain
        newContent[IdentifierSource.groupFile.rawValue] = groupSettings
        newContent[IdentifierSource.vendorKeychain.rawValue] = vendorKeychain
        self.elements = newContent
    }
    
    var appKeychain: T {
        return elements[IdentifierSource.privateKeychain.rawValue]!
    }
    
    var appSettings: T {
        return elements[IdentifierSource.privateFile.rawValue]!
    }

    var groupKeychain: T? {
        return elements[IdentifierSource.groupKeychain.rawValue]
    }
    
    var groupSettings: T? {
        return elements[IdentifierSource.groupFile.rawValue]
    }
    
    var vendorKeychain: T? {
        return elements[IdentifierSource.vendorKeychain.rawValue]
    }
    
    subscript(_ index: IdentifierSource) -> T? {
        get { return elements[index.rawValue] }
        set { elements[index.rawValue] = newValue }
    }
    
    var actualSet: InternalArray.SubSequence {
        return elements[..<IdentifierSource.migrationData.rawValue]
    }
    
    func makeIterator() -> InternalArray.Iterator {
        return elements.makeIterator()
    }
    
    var filledIdentifierCount: Int {
        var count = 0
        for i in elements {
            if i != nil {
                count += 1
            }
        }
        return count
    }
    
    var filledSources: IdentifierSourceSet {
        let result = IdentifierSource.allCases.filter { elements[$0.rawValue] != nil }
        return Set(result)
    }
    
}

extension IdentifierSet {
    
    func forNonNullEach(_ f: (T) throws -> ()) rethrows {
        try elements.forEach {
            if let v = $0 {
                try f(v)
            }
        }
    }
    
}

extension IdentifierSet {
    
    func enumeratedMap<N>(_ transform: (IdentifierSource, T) throws -> N?) rethrows -> IdentifierSet<N> {
        var newContent = Array<N?>(repeating: nil, count: IdentifierSource.allCases.count)
        for i in IdentifierSource.allCases {
            if let value = elements[i.rawValue] {
                newContent[i.rawValue] = try transform(i, value)
            }
        }
        return .init(elements: newContent)
    }
    
    func map<N>(_ transform: (T) throws -> N?) rethrows -> IdentifierSet<N> {
        .init(elements: try elements.map { try $0.flatMap(transform) })
    }
    
    func contains(_ f: (T) throws -> Bool) rethrows -> Bool {
        try elements.contains { value in
            if let value = value {
                return try f(value)
            } else {
                return false
            }
        }
    }
    
}

extension IdentifierSet: Equatable where T: Equatable {
    
}
