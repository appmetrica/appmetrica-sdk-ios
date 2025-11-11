
// If the data storage format and location change, you must notify https://nda.ya.ru/t/94XNTaaf7LkVFu
private struct RawJSONIdentifierStorageData: Codable {
    var deviceID: String?
    var deviceIDHash: String?
    var appMetricaUUID: String?
    
    typealias CodingKeys = IdentifiersCodingKeys
    
    init(loadedIdentifiers: IdentifiersStorageData) {
        self.deviceID = loadedIdentifiers.deviceID?.rawValue
        self.deviceIDHash = loadedIdentifiers.deviceIDHash?.rawValue
        self.appMetricaUUID = loadedIdentifiers.appMetricaUUID?.rawValue
    }
    
    var loadedIdentifiers: IdentifiersStorageData {
        return IdentifiersStorageData(
            deviceID: deviceID.flatMap { DeviceID(rawValue: $0) },
            deviceIDHash: deviceIDHash.flatMap { DeviceIDHash(rawValue: $0) },
            appMetricaUUID: appMetricaUUID.flatMap { AppMetricaUUID(rawValue: $0) }
        )
    }
}

final class JSONIdentifiersStorage: MutableIdentifiersStorable {
    
    let jsonProvider: FileStorageJSONProvider
    init(jsonProvider: FileStorageJSONProvider) {
        self.jsonProvider = jsonProvider
    }
    
    func fetchIdentifiers() throws -> KeychainValueState<IdentifiersStorageData> {
        // If the data storage format and location change, you must notify https://nda.ya.ru/t/94XNTaaf7LkVFu
        do {
            let result = try jsonProvider.read(type: RawJSONIdentifierStorageData.self)?.loadedIdentifiers
            if let result = result, !result.isEmpty {
                return .data(result)
            } else {
                return .none
            }
        } catch let e {
            throw IdentifierStorageError.underlying(e)
        }
    }
    
    func saveIdentifiers(_ ids: IdentifiersStorageData) throws {
        // If the data storage format and location change, you must notify https://nda.ya.ru/t/94XNTaaf7LkVFu
        let rawIdentifiers = RawJSONIdentifierStorageData(loadedIdentifiers: ids)
        do {
            try jsonProvider.write(rawIdentifiers)
        } catch let e {
            throw IdentifierStorageError.underlying(e)
        }
    }
    
}
