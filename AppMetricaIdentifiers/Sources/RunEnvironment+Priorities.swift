import AppMetricaPlatform

extension RunEnvironment {
    
    var priorities: [IdentifierSource] {
        switch self {
        case .mainApp:
            return [.privateFile, .privateKeychain, .groupFile, .groupKeychain, .vendorKeychain]
        case .extension:
            return [.groupFile, .groupKeychain, .privateFile, .privateKeychain, .vendorKeychain]
        @unknown default:
            return [.groupFile, .groupKeychain,  .privateFile, .privateKeychain, .vendorKeychain]
        }
    }
    
}
