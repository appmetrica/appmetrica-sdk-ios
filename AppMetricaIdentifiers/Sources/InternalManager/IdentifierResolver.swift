import Foundation
import AppMetricaPlatform

struct IdentifierResolverResult {
    var resultDeviceID: DeviceID?
    var resultDeviceIDHash: DeviceIDHash?
    var resultAppMetricaUUID: AppMetricaUUID?
    
    var sourcesToUpdate: IdentifierSourceSet = []
    
    var loadedIdentifiers: IdentifiersStorageData {
        return IdentifiersStorageData(
            deviceID: resultDeviceID,
            deviceIDHash: resultDeviceIDHash,
            appMetricaUUID: resultAppMetricaUUID
        )
    }
    
}

enum IdentifierResolver {
    
    static func isAllowedToRewrite(source: IdentifierSource) -> Bool {
        !IdentifierSource.sourcesWithProtectedRewriting.contains(source)
    }
    
    private static func populateDeviceIdentifiers(
        from data: IdentifiersStorageData,
        source: IdentifierSource,
        result: inout IdentifierResolverResult
    ) {
        if let resultDeviceID = result.resultDeviceID {
            if resultDeviceID != data.deviceID, isAllowedToRewrite(source: source) {
                result.sourcesToUpdate.insert(source)
            }
        } else {
            if let newDeviceID = data.deviceID {
                result.resultDeviceID = newDeviceID
                result.resultDeviceIDHash = data.deviceIDHash
            } else {
                result.sourcesToUpdate.insert(source)
            }
        }
    }
    
    private static func populateDeviceHashIdentifers(
        from data: IdentifiersStorageData,
        source: IdentifierSource,
        result: inout IdentifierResolverResult
    ) {
        if let resultDeviceID = result.resultDeviceID, let resultDeviceIDHash = result.resultDeviceIDHash {
            if resultDeviceID != data.deviceID || resultDeviceIDHash != data.deviceIDHash,
                isAllowedToRewrite(source: source) {
                result.sourcesToUpdate.insert(source)
            }
        } else {
            if result.resultDeviceID == data.deviceID {
                result.resultDeviceIDHash = data.deviceIDHash
            } else {
                result.sourcesToUpdate.insert(source)
            }
        }
    }
    
    private static func populateUUID(
        from data: IdentifiersStorageData,
        source: IdentifierSource,
        result: inout IdentifierResolverResult
    ) {
        if let resultAppMetricaUUID = result.resultAppMetricaUUID {
            if resultAppMetricaUUID != data.appMetricaUUID, isAllowedToRewrite(source: source),
                !source.isStoreOnlyDeviceIdentifier {
                result.sourcesToUpdate.insert(source)
            }
        } else {
            if let newAppMetricaUUID = data.appMetricaUUID {
                result.resultAppMetricaUUID = newAppMetricaUUID
            }
        }
    }
    
    static func resolve(
        runEnvionment: RunEnvironment,
        input: IdentifierSet<KeychainValueState<IdentifiersStorageData>>
    ) -> IdentifierResolverResult {
        
        var result = IdentifierResolverResult()
        
        for priority in runEnvionment.priorities {
            
            if let value = input[priority] {
                switch value {
                case .data(let data):
                    populateDeviceIdentifiers(from: data, source: priority, result: &result)
                    populateDeviceHashIdentifers(from: data, source: priority, result: &result)
                    populateUUID(from: data, source: priority, result: &result)
                case .none, .locked:
                    result.sourcesToUpdate.insert(priority)
                }
            }
        }

        return result
    }
    
}
