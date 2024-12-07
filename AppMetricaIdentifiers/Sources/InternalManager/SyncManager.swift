
import AppMetricaPlatform

enum SyncManagerError: Error {
    case writingIdentifiers(Error?)
    case underlying(Error)
}

private struct IdentifiersSyncData {
    var identifiers: Identifiers
    var sourcesToUpdate: IdentifierSourceSet
    
    var shouldUpdate: Bool {
        return !sourcesToUpdate.isEmpty
    }
    
    var storageData: IdentifiersStorageData {
        return .init(
            deviceID: identifiers.deviceID,
            deviceIDHash: identifiers.deviceHashID,
            appMetricaUUID: identifiers.appMetricaUUID
        )
    }
}

final class SyncManager {
    let providers: IdentifierSet<MutableIdentifiersStorable>
    
    let runEnv: RunEnvironment
    
    let appDatabase: IdentifiersStorable?
    
    let deviceIDGenerator: DeviceIDGenerator
    let appMetricaUUIDGenerator: AppMetricaUUIDGenerator
    
    private var syncData: IdentifiersSyncData?
    
    init(
        providers: IdentifierSet<MutableIdentifiersStorable>, 
        runEnv: RunEnvironment,
        appDatabase: IdentifiersStorable?,
        deviceIDGenerator: DeviceIDGenerator,
        appMetricaUUIDGenerator: AppMetricaUUIDGenerator
    ) {
        self.providers = providers
        self.runEnv = runEnv
        self.appDatabase = appDatabase
        self.deviceIDGenerator = deviceIDGenerator
        self.appMetricaUUIDGenerator = appMetricaUUIDGenerator
    }
    
}

extension SyncManager {
    
    func loadAndSyncIfNeeded() throws -> Identifiers {
        let syncData = internalLoadIfNeeded()
        guard syncData.shouldUpdate else { return syncData.identifiers }
        let newSyncData = try sync(input: syncData)
        return newSyncData
    }
    
}

extension SyncManager {
    
    func loadIfNeeded() -> Identifiers {
        internalLoadIfNeeded().identifiers
    }
    
    func updateDeviceID(_ deviceID: DeviceID) -> Identifiers {
        var syncData = internalLoadIfNeeded()
        syncData.identifiers.deviceID = deviceID
        
        do {
            try IdentifierUpdater.updateIdentifiers(
                providers: providers,
                id: syncData.storageData,
                sourcesToUpdate: IdentifierSource.deviceIDSources,
                handleVendorError: false
            )
            self.syncData = syncData
        } catch let e {
            logger.error(e)
        }
        
        return syncData.identifiers
    }
    
    func updateDeviceIDHash(_ deviceIDHash: DeviceIDHash, for deviceID: DeviceID) -> Identifiers {
        var ids = IdentifierLoader.loadIdentifiers(providers: providers)
        let modifiedSources = ids.updateDeviceIDHash(deviceIDHash, for: deviceID)
        
        for i in modifiedSources {
            let val = ids[i]
            switch val {
            case .data(let d):
                do {
                    try providers[i]?.saveIdentifiers(d)
                } catch let e {
                    logger.error(e)
                }
            default:
                break
            }
        }
        
        return internalLoad().identifiers
    }
    
    func updateAppMetricaUUID(_ appMetricaUUID: AppMetricaUUID?) -> Identifiers {
        var syncData = internalLoadIfNeeded()
        syncData.identifiers.appMetricaUUID = appMetricaUUID ?? .defaultValue
        
        do {
            try IdentifierUpdater.updateIdentifiers(
                providers: providers,
                id: syncData.storageData,
                sourcesToUpdate: IdentifierSource.appMetricaUUIDSources,
                handleVendorError: false
            )
            self.syncData = syncData
        } catch let e {
            logger.error(e)
        }
        
        return syncData.identifiers
    }
    
}

private extension SyncManager {
    
