
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
        handleVendorError: Bool
    ) throws {
        guard !sourcesToUpdate.isEmpty else { return }
        
        var items = sourcesToUpdate.intersection(providers.filledSources)
        
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
        
        var writingErrorTypes: Set<IdentifierType> = []
        if deviceErrors.count > 0 && sourcesToUpdate.union(IdentifierType.device.allowedStorages).count == deviceErrors.count {
            writingErrorTypes.insert(.device)
        }
        if uuidErrors.count > 0 && sourcesToUpdate.union(IdentifierType.uuid.allowedStorages).count == uuidErrors.count {
            writingErrorTypes.insert(.uuid)
        }
        
        if !writingErrorTypes.isEmpty {
            throw IdentifierUpdateError.writingToAllStorage(writingErrorTypes, deviceErrors + uuidErrors)
        }
    }
    
    
    
}
