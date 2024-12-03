
import AppMetricaKeychain

class KeychainIdentifiersStorage: MutableIdentifiersStorable {
    
    let keychain: KeychainStoring
    init(keychain: KeychainStoring) {
        self.keychain = keychain
    }
    
    func getStringValue(for key: IdentifiersCodingKeys) throws -> String? {
        let result = try keychain.stringValue(for: key.rawValue)
        if let result = result, !result.isEmpty {
            return result
        } else {
            return nil
        }
    }
    
    func setStringValue(_ value: String, for key: IdentifiersCodingKeys) throws {
        try keychain.setStringValue(value, for: key.rawValue)
    }
    
    func addStringValue(_ value: String, for key: IdentifiersCodingKeys) throws {
        try keychain.addStringValue(value, for: key.rawValue)
    }
    
    func removeStringValue(for key: IdentifiersCodingKeys) throws {
        try keychain.removeStringValue(for: key.rawValue)
    }
    
    func fetchIdentifiers() throws -> KeychainValueState<IdentifiersStorageData> {
        do {
            let deviceID = try getStringValue(for: .deviceID)
            let deviceIDHash = try getStringValue(for: .deviceIDHash)
            
            let ids = IdentifiersStorageData(
                deviceID: .init(optionalValue: deviceID),
                deviceIDHash: .init(optionalValue: deviceIDHash)
            )
            return !ids.isEmpty ? .data(ids) : .none
        } catch let e as KeychainError {
            switch e.code {
            case .locked:
                return .locked
            default:
                throw IdentifierStorageError.underlying(e)
            }
        } catch let e {
            throw IdentifierStorageError.underlying(e)
        }
    }
    
    func saveIdentifiers(_ ids: IdentifiersStorageData) throws {
        do {
            if let deviceID = ids.deviceID?.rawValue {
                try setStringValue(deviceID, for: .deviceID)
                if let deviceIDHash = ids.deviceIDHash?.rawValue {
                    try setStringValue(deviceIDHash, for: .deviceIDHash)
                } else {
                    try removeStringValue(for: .deviceIDHash)
                }
            }
        } catch let e as KeychainError {
            switch e.code {
            case .locked:
                throw IdentifierStorageError.locked
            default:
                throw IdentifierStorageError.underlying(e)
            }
        } catch let e {
            throw IdentifierStorageError.underlying(e)
        }
    }
    
}
