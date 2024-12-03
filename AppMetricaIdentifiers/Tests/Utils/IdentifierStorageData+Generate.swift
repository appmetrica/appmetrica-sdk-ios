
import Foundation
@testable import AppMetricaIdentifiers

extension IdentifiersStorageData {
    
    static func generateISD() -> IdentifiersStorageData {
        IdentifiersStorageData(
            deviceID: DeviceID(nonEmptyString: UUID().uuidString),
            deviceIDHash: DeviceIDHash(nonEmptyString: UUID().uuidString.replacingOccurrences(of: "-", with: "")),
            appMetricaUUID: AppMetricaUUID(nonEmptyString: UUID().uuidString)
        )
    }
    
}
