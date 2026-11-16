
import AppMetricaPlatform

struct IdentifierLoaderData {
    typealias Element = KeychainValueState<IdentifiersStorageData>
    
    var identifierSet: IdentifierSet<Element>
    var failedSources: IdentifierSourceSet = []
    var corruptedSources: IdentifierSourceSet = []

    var hasUnavailableSources: Bool {
        !failedSources.subtracting(corruptedSources).isEmpty || identifierSet.contains { $0.isLocked }
    }
    
    subscript(_ index: IdentifierSource) -> Element? {
        return identifierSet[index]
    }
    
    @discardableResult
    mutating func update(deviceID: DeviceID, deviceIDHash: DeviceIDHash?) -> IdentifierSourceSet {
        var result = IdentifierSourceSet()
        
        identifierSet = identifierSet.enumeratedMap {
            switch $1 {
            case .data(var d):
                if d.deviceID != deviceID || d.deviceIDHash != deviceIDHash {
                    result.insert($0)
                    d.deviceID = deviceID
                    d.deviceIDHash = deviceIDHash
                    return .data(d)
                }
            default:
                break
            }
            return $1
        }
        
        return result
    }
    
}

enum IdentifierLoader {
    
    static func loadIdentifiers(providers: IdentifierSet<MutableIdentifiersStorable>) -> IdentifierLoaderData {
        var failedSources = IdentifierSourceSet()
        var corruptedSources = IdentifierSourceSet()
        let identifierSet = providers.enumeratedMap { source, provider in
            do {
                return try provider.fetchIdentifiers()
            } catch let e {
                logger.error(e)
                failedSources.insert(source)
                if case IdentifierStorageError.corrupted = e {
                    corruptedSources.insert(source)
                }
                return nil
            }
        }
        return .init(identifierSet: identifierSet, failedSources: failedSources, corruptedSources: corruptedSources)
    }
    
}
