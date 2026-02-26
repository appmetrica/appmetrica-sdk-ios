
enum IdentifierSource: Int, CaseIterable, Hashable, Sendable {
    
    // on update see also
    // - IdentifierSource.sourcesStoringOnlyDeviceID
    // - IdentifierSource.deviceIDSources
    // - IdentifierSource.appMetricaUUIDSources
    
    case privateKeychain
    case privateFile
    
    case groupKeychain
    case groupFile
    
    case vendorKeychain
    
    case migrationData
    
    static let allActualSet: Set<Self> = [
        .privateKeychain,
        .privateFile,
        .groupKeychain,
        .groupFile,
        .vendorKeychain,
    ]
    static let allSet: Set<Self> = Set(allCases)
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
    
    static let deviceIDSources: Set<Self> = [
        .privateKeychain,
        .privateFile,
        .groupKeychain,
        .groupFile,
        .vendorKeychain,
    ]
    static let appMetricaUUIDSources: Set<Self> = [.privateFile, .groupFile]
    
}
