
protocol OptionalConstructable {
    associatedtype RawValue
    init?(optionalValue: RawValue?)
}

public struct AppMetricaUUID: RawRepresentable, Hashable, OptionalConstructable {
    public var rawValue: String
    
    public init?(rawValue: String) {
        guard !rawValue.isEmpty else { return nil }
        self.rawValue = rawValue
    }
    
    init(nonEmptyString: String) {
        self.rawValue = nonEmptyString
    }
    
}

public struct DeviceID: RawRepresentable, Hashable, OptionalConstructable {
    public var rawValue: String
    
    public init?(rawValue: String) {
        guard !rawValue.isEmpty else { return nil }
        self.rawValue = rawValue
    }
    
    init(nonEmptyString: String) {
        self.rawValue = nonEmptyString
    }
    
}

public struct DeviceIDHash: RawRepresentable, Hashable, OptionalConstructable {
    public var rawValue: String
    
    public init?(rawValue: String) {
        guard !rawValue.isEmpty else { return nil }
        self.rawValue = rawValue
    }
    
    init(nonEmptyString: String) {
        self.rawValue = nonEmptyString
    }
    
}

extension OptionalConstructable where Self: RawRepresentable {
    
    init?(optionalValue: RawValue?) {
        guard let optionalValue = optionalValue else { return nil }
        self.init(rawValue: optionalValue)
    }
    
}

extension DeviceID {
    static let defaultValue: DeviceID = .init(nonEmptyString: "");
}

extension AppMetricaUUID {
    static let defaultValue: AppMetricaUUID = .init(nonEmptyString: "")
}
