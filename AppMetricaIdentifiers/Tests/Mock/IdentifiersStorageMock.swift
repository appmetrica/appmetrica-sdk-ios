import Foundation
import XCTest
@testable import AppMetricaIdentifiers

final class IdentifiersStorageMock: MutableIdentifiersStorable {
    
    var value: KeychainValueState<IdentifiersStorageData> = .none
    var fetchError: Error?
    var fetchExpectation: XCTestExpectation?
    
    var saveError: Error?
    var saveExpectation: XCTestExpectation?
    
    var storeAppMetricaUUID: Bool = true
    
    func fetchIdentifiers() throws -> KeychainValueState<IdentifiersStorageData> {
        fetchExpectation?.fulfill()
        if let fetchError = fetchError {
            throw fetchError
        }
        return value
    }
    
    func saveIdentifiers(_ ids: IdentifiersStorageData) throws {
        saveExpectation?.fulfill()
        if let saveError = saveError {
            throw saveError
        }
        if storeAppMetricaUUID {
            value = .data(ids)
        } else {
            value = .data(ids.withoutAppMetricaUUID)
        }
    }
    
    func emulateKeychain() -> Self {
        self.storeAppMetricaUUID = false
        return self
    }
    
}
