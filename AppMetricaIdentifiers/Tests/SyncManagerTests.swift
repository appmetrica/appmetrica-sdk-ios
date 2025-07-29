import Foundation
import XCTest
@testable import AppMetricaIdentifiers
import AppMetricaKeychain

class SyncManagerTests: XCTestCase {
    
    var appKeychain: IdentifiersStorageMock!
    var appSettings: IdentifiersStorageMock!
    var groupKeychain: IdentifiersStorageMock!
    var groupSettings: IdentifiersStorageMock!
    var vendorKeychain: IdentifiersStorageMock!
    
    var sourcesSet: IdentifierSet<IdentifiersStorageMock>!
    
    var deviceIDGenerator: DeviceIDGeneratorMock!
    var appMetricaUUIDGenerator: AppMetricaUUIDGeneratorMock!
    var syncManager: SyncManager!
    
    override func setUp() {
        super.setUp()
        
        deviceIDGenerator = DeviceIDGeneratorMock(deviceID: DeviceID(nonEmptyString: UUID().uuidString))
        appMetricaUUIDGenerator = AppMetricaUUIDGeneratorMock(value: AppMetricaUUID(nonEmptyString: UUID().uuidString.replacingOccurrences(of: "-", with: "")))
        
        appKeychain = IdentifiersStorageMock().emulateKeychain()
        appSettings = IdentifiersStorageMock()
        groupKeychain = IdentifiersStorageMock().emulateKeychain()
        groupSettings = IdentifiersStorageMock()
        vendorKeychain = IdentifiersStorageMock().emulateKeychain()
        
        sourcesSet = IdentifierSet<IdentifiersStorageMock>()
        sourcesSet[.privateKeychain] = appKeychain
        sourcesSet[.privateFile] = appSettings
        sourcesSet[.groupKeychain] = groupKeychain
        sourcesSet[.groupFile] = groupSettings
        sourcesSet[.vendorKeychain] = vendorKeychain
        
        syncManager = SyncManager(
            providers: sourcesSet.map { $0 },
            runEnv: .mainApp,
            deviceIDGenerator: deviceIDGenerator,
            appMetricaUUIDGenerator: appMetricaUUIDGenerator
        )
    }
    
    func testNewIdentifiers() throws {
        let deviceID = DeviceID(nonEmptyString: UUID().uuidString)
        let appMetricaUUID = AppMetricaUUID(nonEmptyString: UUID().uuidString.replacingOccurrences(of: "-", with: ""))
        
        deviceIDGenerator.deviceID = deviceID
        deviceIDGenerator.generateExpectation = expectation(description: "Generate DeviceID")
        appMetricaUUIDGenerator.appMetricaUUID = appMetricaUUID
        appMetricaUUIDGenerator.generateAppMetricaExpectation = expectation(description: "Generate AppMetricaUUID")
        
        for i in IdentifierSource.allSet {
            sourcesSet[i]?.saveExpectation = expectation(description: "Save expectation \(i)")
            sourcesSet[i]?.saveExpectation?.isInverted = true
        }
        
        let id = syncManager.loadIfNeeded()
        XCTAssertEqual(id.deviceID, deviceID)
        XCTAssertEqual(id.appMetricaUUID, appMetricaUUID)
        XCTAssertNil(id.deviceHashID)
        
        wait(for: [
            deviceIDGenerator.generateExpectation,
            appMetricaUUIDGenerator.generateAppMetricaExpectation
        ].compactMap { $0 }, timeout: 1)
        wait(for: Array(sourcesSet).compactMap { $0?.saveExpectation }, timeout: 1)
        
        let newId = try syncManager.loadAndSyncIfNeeded()
        XCTAssertEqual(id, newId)
        
        let lid = IdentifiersStorageData(
            deviceID: deviceID,
            appMetricaUUID: appMetricaUUID
        )
        checkISD(idSet: sourcesSet, isd: lid)
    }
    
    func testReadIdentifiers() throws {
        let lid = IdentifiersStorageData.generateISD()
        appSettings.value = .data(lid)
        
        deviceIDGenerator.generateExpectation = expectation(description: "Generate DeviceID")
        deviceIDGenerator.generateExpectation?.isInverted = true
        appMetricaUUIDGenerator.generateAppMetricaExpectation = expectation(description: "Generate AppMetricaUUID")
        appMetricaUUIDGenerator.generateAppMetricaExpectation?.isInverted = true
        
        let syncId = try syncManager.loadAndSyncIfNeeded()
        wait(for: [
            deviceIDGenerator.generateExpectation,
            appMetricaUUIDGenerator.generateAppMetricaExpectation
        ].compactMap { $0 }, timeout: 1)
        
        XCTAssertEqual(lid.deviceID, syncId.deviceID)
        XCTAssertEqual(lid.deviceIDHash, syncId.deviceHashID)
        XCTAssertEqual(lid.appMetricaUUID, syncId.appMetricaUUID)
        
        checkISD(idSet: sourcesSet, isd: lid, sources: IdentifierSource.allSet.subtracting([.privateFile]))
    }
    
    func testMigration() throws {
        let lid = IdentifiersStorageData.generateISD()
        
        syncManager.migrationData = lid
        
        let syncId = try syncManager.loadAndSyncIfNeeded()
        XCTAssertEqual(lid.deviceID, syncId.deviceID)
        XCTAssertEqual(lid.deviceIDHash, syncId.deviceHashID)
        XCTAssertEqual(lid.appMetricaUUID, syncId.appMetricaUUID)
        
        checkISD(idSet: sourcesSet, isd: lid, sources: IdentifierSource.allSet.subtracting([.privateFile]))
    }
    
