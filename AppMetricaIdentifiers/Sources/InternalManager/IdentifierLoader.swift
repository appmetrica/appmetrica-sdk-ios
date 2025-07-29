
import AppMetricaPlatform

struct IdentifierLoaderData {
    typealias Element = KeychainValueState<IdentifiersStorageData>
    
    var identifierSet: IdentifierSet<Element>
    
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
