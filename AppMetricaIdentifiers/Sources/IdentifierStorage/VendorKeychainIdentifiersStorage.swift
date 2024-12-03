
import AppMetricaKeychain

class VendorKeychainIdentifiersStorage: KeychainIdentifiersStorage {
    
    private func wrapError(_ closure: () throws -> ()) rethrows {
        do {
            try closure()
        } catch let e as IdentifierStorageError {
            throw e
        } catch let e as KeychainError {
            switch e.code {
            case .duplicate:
                break
            default:
                throw IdentifierStorageError.underlying(e)
            }
        } catch let e {
            throw IdentifierStorageError.underlying(e)
        }
    }
    
    override func saveIdentifiers(_ ids: IdentifiersStorageData) throws {
        
        try wrapError {
            if let deviceID = ids.deviceID?.rawValue {
                try addStringValue(deviceID, for: .deviceID)
            }
        }
        
        try wrapError {
            let storedDeviceID = try getStringValue(for: .deviceID)
            if let deviceIDHash = ids.deviceIDHash?.rawValue,
                let deviceID = ids.deviceID?.rawValue, storedDeviceID == deviceID {
                try addStringValue(deviceIDHash, for: .deviceIDHash)
            } else {
                throw IdentifierStorageError.deviceIDMismatch
            }
        }
        
    }
    
}