    func testMigrationIfDataExists() throws {
        let lid = IdentifiersStorageData.generateISD()
        let lid2 = IdentifiersStorageData.generateISD()
        
        appKeychain.value = .data(lid.withoutAppMetricaUUID)
        appSettings.value = .data(lid)
        syncManager.migrationData = lid2
        
        let syncId = try syncManager.loadAndSyncIfNeeded()
        XCTAssertEqual(lid.deviceID, syncId.deviceID)
        XCTAssertEqual(lid.deviceIDHash, syncId.deviceHashID)
        XCTAssertEqual(lid.appMetricaUUID, syncId.appMetricaUUID)
        
        checkISD(idSet: sourcesSet, isd: lid, sources: IdentifierSource.allSet.subtracting([.privateFile]))
    }
    
    func testUpdateDeviceIDAndDeviceIDHash() throws {
        let lid = IdentifiersStorageData.generateISD()
        let lid2 = IdentifiersStorageData.generateISD()
        
        appKeychain.value = .data(lid.withoutAppMetricaUUID)
        appSettings.value = .data(lid)
        
        let syncId = try syncManager.loadAndSyncIfNeeded()
        XCTAssertEqual(lid.deviceID, syncId.deviceID)
        XCTAssertEqual(lid.deviceIDHash, syncId.deviceHashID)
        XCTAssertEqual(lid.appMetricaUUID, syncId.appMetricaUUID)
        
        let newSyncId = syncManager.update(deviceID: lid2.deviceID!, deviceIDHash: lid2.deviceIDHash)
        XCTAssertEqual(newSyncId.deviceID, lid2.deviceID)
        XCTAssertEqual(newSyncId.deviceHashID, lid2.deviceIDHash)
        XCTAssertEqual(newSyncId.appMetricaUUID, lid.appMetricaUUID)
        
        let newLid = IdentifiersStorageData(
            deviceID: newSyncId.deviceID,
            deviceIDHash: newSyncId.deviceHashID,
            appMetricaUUID: newSyncId.appMetricaUUID
        )
        
        checkISD(idSet: sourcesSet, isd: newLid, sources: IdentifierSource.allSet.subtracting([.vendorKeychain]))
    }
    
    func testUpdateDeviceID() throws {
        let lid = IdentifiersStorageData.generateISD()
        let lid2 = IdentifiersStorageData.generateISD()
        let newDeviceID = DeviceID(nonEmptyString: UUID().uuidString)
        
        appKeychain.value = .data(lid.withoutAppMetricaUUID)
        appSettings.value = .data(lid)
        vendorKeychain.value = .data(lid2.withoutAppMetricaUUID)
        
        let syncId = try syncManager.loadAndSyncIfNeeded()
        XCTAssertEqual(lid.deviceID, syncId.deviceID)
        XCTAssertEqual(lid.deviceIDHash, syncId.deviceHashID)
        XCTAssertEqual(lid.appMetricaUUID, syncId.appMetricaUUID)
        
        let newSyncId = syncManager.updateDeviceID(newDeviceID)
        XCTAssertEqual(newSyncId.deviceID, newDeviceID)
        XCTAssertEqual(newSyncId.deviceHashID, lid.deviceIDHash)
        XCTAssertEqual(newSyncId.appMetricaUUID, lid.appMetricaUUID)
        
        let newLid = IdentifiersStorageData(
            deviceID: newSyncId.deviceID,
            deviceIDHash: newSyncId.deviceHashID,
            appMetricaUUID: newSyncId.appMetricaUUID
        )
        
        checkISD(idSet: sourcesSet, isd: newLid, sources: IdentifierSource.allSet.subtracting([.vendorKeychain]))
    }
    
    func testMigrationData() throws {
        let lid = IdentifiersStorageData.generateISD().withoutAppMetricaUUID
        
        syncManager.migrationData = lid
        
        let syncId = try syncManager.loadAndSyncIfNeeded()
        XCTAssertEqual(syncId.deviceID, lid.deviceID)
        XCTAssertEqual(syncId.deviceHashID, lid.deviceIDHash)
        
        var resultIdentifiers = lid
        resultIdentifiers.appMetricaUUID = syncId.appMetricaUUID
        checkISD(idSet: sourcesSet, isd: resultIdentifiers)
    }
    
    func testIgnoreMigrationDataIfNewAvailable() throws {
        let lid = IdentifiersStorageData.generateISD().withoutAppMetricaUUID
        let lid2 = IdentifiersStorageData.generateISD()
        
        appKeychain.value = .data(lid2.withoutAppMetricaUUID)
        groupKeychain.value = .data(lid2.withoutAppMetricaUUID)
        
        syncManager.migrationData = lid
        
        let syncId = try syncManager.loadAndSyncIfNeeded()
        XCTAssertEqual(syncId.deviceID, lid2.deviceID)
        XCTAssertEqual(syncId.deviceHashID, lid2.deviceIDHash)
        
        var resultIdentifiers = lid2
        resultIdentifiers.appMetricaUUID = syncId.appMetricaUUID
        checkISD(idSet: sourcesSet, isd: resultIdentifiers)
    }
    
}
