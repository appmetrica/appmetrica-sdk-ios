
import Foundation
import XCTest
@testable import AppMetricaIdentifiers

final class IdentifierResolverTests: XCTestCase {
    
    private func generateLID() -> IdentifiersStorageData {
        IdentifiersStorageData(
            deviceID: DeviceID(nonEmptyString: UUID().uuidString),
            deviceIDHash: DeviceIDHash(nonEmptyString: UUID().uuidString.replacingOccurrences(of: "-", with: "")),
            appMetricaUUID: AppMetricaUUID(nonEmptyString: UUID().uuidString)
        )
    }
    
    func testAllEquals() {
        let lid = generateLID()
        var identifierSet = IdentifierSet<KeychainValueState<IdentifiersStorageData>>()
        identifierSet[.privateKeychain] = .data(lid.withoutAppMetricaUUID)
        identifierSet[.privateFile] = .data(lid)
        identifierSet[.groupKeychain] = .data(lid.withoutAppMetricaUUID)
        identifierSet[.groupFile] = .data(lid)
        identifierSet[.vendorKeychain] = .data(lid)
        
        let result = IdentifierResolver.resolve(runEnvionment: .mainApp, input: identifierSet)
        
        XCTAssertEqual(result.resultDeviceID, lid.deviceID)
        XCTAssertEqual(result.resultDeviceIDHash, lid.deviceIDHash)
        XCTAssertEqual(result.resultAppMetricaUUID, lid.appMetricaUUID)
        XCTAssertEqual(result.sourcesToUpdate.count, 0)
    }
    
    func testDiffentIds() {
        let lid1 = generateLID()
        let lid2 = generateLID()
        
        var identifierSet = IdentifierSet<KeychainValueState<IdentifiersStorageData>>()
        identifierSet[.privateKeychain] = .data(lid1.withoutAppMetricaUUID)
        identifierSet[.privateFile] = .data(lid1)
        identifierSet[.groupKeychain] = .data(lid2.withoutAppMetricaUUID)
        identifierSet[.groupFile] = .data(lid2)
        identifierSet[.vendorKeychain] = .data(lid2)
        
        let result = IdentifierResolver.resolve(runEnvionment: .mainApp, input: identifierSet)
        
        XCTAssertEqual(result.resultDeviceID, lid1.deviceID)
        XCTAssertEqual(result.resultDeviceIDHash, lid1.deviceIDHash)
        XCTAssertEqual(result.resultAppMetricaUUID, lid1.appMetricaUUID)
        XCTAssertEqual(result.sourcesToUpdate, Set([.groupKeychain, .groupFile])) //vendor keychain should not update
    }
    
    func testMustNotUpdateVendorKeychain() {
        let lid1 = generateLID()
        let lid2 = generateLID()
        
        var identifierSet = IdentifierSet<KeychainValueState<IdentifiersStorageData>>()
        identifierSet[.privateKeychain] = .data(lid1.withoutAppMetricaUUID)
        identifierSet[.privateFile] = .data(lid1)
        identifierSet[.groupKeychain] = .data(lid1.withoutAppMetricaUUID)
        identifierSet[.groupFile] = .data(lid1)
        identifierSet[.vendorKeychain] = .data(lid2.withoutAppMetricaUUID)
        
        let result = IdentifierResolver.resolve(runEnvionment: .mainApp, input: identifierSet)
        
        XCTAssertEqual(result.resultDeviceID, lid1.deviceID)
        XCTAssertEqual(result.resultDeviceIDHash, lid1.deviceIDHash)
        XCTAssertEqual(result.resultAppMetricaUUID, lid1.appMetricaUUID)
        XCTAssertEqual(result.sourcesToUpdate.count, 0) //vendor keychain should not update
    }
    
    func testMustUpdateVendorKeychain() {
        let lid1 = generateLID()
        
        var identifierSet = IdentifierSet<KeychainValueState<IdentifiersStorageData>>()
        identifierSet[.privateKeychain] = .data(lid1.withoutAppMetricaUUID)
        identifierSet[.privateFile] = .data(lid1)
        identifierSet[.groupKeychain] = .data(lid1.withoutAppMetricaUUID)
        identifierSet[.groupFile] = .data(lid1)
        identifierSet[.vendorKeychain] = KeychainValueState.none
        
        let result = IdentifierResolver.resolve(runEnvionment: .mainApp, input: identifierSet)
        
        XCTAssertEqual(result.resultDeviceID, lid1.deviceID)
        XCTAssertEqual(result.resultDeviceIDHash, lid1.deviceIDHash)
        XCTAssertEqual(result.resultAppMetricaUUID, lid1.appMetricaUUID)
        XCTAssertEqual(result.sourcesToUpdate, Set([.vendorKeychain])) //vendor keychain should not update
    }
    
    func testMustNotUpdateIfNone() {
        let lid1 = generateLID()
        
        var identifierSet = IdentifierSet<KeychainValueState<IdentifiersStorageData>>()
        identifierSet[.privateKeychain] = .data(lid1.withoutAppMetricaUUID)
        identifierSet[.privateFile] = .data(lid1)
        identifierSet[.groupKeychain] = Optional.none
        identifierSet[.groupFile] = Optional.none
        identifierSet[.vendorKeychain] = KeychainValueState.none
        
        let result = IdentifierResolver.resolve(runEnvionment: .mainApp, input: identifierSet)
        
        XCTAssertEqual(result.resultDeviceID, lid1.deviceID)
        XCTAssertEqual(result.resultDeviceIDHash, lid1.deviceIDHash)
        XCTAssertEqual(result.resultAppMetricaUUID, lid1.appMetricaUUID)
        XCTAssertEqual(result.sourcesToUpdate, Set([.vendorKeychain])) //vendor keychain should not update
    }
    
    func testDiffentIdsForExtension() {
        let lid1 = generateLID()
        let lid2 = generateLID()
        
        var identifierSet = IdentifierSet<KeychainValueState<IdentifiersStorageData>>()
        identifierSet[.privateKeychain] = .data(lid2.withoutAppMetricaUUID)
        identifierSet[.privateFile] = .data(lid2)
        identifierSet[.groupKeychain] = .data(lid1.withoutAppMetricaUUID)
        identifierSet[.groupFile] = .data(lid1)
        identifierSet[.vendorKeychain] = .data(lid2)
        
        let result = IdentifierResolver.resolve(runEnvionment: .extension, input: identifierSet)
        
        XCTAssertEqual(result.resultDeviceID, lid1.deviceID)
        XCTAssertEqual(result.resultDeviceIDHash, lid1.deviceIDHash)
        XCTAssertEqual(result.resultAppMetricaUUID, lid1.appMetricaUUID)
        XCTAssertEqual(result.sourcesToUpdate, Set([.privateKeychain, .privateFile])) //vendor keychain should not update
    }
    
}
