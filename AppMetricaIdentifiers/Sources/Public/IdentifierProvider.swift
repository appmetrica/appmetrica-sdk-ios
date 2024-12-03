
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
    func updateDeviceID(_ deviceID: String)
    func updateDeviceIdHash(_ deviceHashID: String)
    func updateAppMetricaUUID(_ uuid: String?)
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
    public var appDatabase: KeyValueStoring?

    @objc
    public var uuidMigration: AppMetricaUUIDMigratable?

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
        
        let appDatabase = config.appDatabase.map { ReadOnlyKeyValueIdentifiersStorage(storage: $0, prefix: "fallback-keychain-") }

        return SyncManager(
            providers: identifierSet,
            runEnv: env,
            appDatabase: appDatabase,
            appMetricaUUIDMigration: config.uuidMigration,
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
    
    public func updateDeviceID(_ deviceID: String) {
        loadIdentifiersLock.lock()
        defer { loadIdentifiersLock.unlock() }
        
        let result = withFileLock {
            syncManager.updateDeviceID(DeviceID(nonEmptyString: deviceID))
        }
        if result.isValid {
            identifierData.value = result
        }
    }
    
    public func updateDeviceIdHash(_ newHash: String) {
        loadIdentifiersLock.lock()
        defer { loadIdentifiersLock.unlock() }

        guard let ids = identifierData.value, let deviceID = ids.deviceID else { return }
        
        let result = withFileLock {
            syncManager.updateDeviceIDHash(DeviceIDHash(nonEmptyString: newHash), for: deviceID)
        }
        
        if result.isValid {
            identifierData.value = result
        }
    }

    public func updateAppMetricaUUID(_ uuid: String?) {
        loadIdentifiersLock.lock()
        defer { loadIdentifiersLock.unlock() }

        let result = withFileLock {
            syncManager.updateAppMetricaUUID(uuid.flatMap { AppMetricaUUID(rawValue: $0) })
        }
        if result.isValid {
            identifierData.value = result
        }
    }
    
}
