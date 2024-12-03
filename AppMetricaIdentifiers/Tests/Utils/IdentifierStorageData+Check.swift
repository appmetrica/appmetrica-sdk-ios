
import Foundation
import XCTest
@testable import AppMetricaIdentifiers

func checkISD(idSet: IdentifierSet<IdentifiersStorageMock>, isd: IdentifiersStorageData, sources: IdentifierSourceSet = IdentifierSource.allSet) {
    
    for i in sources {
        if let provider = idSet[i] {
            if provider.storeAppMetricaUUID {
                XCTAssertEqual(provider.value.data, isd)
            } else {
                XCTAssertEqual(provider.value.data, isd.withoutAppMetricaUUID)
            }
        }
    }
}
