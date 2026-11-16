import Foundation
import XCTest
import AppMetricaTestUtils
@testable import AppMetricaIdentifiers

class JSONIdentifiersStorageTests: XCTestCase {
    
    var filePath: String!
    var fileStorage: FileStorage!
    var provider: JSONIdentifiersStorage!
    
    private func readIntoLID() throws -> IdentifiersStorageData {
        let fileData = try Data(contentsOf: URL(fileURLWithPath: filePath))
        let dict = try Foundation.JSONSerialization.jsonObject(with: fileData) as? [String: String]
        
        var lid = IdentifiersStorageData()
        lid.deviceID = DeviceID(optionalValue: dict?[IdentifiersCodingKeys.deviceID.rawValue])
        lid.deviceIDHash = DeviceIDHash(optionalValue: dict?[IdentifiersCodingKeys.deviceIDHash.rawValue])
        lid.appMetricaUUID = AppMetricaUUID(optionalValue: dict?[IdentifiersCodingKeys.appMetricaUUID.rawValue])
        
        return lid
    }
    
    private func writeIntoFile(_ lid: IdentifiersStorageData) throws {
        var json: [String: String] = [:]
        if let deviceID = lid.deviceID {
            json[IdentifiersCodingKeys.deviceID.rawValue] = deviceID.rawValue
        }
        if let deviceIDHash = lid.deviceIDHash {
            json[IdentifiersCodingKeys.deviceIDHash.rawValue] = deviceIDHash.rawValue
        }
        if let appMetricaUUID = lid.appMetricaUUID {
            json[IdentifiersCodingKeys.appMetricaUUID.rawValue] = appMetricaUUID.rawValue
        }
        
        let data = try Foundation.JSONSerialization.data(withJSONObject: json)
        try data.write(to: URL(fileURLWithPath: filePath), options: [.atomic])
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
     
        filePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] + "/test.json"
        
        if FileManager.default.fileExists(atPath: filePath) {
            try FileManager.default.removeItem(atPath: filePath)
        }
        
        fileStorage = DiskFileStorage(path: filePath)
        let jsonProvider = FileStorageJSONProvider(fileStorage: fileStorage)
        provider = JSONIdentifiersStorage(jsonProvider: jsonProvider)
    }
    
    func testReadEmptyFile() throws {
        let id = try provider.fetchIdentifiers()
        XCTAssert(id.isNone)
    }
    
    func testWriteEmptyFile() throws {
        let lid = IdentifiersStorageData.generateISD()
        
        try provider.saveIdentifiers(lid)
        
        let rLid = try readIntoLID()
        XCTAssertEqual(rLid, lid)
    }
    
    func testReadFile() throws {
        let lid = IdentifiersStorageData.generateISD()
        try writeIntoFile(lid)
        
        let pLid = try provider.fetchIdentifiers()
        XCTAssertEqual(lid, pLid.data)
    }
    
    func testOverwriteFile() throws {
        let lid = IdentifiersStorageData.generateISD()
        try writeIntoFile(lid)
        
        let newLid = IdentifiersStorageData.generateISD()
        try provider.saveIdentifiers(newLid)
        
        let rLid = try readIntoLID()
        
        XCTAssertEqual(newLid, rLid)
    }
    
    func testCorruptedFileIsRecoveredFromExistingIdentifiers() throws {
        for corruptedSource in [IdentifierSource.privateFile, .groupFile] {
            try Data("{invalid JSON".utf8).write(to: URL(fileURLWithPath: filePath))
            let original = IdentifiersStorageData.generateISD()
            let healthyStorage = IdentifiersStorageMock()
            healthyStorage.value = .data(original)
            var providers = IdentifierSet<MutableIdentifiersStorable>()
            providers[corruptedSource] = provider
            providers[corruptedSource == .privateFile ? .groupFile : .privateFile] = healthyStorage

            let loaded = IdentifierLoader.loadIdentifiers(providers: providers)
            XCTAssertEqual(loaded.corruptedSources, [corruptedSource])
            XCTAssertFalse(loaded.hasUnavailableSources)
            let manager = SyncManager(providers: providers, runEnv: .mainApp,
                                      deviceIDGenerator: DeviceIDGeneratorMock(deviceID: original.deviceID!),
                                      appMetricaUUIDGenerator: AppMetricaUUIDGeneratorMock(value: original.appMetricaUUID!))
            let recovered = try manager.loadAndSyncIfNeeded()
            XCTAssertEqual(recovered.deviceID, original.deviceID)
            XCTAssertEqual(recovered.appMetricaUUID, original.appMetricaUUID)
            XCTAssertEqual(try provider.fetchIdentifiers().data, original)
            XCTAssertEqual(healthyStorage.saveCallCount, 0)
        }
    }

    func testCorruptedFileWithoutBackupDoesNotGenerateIdentifiers() throws {
        let corruptedData = Data("{invalid JSON".utf8)
        try corruptedData.write(to: URL(fileURLWithPath: filePath))
        let original = IdentifiersStorageData.generateISD()
        let keychain = IdentifiersStorageMock().emulateKeychain()
        keychain.value = .data(original.withoutAppMetricaUUID)
        var providers = IdentifierSet<MutableIdentifiersStorable>()
        providers[.privateFile] = provider
        providers[.privateKeychain] = keychain
        let manager = SyncManager(providers: providers, runEnv: .mainApp,
                                  deviceIDGenerator: DeviceIDGeneratorMock(deviceID: original.deviceID!),
                                  appMetricaUUIDGenerator: AppMetricaUUIDGeneratorMock(value: original.appMetricaUUID!))
        XCTAssertThrowsError(try manager.loadAndSyncIfNeeded())
        XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: filePath)), corruptedData)
        XCTAssertEqual(keychain.saveCallCount, 0)
    }

}
