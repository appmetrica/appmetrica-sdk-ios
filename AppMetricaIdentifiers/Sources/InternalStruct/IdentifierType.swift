import Foundation

enum IdentifierType: Int, Hashable {
    case device
    case uuid
}

extension IdentifierType {
    
    var allowedStorages: IdentifierSourceSet {
        switch self {
        case .device:
            return IdentifierSource.deviceIDSources
        case .uuid:
            return IdentifierSource.appMetricaUUIDSources
        }
    }
    
}
