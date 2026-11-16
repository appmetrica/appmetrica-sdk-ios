
import AppMetricaKeychain

enum IdentifierUpdateError: Error {
    case vendorDuplicate
    case writingToAllStorage(Set<IdentifierType>, [Error])
}

enum IdentifierUpdater {
    
    static func updateIdentifiers(
        providers: IdentifierSet<MutableIdentifiersStorable>,
        id: IdentifiersStorageData,
        sourcesToUpdate: IdentifierSourceSet,
        handleVendorError: Bool,
        persistedIdentifiers: IdentifierSet<IdentifiersStorageData> = .init()
    ) throws {
        guard !sourcesToUpdate.isEmpty else { return }
        
        let attemptedSources = sourcesToUpdate.intersection(providers.filledSources)
        var items = attemptedSources
        
        var deviceErrors: [Error] = []
        var uuidErrors: [Error] = []
        
        
        if handleVendorError, items.contains(.vendorKeychain), let vendorKeychain = providers.vendorKeychain {
            do {
                try vendorKeychain.saveIdentifiers(id)
            } catch let e as KeychainError {
                switch e.code {
                case .duplicate:
                    throw IdentifierUpdateError.vendorDuplicate
                default:
                    deviceErrors.append(e)
                }
            } catch let e {
                deviceErrors.append(e)
                
            }
            items.remove(.vendorKeychain)
        }
        
        items.forEach {
            do {
                try providers[$0]?.saveIdentifiers(id)
            } catch let e {
                if IdentifierType.device.allowedStorages.contains($0) {
                    deviceErrors.append(e)
                }
                if IdentifierType.uuid.allowedStorages.contains($0) {
                    uuidErrors.append(e)
                }
            }
        }
        
        // Failure to write an additional copy does not invalidate already persisted values.
        var persistedTypes: Set<IdentifierType> = []
        let unchangedSources = providers.filledSources.subtracting(attemptedSources)
        for source in unchangedSources {
            guard let stored = persistedIdentifiers[source] else { continue }
            if IdentifierType.device.allowedStorages.contains(source),
               let deviceID = stored.deviceID, deviceID == id.deviceID,
               stored.deviceIDHash == id.deviceIDHash {
                persistedTypes.insert(.device)
            }
            if IdentifierType.uuid.allowedStorages.contains(source),
               let uuid = stored.appMetricaUUID, uuid == id.appMetricaUUID {
                persistedTypes.insert(.uuid)
            }
        }

        var writingErrorTypes: Set<IdentifierType> = []
        if deviceErrors.count > 0 && attemptedSources.intersection(IdentifierType.device.allowedStorages).count == deviceErrors.count {
            writingErrorTypes.insert(.device)
        }
        if uuidErrors.count > 0 && attemptedSources.intersection(IdentifierType.uuid.allowedStorages).count == uuidErrors.count {
            writingErrorTypes.insert(.uuid)
        }
        
        writingErrorTypes.subtract(persistedTypes)
        if !writingErrorTypes.isEmpty {
            throw IdentifierUpdateError.writingToAllStorage(writingErrorTypes, deviceErrors + uuidErrors)
        }
    }
    
    
    
}
