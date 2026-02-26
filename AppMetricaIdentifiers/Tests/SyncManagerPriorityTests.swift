
import Foundation
import XCTest
@testable import AppMetricaIdentifiers
import AppMetricaKeychain
import AppMetricaPlatform

class SyncManagerPriorityTests: XCTestCase {
    
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
    
    // MARK: - Helper Methods
    
    private func createSyncManager(runEnv: RunEnvironment = .mainApp) -> SyncManager {
        return SyncManager(
            providers: sourcesSet.map { $0 },
            runEnv: runEnv,
            deviceIDGenerator: deviceIDGenerator,
            appMetricaUUIDGenerator: appMetricaUUIDGenerator
        )
    }
    
    // MARK: - MainApp: appSettings vs groupSettings (privateFile vs groupFile)
    // Priority for mainApp: [.privateFile, .privateKeychain, .migrationData, .groupFile, .groupKeychain, .vendorKeychain]
    // privateFile (appSettings) has higher priority than groupFile (groupSettings)
    
    func testMainApp_AppSettingsAndGroupSettings_DifferentData_AppSettingsWins() throws {
        let appSettingsData = IdentifiersStorageData.generateISD()
        let groupSettingsData = IdentifiersStorageData.generateISD()
        
        appSettings.value = .data(appSettingsData)
        groupSettings.value = .data(groupSettingsData)
        
        let syncManager = createSyncManager(runEnv: .mainApp)
        let result = try syncManager.loadAndSyncIfNeeded()
        
        // appSettings (privateFile) has higher priority, so its data should be used
        XCTAssertEqual(result.deviceID, appSettingsData.deviceID)
        XCTAssertEqual(result.deviceHashID, appSettingsData.deviceIDHash)
        XCTAssertEqual(result.appMetricaUUID, appSettingsData.appMetricaUUID)
    }
    
    func testExtension_AppSettingsAndGroupSettings_DifferentData_GroupSettingsWins() throws {
        let appSettingsData = IdentifiersStorageData.generateISD()
        let groupSettingsData = IdentifiersStorageData.generateISD()
        
        appSettings.value = .data(appSettingsData)
        groupSettings.value = .data(groupSettingsData)
        
        let syncManager = createSyncManager(runEnv: .extension)
        let result = try syncManager.loadAndSyncIfNeeded()
        
        // For extension, groupFile has higher priority than privateFile
        XCTAssertEqual(result.deviceID, groupSettingsData.deviceID)
        XCTAssertEqual(result.deviceHashID, groupSettingsData.deviceIDHash)
        XCTAssertEqual(result.appMetricaUUID, groupSettingsData.appMetricaUUID)
    }
    
    // MARK: - MainApp: appSettings vs vendorKeychain (privateFile vs vendorKeychain)
    // privateFile (appSettings) has higher priority than vendorKeychain
    
    func testMainApp_AppSettingsAndVendorKeychain_DifferentData_AppSettingsWins() throws {
        let appSettingsData = IdentifiersStorageData.generateISD()
        let vendorKeychainData = IdentifiersStorageData.generateISD()
        
        appSettings.value = .data(appSettingsData)
        vendorKeychain.value = .data(vendorKeychainData.withoutAppMetricaUUID)
        
        let syncManager = createSyncManager(runEnv: .mainApp)
        let result = try syncManager.loadAndSyncIfNeeded()
        
        // appSettings (privateFile) has higher priority than vendorKeychain
        XCTAssertEqual(result.deviceID, appSettingsData.deviceID)
        XCTAssertEqual(result.deviceHashID, appSettingsData.deviceIDHash)
        XCTAssertEqual(result.appMetricaUUID, appSettingsData.appMetricaUUID)
    }
    
    func testExtension_AppSettingsAndVendorKeychain_DifferentData_AppSettingsWins() throws {
        let appSettingsData = IdentifiersStorageData.generateISD()
        let vendorKeychainData = IdentifiersStorageData.generateISD()
        
        appSettings.value = .data(appSettingsData)
        vendorKeychain.value = .data(vendorKeychainData.withoutAppMetricaUUID)
        
        let syncManager = createSyncManager(runEnv: .extension)
        let result = try syncManager.loadAndSyncIfNeeded()
        
        // For extension: [.groupFile, .groupKeychain, .privateFile, .privateKeychain, .vendorKeychain]
        // privateFile still has higher priority than vendorKeychain
        XCTAssertEqual(result.deviceID, appSettingsData.deviceID)
        XCTAssertEqual(result.deviceHashID, appSettingsData.deviceIDHash)
        XCTAssertEqual(result.appMetricaUUID, appSettingsData.appMetricaUUID)
    }
    
