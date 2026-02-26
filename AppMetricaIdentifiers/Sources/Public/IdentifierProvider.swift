
import Foundation
import UIKit
import AppMetricaKeychain
import AppMetricaStorageUtils
import AppMetricaSynchronization
import AppMetricaCoreUtils
import AppMetricaPlatform

@objc(AMAIdentifierProviding)
public protocol IdentifierProviding: NSObjectProtocol {
    var deviceID: String? { get }
    var deviceIDHash: String? { get }
    var appMetricaUUID: String? { get }
    
    func update(deviceID: String, deviceIDHash: String?)
    
    func updateAppMigrationData(deviceID: String, deviceIDHash: String?)
    func updateAppMigrationData(uuid: String?)
}

public let identifierErrorDomain = "io.appmetrica.identifier.error"


@objc(AMAIdentifierProviderConfiguration)
public final class IdentifierProviderConfiguration: NSObject {

    @objc
    public var privateKeychain: KeychainStoring
    @objc
    public var privateFileStorage: FileStorage

    @objc
    public var vendorKeychain: KeychainStoring?

    @objc
    public var groupKeychain: KeychainStoring?
    @objc
    public var groupFileStorage: FileStorage?

    @objc
    public var groupLockFilePath: String?

    @objc
    public init(privateKeychain: KeychainStoring, privateFileStorage: FileStorage) {
        self.privateKeychain = privateKeychain
        self.privateFileStorage = privateFileStorage
    }

}

@objc(AMAIdentifierProvider)
public final class IdentifierProvider: NSObject, IdentifierProviding {

    private let env: RunEnvironment
    
    private let identifierData = UnfairLocker<Identifiers?>(value: nil)

    @objc
    public let config: IdentifierProviderConfiguration
    
    var deviceIDGenerator: DeviceIDGenerator = IdentifierForVendorGenerator()
    var appMetricaUUIDGenerator: AppMetricaUUIDGenerator = RandomAppMetricaUUIDGenerator()
    
    private lazy var syncManager = {
        let privateKeychain = KeychainIdentifiersStorage(keychain: config.privateKeychain)
        let privateFile = JSONIdentifiersStorage(
            jsonProvider: FileStorageJSONProvider(fileStorage: config.privateFileStorage)
        )
        
        let groupKeychain = config.groupKeychain.map { KeychainIdentifiersStorage(keychain: $0) }
        let groupFile = config.groupFileStorage.map {
            let jsonProvider = FileStorageJSONProvider(fileStorage: $0)
            return JSONIdentifiersStorage(jsonProvider: jsonProvider)
        }
        
        let vendorKeychain = config.vendorKeychain.map { VendorKeychainIdentifiersStorage(keychain: $0) }

        var identifierSet = IdentifierSet<MutableIdentifiersStorable>()
        identifierSet[.privateKeychain] = privateKeychain
        identifierSet[.privateFile] = privateFile
        identifierSet[.groupKeychain] = groupKeychain
        identifierSet[.groupFile] = groupFile
        identifierSet[.vendorKeychain] = vendorKeychain

        return SyncManager(
            providers: identifierSet,
            runEnv: env,
            deviceIDGenerator: deviceIDGenerator,
            appMetricaUUIDGenerator: appMetricaUUIDGenerator
        )
    }()

    private let loadIdentifiersLock = NSLock()
    private let groupFileLock: FileLockFactory?
    
    @objc
    public init(
        config: IdentifierProviderConfiguration,
        env: RunEnvironment
    ) {
        self.config = config
        self.env = env
        self.groupFileLock = config.groupLockFilePath.map { FileLockFactory(filePath: $0) }
    }
    
    private func withFileLock<T>(_ closure: () throws -> T) rethrows -> T {
        let fl = (try? groupFileLock?.open()).flatMap { $0 }
        
        fl?.lockExclusive()
        defer { fl?.unlock() }
        
        return try closure()
    }

    @discardableResult
    private func loadIdentifiers() -> Identifiers {
        if let id = identifierData.value {
            return id
        }
        
        loadIdentifiersLock.lock()
        defer { loadIdentifiersLock.unlock() }
        
        return loadIdentifiersInternal()
    }
    
    private func loadIdentifiersInternal() -> Identifiers {
        if let id = identifierData.value {
            return id
        }
        
        let result: Identifiers
        do {
            result = try withFileLock {
                 return try syncManager.loadAndSyncIfNeeded()
            }
        } catch let e {
            logger.error("load identifiers failed: \(e)")
            logger.error(e)
            result = .init(appMetricaUUID: .defaultValue)
        }

        if result.isValid {
            identifierData.value = result
        }

        return result
    }
    
    public var identifiers: Identifiers {
        return loadIdentifiers()
    }
    
    public var deviceID: String? {
        let loadedId = loadIdentifiers()
        return loadedId.deviceID?.rawValue
    }
    
    public var deviceIDHash: String? {
        let id = loadIdentifiers()
        return id.deviceHashID?.rawValue
    }
    
    public var appMetricaUUID: String? {
        let id = loadIdentifiers()
        return id.appMetricaUUID.rawValue
    }
    
    public func update(deviceID: String, deviceIDHash: String?) {
        guard let deviceIDValue = DeviceID(rawValue: deviceID) else { return }
        let deviceIDHashValue = deviceIDHash.flatMap { DeviceIDHash(rawValue: $0) }

        loadIdentifiersLock.lock()
        defer { loadIdentifiersLock.unlock() }
        
        // this method is used in startup handling, don't use file lock due to ios kill app going to suspend with active flock
        // this method are expected to call with current DeviceID and new(maybe) DeviceIDHash
        let result: Identifiers = syncManager.update(deviceID: deviceIDValue, deviceIDHash: deviceIDHashValue)
        
        if result.isValid {
            identifierData.value = result
        }
    }
    
    private func updateMigrationData(
        currentData: IdentifiersStorageData?,
        deviceID: String?,
        deviceIDHash: String?,
        uuid: String?
    ) -> IdentifiersStorageData {
        var md = currentData ?? IdentifiersStorageData()
        
        if let d = deviceID, let did = DeviceID(rawValue: d) {
            md.deviceID = did
        }
        if deviceID != nil, let hash = deviceIDHash, let dih = DeviceIDHash(rawValue: hash) {
            md.deviceIDHash = dih
        }
        if let u = uuid, let appMetricaUUID = AppMetricaUUID(rawValue: u) {
            md.appMetricaUUID = appMetricaUUID
        }
        
        return md
    }
    
    public func updateAppMigrationData(deviceID: String, deviceIDHash: String?) {
        loadIdentifiersLock.lock()
        defer { loadIdentifiersLock.unlock() }
        
        syncManager.appMigrationData = updateMigrationData(
            currentData: syncManager.appMigrationData,
            deviceID: deviceID,
            deviceIDHash: deviceIDHash,
            uuid: nil
        )
    }
    
    public func updateAppMigrationData(uuid: String?) {
        loadIdentifiersLock.lock()
        defer { loadIdentifiersLock.unlock() }

        syncManager.appMigrationData = updateMigrationData(
            currentData: syncManager.appMigrationData,
            deviceID: nil,
            deviceIDHash: nil,
            uuid: uuid
        )
    }
    
}
