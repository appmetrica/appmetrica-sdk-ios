import Foundation
import AppMetricaStorageUtils


final class ReadOnlyKeyValueIdentifiersStorage: IdentifiersStorable {
    
    let storage: KeyValueStoring
    let prefix: String
    init(storage: KeyValueStoring, prefix: String = "") {
        self.storage = storage
        self.prefix = prefix
    }
    
    private func wrappedKey(for key: IdentifiersCodingKeys) -> String {
        return prefix + key.rawValue
    }
    
    func fetchIdentifiers() throws -> KeychainValueState<IdentifiersStorageData> {
        let deviceID = try storage.string(forKey: wrappedKey(for: .deviceID))
        let deviceIDHash = try storage.string(forKey: wrappedKey(for: .deviceIDHash))
        
        let ids = IdentifiersStorageData(
            deviceID: DeviceID(optionalValue: deviceID),
            deviceIDHash: DeviceIDHash(optionalValue: deviceIDHash)
        )
        
        return !ids.isEmpty ? .data(ids) : .none
    }
    
}
