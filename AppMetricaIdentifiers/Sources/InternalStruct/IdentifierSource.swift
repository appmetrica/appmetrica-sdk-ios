
enum IdentifierSource: Int, CaseIterable, Hashable {
    case privateKeychain
    case privateFile
    
    case groupKeychain
    case groupFile
    
    case vendorKeychain
    
    static var allSet: Set<Self> = Set(allCases)
}

typealias IdentifierSourceSet = Set<IdentifierSource>

extension IdentifierSource {
    
    // Updating the deviceId in these sources is not allowed
    static let sourcesWithProtectedRewriting: Set<Self> = [.vendorKeychain]
    
    static let sourcesStoringOnlyDeviceID: Set<Self> = [
        .privateKeychain,
        .groupKeychain,
        .vendorKeychain,
    ]
    
    var isProtectedForRewriting: Bool {
        Self.sourcesWithProtectedRewriting.contains(self)
    }
    
    var isStoreOnlyDeviceIdentifier: Bool {
        Self.sourcesStoringOnlyDeviceID.contains(self)
    }
}

extension IdentifierSource {
    
    static let deviceIDSources: Set<Self> = allSet
    static let appMetricaUUIDSources: Set<Self> = [.privateFile, .groupFile]
    
}
