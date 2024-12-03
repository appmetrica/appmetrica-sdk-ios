
import AppMetricaPlatform

struct IdentifierLoaderData {
    typealias Element = KeychainValueState<IdentifiersStorageData>
    
    var identifierSet: IdentifierSet<Element>
    
    subscript(_ index: IdentifierSource) -> Element? {
        return identifierSet[index]
    }
    
    func itemsToUpdate(resultIdentifiers: IdentifiersStorageData) -> IdentifierSourceSet {
        var result = IdentifierSourceSet()
        
        for i in IdentifierSource.allCases {
            if let value = identifierSet[i], !value.isLocked {
                let resultData = i.isStoreOnlyDeviceIdentifier ? resultIdentifiers.withoutAppMetricaUUID : resultIdentifiers
                if value.isNone || (resultData != value.data && !i.isProtectedForRewriting) {
                    result.insert(i)
                }
            }
        }
        
        return result
    }
    
    @discardableResult
    mutating func updateDeviceIDHash(_ deviceIDHash: DeviceIDHash, for deviceID: DeviceID) -> IdentifierSourceSet {
        var result = IdentifierSourceSet()
        
        identifierSet = identifierSet.enumeratedMap {
            switch $1 {
            case .data(var d):
                if d.deviceID == deviceID {
                    result.insert($0)
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
        let identifierSet =  providers.map {
            do {
                return try $0.fetchIdentifiers()
            } catch let e {
                logger.error(e)
                return nil
            }
        }
        return .init(identifierSet: identifierSet)
    }
    
}
