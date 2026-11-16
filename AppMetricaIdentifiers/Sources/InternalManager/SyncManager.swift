
import AppMetricaPlatform

enum SyncManagerError: Error {
    case identifiersUnavailable
    case writingIdentifiers(Error?)
    case underlying(Error)
}

private struct IdentifiersSyncData {
    var identifiers: Identifiers
    var sourcesToUpdate: IdentifierSourceSet
    var persistedIdentifiers: IdentifierSet<IdentifiersStorageData>
    
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
    
    let deviceIDGenerator: DeviceIDGenerator
    let appMetricaUUIDGenerator: AppMetricaUUIDGenerator
    
    private var syncData: IdentifiersSyncData?
    
    var appMigrationData: IdentifiersStorageData?
    
    init(
        providers: IdentifierSet<MutableIdentifiersStorable>, 
        runEnv: RunEnvironment,
        deviceIDGenerator: DeviceIDGenerator,
        appMetricaUUIDGenerator: AppMetricaUUIDGenerator
    ) {
        self.providers = providers
        self.runEnv = runEnv
        self.deviceIDGenerator = deviceIDGenerator
        self.appMetricaUUIDGenerator = appMetricaUUIDGenerator
    }
    
}

extension SyncManager {
    
    func loadAndSyncIfNeeded() throws -> Identifiers {
        do {
            let syncData = try internalLoadIfNeeded()
            guard syncData.shouldUpdate else { return syncData.identifiers }
            return try sync(input: syncData)
        } catch {
            // A retry must read the original identifiers after storage access recovers.
            self.syncData = nil
            throw error
        }
    }
    
}

extension SyncManager {
    
    func loadIfNeeded() throws -> Identifiers {
        try internalLoadIfNeeded().identifiers
    }
    
    func update(deviceID: DeviceID, deviceIDHash: DeviceIDHash?) throws -> Identifiers {
        
        self.syncData = nil
        var ids = IdentifierLoader.loadIdentifiers(providers: providers)
        guard !ids.hasUnavailableSources else { throw SyncManagerError.identifiersUnavailable }
        let modifiedSources: IdentifierSourceSet = ids.update(deviceID: deviceID, deviceIDHash: deviceIDHash)
        
        for i in modifiedSources {
            let val = ids[i]
            switch val {
            case .data(let d):
                do {
                    try providers[i]?.saveIdentifiers(d)
                } catch IdentifierStorageError.deviceIDMismatch where i.isProtectedForRewriting {
                    // The vendor identifier cannot be replaced by a startup response.
                    continue
                } catch let e {
                    throw SyncManagerError.writingIdentifiers(e)
                }
            default:
                break
            }
        }
        
        return try internalLoad().identifiers
        
    }
    
}

private extension SyncManager {
    
    func internalLoadIfNeeded() throws -> IdentifiersSyncData {
        if let syncData = syncData, syncData.identifiers.isValid {
            return syncData
        } else {
            return try internalLoad()
        }
    }
    
    @discardableResult
    func internalLoad() throws -> IdentifiersSyncData {
        let ids = IdentifierLoader.loadIdentifiers(providers: providers)
        guard !ids.hasUnavailableSources else { throw SyncManagerError.identifiersUnavailable }
        var idsData = ids.identifierSet
        if let appIdentifiersData = appMigrationData {
            idsData[.migrationData] = .data(appIdentifiersData)
        }
        var result = IdentifierResolver.resolve(runEnvionment: runEnv, input: idsData)
        if !ids.corruptedSources.isEmpty {
            // Recover a corrupted copy only from existing identifiers.
            guard result.resultDeviceID != nil, result.resultAppMetricaUUID != nil else {
                throw SyncManagerError.identifiersUnavailable
            }
            result.sourcesToUpdate.formUnion(ids.corruptedSources)
        }
        
        let rUUID: AppMetricaUUID
        
        //TODO: https://nda.ya.ru/t/lb6gBoj_7AACua
        if result.resultDeviceID == nil {
            result.resultDeviceID = deviceIDGenerator.generateDeviceID()
            result.resultDeviceIDHash = nil
            result.sourcesToUpdate.formUnion(IdentifierSource.deviceIDSources)
        }
        
        guard result.resultDeviceID != nil else { throw SyncManagerError.identifiersUnavailable }

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
            sourcesToUpdate: result.sourcesToUpdate,
            persistedIdentifiers: ids.identifierSet.map { $0.data }
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
                    handleVendorError: handleVendorError,
                    persistedIdentifiers: result.persistedIdentifiers
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
            
            let new = try internalLoad()
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
