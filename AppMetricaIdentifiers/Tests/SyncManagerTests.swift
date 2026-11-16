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
        
        let id = try syncManager.loadIfNeeded()
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
        
        syncManager.appMigrationData = lid
        
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
        syncManager.appMigrationData = lid2
        
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
        
        let newSyncId = try syncManager.update(deviceID: lid2.deviceID!, deviceIDHash: lid2.deviceIDHash)
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
    
    func testMigrationData() throws {
        let lid = IdentifiersStorageData.generateISD().withoutAppMetricaUUID
        
        syncManager.appMigrationData = lid
        
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
        
        syncManager.appMigrationData = lid
        
        let syncId = try syncManager.loadAndSyncIfNeeded()
        XCTAssertEqual(syncId.deviceID, lid2.deviceID)
        XCTAssertEqual(syncId.deviceHashID, lid2.deviceIDHash)
        
        var resultIdentifiers = lid2
        resultIdentifiers.appMetricaUUID = syncId.appMetricaUUID
        checkISD(idSet: sourcesSet, isd: resultIdentifiers)
    }
    
    func testUnavailableSourcesDoNotGenerateOrWriteIdentifiers() throws {
        for source in IdentifierSource.allActualSet {
            for readFails in [false, true] {
                let storage = IdentifiersStorageMock()
                storage.value = .locked
                storage.fetchError = readFails ? CustomError() : nil
                var providers = IdentifierSet<MutableIdentifiersStorable>()
                providers[source] = storage
                let manager = SyncManager(providers: providers, runEnv: .mainApp,
                                          deviceIDGenerator: deviceIDGenerator,
                                          appMetricaUUIDGenerator: appMetricaUUIDGenerator)
                XCTAssertThrowsError(try manager.loadAndSyncIfNeeded())
                XCTAssertEqual(storage.saveCallCount, 0)
                let original = IdentifiersStorageData.generateISD()
                storage.fetchError = nil
                storage.value = .data(original)
                let recovered = try manager.loadAndSyncIfNeeded()
                XCTAssertEqual(recovered.deviceID, original.deviceID)
                XCTAssertEqual(recovered.appMetricaUUID, original.appMetricaUUID)
            }
        }
    }

    func testRetryAfterFailedWriteReadsOriginalIdentifiers() throws {
        for storage in sourcesSet.compactMap({ $0 }) {
            storage.saveError = CustomError()
        }
        XCTAssertThrowsError(try syncManager.loadAndSyncIfNeeded())

        let original = IdentifiersStorageData.generateISD()
        for storage in sourcesSet.compactMap({ $0 }) {
            storage.saveError = nil
            storage.value = .data(storage.storeAppMetricaUUID ? original : original.withoutAppMetricaUUID)
        }
        let recovered = try syncManager.loadAndSyncIfNeeded()
        XCTAssertEqual(recovered.deviceID, original.deviceID)
        XCTAssertEqual(recovered.appMetricaUUID, original.appMetricaUUID)
        checkISD(idSet: sourcesSet, isd: original)
    }

    func testMissingDeviceIDDoesNotPersistNewUUID() throws {
        deviceIDGenerator.deviceID = nil
        XCTAssertThrowsError(try syncManager.loadAndSyncIfNeeded())
        for storage in sourcesSet.compactMap({ $0 }) {
            XCTAssertEqual(storage.saveCallCount, 0)
        }
    }

    func testStartupUpdateHandlesVendorMismatchButPropagatesWriteFailures() throws {
        let original = IdentifiersStorageData.generateISD()
        appSettings.value = .data(original)
        _ = try syncManager.loadAndSyncIfNeeded()
        let replacement = IdentifiersStorageData.generateISD()
        vendorKeychain.saveError = IdentifierStorageError.deviceIDMismatch
        let updated = try syncManager.update(deviceID: replacement.deviceID!,
                                             deviceIDHash: replacement.deviceIDHash)
        XCTAssertEqual(updated.deviceID, replacement.deviceID)
        XCTAssertEqual(updated.deviceHashID, replacement.deviceIDHash)
        XCTAssertEqual(updated.appMetricaUUID, original.appMetricaUUID)

        vendorKeychain.saveError = IdentifierStorageError.locked
        let next = IdentifiersStorageData.generateISD()
        XCTAssertThrowsError(try syncManager.update(deviceID: next.deviceID!,
                                                   deviceIDHash: next.deviceIDHash))
    }

    func testStartupUpdateWaitsForUnavailableSources() throws {
        let original = IdentifiersStorageData.generateISD()
        appSettings.value = .data(original)
        appKeychain.value = .locked
        let replacement = IdentifiersStorageData.generateISD()
        XCTAssertThrowsError(try syncManager.update(deviceID: replacement.deviceID!,
                                                   deviceIDHash: replacement.deviceIDHash))
        for storage in sourcesSet.compactMap({ $0 }) {
            XCTAssertEqual(storage.saveCallCount, 0)
        }
        appKeychain.value = .data(original.withoutAppMetricaUUID)
        let recovered = try syncManager.loadAndSyncIfNeeded()
        XCTAssertEqual(recovered.deviceID, original.deviceID)
        XCTAssertEqual(recovered.appMetricaUUID, original.appMetricaUUID)
    }

    func testFailedSecondaryRepairPreservesPersistedIdentifiers() throws {
        for healthySource in [IdentifierSource.privateFile, .groupFile] {
            let original = IdentifiersStorageData.generateISD()
            let healthy = IdentifiersStorageMock()
            healthy.value = .data(original)
            let secondary = IdentifiersStorageMock()
            secondary.saveError = CustomError()
            var providers = IdentifierSet<MutableIdentifiersStorable>()
            providers[healthySource] = healthy
            providers[healthySource == .privateFile ? .groupFile : .privateFile] = secondary
            let manager = SyncManager(providers: providers, runEnv: .mainApp,
                                      deviceIDGenerator: deviceIDGenerator,
                                      appMetricaUUIDGenerator: appMetricaUUIDGenerator)
            for _ in 0..<2 {
                let result = try manager.loadAndSyncIfNeeded()
                XCTAssertEqual(result.deviceID, original.deviceID)
                XCTAssertEqual(result.appMetricaUUID, original.appMetricaUUID)
            }
            XCTAssertEqual(healthy.value.data, original)
            XCTAssertEqual(healthy.saveCallCount, 0)
            XCTAssertGreaterThan(secondary.saveCallCount, 0)
        }
    }

    func testCorruptedSecondaryWithFailedRepairPreservesPrimaryIdentifiers() throws {
        let original = IdentifiersStorageData.generateISD()
        appSettings.value = .data(original)
        groupSettings.fetchError = IdentifierStorageError.corrupted(CustomError())
        groupSettings.saveError = CustomError()
        let result = try syncManager.loadAndSyncIfNeeded()
        XCTAssertEqual(result.deviceID, original.deviceID)
        XCTAssertEqual(result.appMetricaUUID, original.appMetricaUUID)
        XCTAssertEqual(appSettings.saveCallCount, 0)
    }

    func testUnavailableSecondaryStillPreventsSynchronization() throws {
        let original = IdentifiersStorageData.generateISD()
        appSettings.value = .data(original)
        for readFails in [false, true] {
            groupSettings.value = .locked
            groupSettings.fetchError = readFails ? CustomError() : nil
            XCTAssertThrowsError(try syncManager.loadAndSyncIfNeeded())
            XCTAssertEqual(appSettings.value.data, original)
            for storage in sourcesSet.compactMap({ $0 }) {
                XCTAssertEqual(storage.saveCallCount, 0)
            }
        }
    }

}
