import Foundation
import XCTest
@testable import AppMetricaIdentifiers
import AppMetricaKeychain

final class IdentifierProviderRaceTests: XCTestCase {
    
    var appKeychain: IdentifiersStorageMock!
    var appSettings: IdentifiersStorageMock!
    var groupKeychain: IdentifiersStorageMock!
    var groupSettings: IdentifiersStorageMock!

    var vendorKeychain: DuplicateSaveErrorStorage!
    
    var sourcesSet: IdentifierSet<MutableIdentifiersStorable>!
    
    var deviceIDGenerator: DeviceIDGeneratorMock!
    var appMetricaUUIDGenerator: CountingAppMetricaUUIDGeneratorMock!
    var syncManager: SyncManager!
    
    override func setUp() {
        super.setUp()
        
        deviceIDGenerator = DeviceIDGeneratorMock(deviceID: DeviceID(nonEmptyString: UUID().uuidString))
        appMetricaUUIDGenerator = CountingAppMetricaUUIDGeneratorMock()
        
        appKeychain = IdentifiersStorageMock().emulateKeychain()
        appSettings = IdentifiersStorageMock()
        groupKeychain = IdentifiersStorageMock().emulateKeychain()
        groupSettings = IdentifiersStorageMock()
        vendorKeychain = DuplicateSaveErrorStorage(
            inner: IdentifiersStorageMock().emulateKeychain()
        )
        
        sourcesSet = IdentifierSet<MutableIdentifiersStorable>()
        sourcesSet[.privateKeychain] = appKeychain
        sourcesSet[.privateFile] = appSettings
        sourcesSet[.groupKeychain] = groupKeychain
        sourcesSet[.groupFile] = groupSettings
        sourcesSet[.vendorKeychain] = vendorKeychain
        
        syncManager = SyncManager(
            providers: sourcesSet,
            runEnv: .mainApp,
            deviceIDGenerator: deviceIDGenerator,
            appMetricaUUIDGenerator: appMetricaUUIDGenerator
        )
    }
    
    /// Tighter assertion: even *after* `.needUpdate` resolves, the in-memory
    /// `syncData.identifiers.appMetricaUUID` (i.e. what subsequent `loadIfNeeded()`
    /// calls will return) must equal the value persisted on disk.
    func test_vendorDuplicate_subsequentLoadReturnsPersistedUUID() throws {
        _ = try syncManager.loadAndSyncIfNeeded()
        
        let cachedAfterSync = syncManager.loadIfNeeded()
        XCTAssertEqual(cachedAfterSync.appMetricaUUID, appSettings.value.data?.appMetricaUUID,
                       "loadIfNeeded() must return the same UUID that is persisted on disk")
        XCTAssertEqual(cachedAfterSync.appMetricaUUID, groupSettings.value.data?.appMetricaUUID,
                       "loadIfNeeded() must return the same UUID that is persisted on disk")
    }
}

// MARK: - Helpers

/// A storage wrapper whose `saveIdentifiers` always throws `KeychainError(.duplicate)`,
/// mirroring the real vendor keychain behaviour: while an existing entry is present,
/// every write attempt is rejected as a duplicate. Reads are passed through to `inner`.
final class DuplicateSaveErrorStorage: MutableIdentifiersStorable {
    private let inner: IdentifiersStorageMock
    
    init(inner: IdentifiersStorageMock) {
        self.inner = inner
    }
    
    func fetchIdentifiers() throws -> KeychainValueState<IdentifiersStorageData> {
        return try inner.fetchIdentifiers()
    }
    
    func saveIdentifiers(_ ids: IdentifiersStorageData) throws {
        throw KeychainError(.duplicate)
    }
}

/// A UUID generator that produces a fresh UUID on every call and counts calls.
/// Lets us detect "UUID regenerated for the same logical load".
final class CountingAppMetricaUUIDGeneratorMock: AppMetricaUUIDGenerator {
    private(set) var generatedCount: Int = 0
    private(set) var generatedValues: [AppMetricaUUID] = []
    
    func generateAppMetricaUUID() -> AppMetricaUUID {
        generatedCount += 1
        let value = AppMetricaUUID(nonEmptyString: UUID().uuidString.replacingOccurrences(of: "-", with: ""))
        generatedValues.append(value)
        return value
    }
}