    // MARK: - MainApp: migrationData vs groupSettings (migrationData vs groupFile)
    // Priority for mainApp: [.privateFile, .privateKeychain, .migrationData, .groupFile, ...]
    // migrationData has higher priority than groupFile
    
    func testMainApp_MigrationDataAndGroupSettings_DifferentData_MigrationDataWins() throws {
        let migrationData = IdentifiersStorageData.generateISD()
        let groupSettingsData = IdentifiersStorageData.generateISD()
        
        groupSettings.value = .data(groupSettingsData)
        
        let syncManager = createSyncManager(runEnv: .mainApp)
        syncManager.appMigrationData = migrationData
        
        let result = try syncManager.loadAndSyncIfNeeded()
        
        // migrationData has higher priority than groupFile (groupSettings)
        XCTAssertEqual(result.deviceID, migrationData.deviceID)
        XCTAssertEqual(result.deviceHashID, migrationData.deviceIDHash)
        XCTAssertEqual(result.appMetricaUUID, migrationData.appMetricaUUID)
    }
    
    func testExtension_MigrationDataAndGroupSettings_DifferentData_GroupSettingsWins() throws {
        let migrationData = IdentifiersStorageData.generateISD()
        let groupSettingsData = IdentifiersStorageData.generateISD()
        
        groupSettings.value = .data(groupSettingsData)
        
        let syncManager = createSyncManager(runEnv: .extension)
        syncManager.appMigrationData = migrationData
        
        let result = try syncManager.loadAndSyncIfNeeded()
        
        // For extension, migrationData is not in the priority list, so groupFile wins
        XCTAssertEqual(result.deviceID, groupSettingsData.deviceID)
        XCTAssertEqual(result.deviceHashID, groupSettingsData.deviceIDHash)
        XCTAssertEqual(result.appMetricaUUID, groupSettingsData.appMetricaUUID)
    }
    
    // MARK: - MainApp: migrationData vs appSettings (migrationData vs privateFile)
    // Priority for mainApp: [.privateFile, .privateKeychain, .migrationData, ...]
    // privateFile has higher priority than migrationData
    
    func testMainApp_MigrationDataAndAppSettings_DifferentData_AppSettingsWins() throws {
        let migrationData = IdentifiersStorageData.generateISD()
        let appSettingsData = IdentifiersStorageData.generateISD()
        
        appSettings.value = .data(appSettingsData)
        
        let syncManager = createSyncManager(runEnv: .mainApp)
        syncManager.appMigrationData = migrationData
        
        let result = try syncManager.loadAndSyncIfNeeded()
        
        // privateFile (appSettings) has higher priority than migrationData
        XCTAssertEqual(result.deviceID, appSettingsData.deviceID)
        XCTAssertEqual(result.deviceHashID, appSettingsData.deviceIDHash)
        XCTAssertEqual(result.appMetricaUUID, appSettingsData.appMetricaUUID)
    }
    
    func testExtension_MigrationDataAndAppSettings_DifferentData_AppSettingsWins() throws {
        let migrationData = IdentifiersStorageData.generateISD()
        let appSettingsData = IdentifiersStorageData.generateISD()
        
        appSettings.value = .data(appSettingsData)
        
        let syncManager = createSyncManager(runEnv: .extension)
        syncManager.appMigrationData = migrationData
        
        let result = try syncManager.loadAndSyncIfNeeded()
        
        // For extension, migrationData is not in the priority list
        // privateFile (appSettings) is used
        XCTAssertEqual(result.deviceID, appSettingsData.deviceID)
        XCTAssertEqual(result.deviceHashID, appSettingsData.deviceIDHash)
        XCTAssertEqual(result.appMetricaUUID, appSettingsData.appMetricaUUID)
    }
    
}
