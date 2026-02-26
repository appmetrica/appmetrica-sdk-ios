import AppMetricaPlatform

extension RunEnvironment {
    
    var priorities: [IdentifierSource] {
        switch self {
        case .mainApp:
            return [.privateFile, .privateKeychain, .migrationData, .groupFile, .groupKeychain, .vendorKeychain]
        case .extension:
            return [.groupFile, .groupKeychain, .privateFile, .privateKeychain, .migrationData, .vendorKeychain]
        @unknown default:
            return [.groupFile, .groupKeychain,  .privateFile, .privateKeychain, .migrationData, .vendorKeychain]
        }
    }
    
}