    func internalLoadIfNeeded() -> IdentifiersSyncData {
        if let syncData = syncData, syncData.identifiers.isValid {
            return syncData
        } else {
            return internalLoad()
        }
    }
    
    @discardableResult
    func internalLoad() -> IdentifiersSyncData {
        let ids = IdentifierLoader.loadIdentifiers(providers: providers)
        var result = IdentifierResolver.resolve(runEnvionment: runEnv, input: ids.identifierSet)
        
        var appDatabaseMigrationCachedData: IdentifiersStorageData?
        func fetchDatabaseProvider() -> IdentifiersStorageData? {
            if let cachedData = appDatabaseMigrationCachedData {
                return cachedData
            }
            do {
                appDatabaseMigrationCachedData = try appDatabase?.fetchIdentifiers().data
            } catch let e {
                logger.error(e)
            }
            return appDatabaseMigrationCachedData
        }
        
        let rUUID: AppMetricaUUID
        
        //TODO: https://nda.ya.ru/t/lb6gBoj_7AACua
        if result.resultDeviceID == nil {
            result.resultDeviceID = fetchDatabaseProvider()?.deviceID
            result.resultDeviceIDHash = fetchDatabaseProvider()?.deviceIDHash
            result.sourcesToUpdate.formUnion(IdentifierSource.deviceIDSources)
        }
        
        if result.resultDeviceID == nil {
            result.resultDeviceID = deviceIDGenerator.generateDeviceID()
            result.resultDeviceIDHash = nil
            result.sourcesToUpdate.formUnion(IdentifierSource.deviceIDSources)
        }
        
        if let rAppMetricaUUID = result.resultAppMetricaUUID {
            rUUID = rAppMetricaUUID
        } else {
            rUUID = appMetricaUUIDGenerator.generateAppMetricaUUID()
            result.resultAppMetricaUUID = rUUID
            result.sourcesToUpdate.formUnion(IdentifierSource.appMetricaUUIDSources)
        }
        
        let identifierData = Identifiers(
            deviceID: result.resultDeviceID,
            deviceHashID: result.resultDeviceIDHash,
            appMetricaUUID: rUUID
        )
        let syncData = IdentifiersSyncData(
            identifiers: identifierData,
            sourcesToUpdate: result.sourcesToUpdate
        )
        
        self.syncData = syncData
        
        return syncData
    }
    
    func sync(input: IdentifiersSyncData) throws -> Identifiers {
        var syncData = input
        
        enum UpdateResult {
            case success
            case failed(IdentifierUpdateError)
            case needUpdate
        }
        
        func update(result: IdentifiersSyncData, handleVendorError: Bool) -> UpdateResult {
            do {
                try IdentifierUpdater.updateIdentifiers(
                    providers: providers,
                    id: result.storageData,
                    sourcesToUpdate: result.sourcesToUpdate,
                    handleVendorError: handleVendorError
                )
            } catch let e as IdentifierUpdateError {
                switch e {
                case .vendorDuplicate:
                    return .needUpdate
                default:
                    return .failed(e)
                }
            } catch let e {
                logger.error(e)
            }
            return .success
        }
        
        var resultData: Identifiers
        switch update(result: syncData, handleVendorError: true) {
        case .success:
            syncData.sourcesToUpdate = []
            self.syncData = syncData
            resultData = syncData.identifiers
        case .failed(let err):
            throw SyncManagerError.writingIdentifiers(err)
        case .needUpdate:
            
            let new = internalLoad()
            // this update must write identifier in any cases or they will be lost, so just ignore if vendor keychain throws error
            let newUpdateResult = update(result: new, handleVendorError: false)
            switch newUpdateResult {
            case .success:
                self.syncData = new
                resultData = new.identifiers
            case .failed(let e):
                throw SyncManagerError.writingIdentifiers(e)
            case .needUpdate:
                throw SyncManagerError.writingIdentifiers(IdentifierUpdateError.vendorDuplicate)
            }
            
        }
        
        return resultData
    }
}
