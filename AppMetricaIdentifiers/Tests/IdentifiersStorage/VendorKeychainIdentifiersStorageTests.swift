
import Foundation
import XCTest
import AppMetricaTestUtils
import AppMetricaKeychain
@testable import AppMetricaIdentifiers

class VendorKeychainIdentifiersStorageTests: XCTestCase {
    
    var keychain: KeychainMock!
    var provider: VendorKeychainIdentifiersStorage!
    
    override func setUp() {
        super.setUp()
        
        keychain = KeychainMock()
        provider = VendorKeychainIdentifiersStorage(keychain: keychain)
    }
    
    
    func testSetValue() {
        let ids = IdentifiersStorageData.generateISD().withoutAppMetricaUUID
        
        XCTAssertNoThrow(try provider.saveIdentifiers(ids))
        let expectedDict: [String: String?] = [
            IdentifiersCodingKeys.deviceID.rawValue: ids.deviceID?.rawValue,
            IdentifiersCodingKeys.deviceIDHash.rawValue: ids.deviceIDHash?.rawValue,
            IdentifiersCodingKeys.appMetricaUUID.rawValue: ids.appMetricaUUID?.rawValue
        ]
        XCTAssertEqual(keychain.storage, expectedDict.compactMapValues { $0 })
    }
    
    func testOverwriteValue() {
        let idsOld = IdentifiersStorageData.generateISD().withoutAppMetricaUUID
        let ids = IdentifiersStorageData.generateISD().withoutAppMetricaUUID
        
        keychain.storage = [
            IdentifiersCodingKeys.deviceID.rawValue: idsOld.deviceID!.rawValue,
            IdentifiersCodingKeys.deviceIDHash.rawValue: idsOld.deviceIDHash!.rawValue,
        ]
        XCTAssertThrowsError(try provider.saveIdentifiers(ids)) {
            if let err = $0 as? IdentifierStorageError, case .deviceIDMismatch = err {
                return
            }
            XCTAssert(false)
        }
        
        let expectedDict: [String: String?] = [
            IdentifiersCodingKeys.deviceID.rawValue: idsOld.deviceID?.rawValue,
            IdentifiersCodingKeys.deviceIDHash.rawValue: idsOld.deviceIDHash?.rawValue,
            IdentifiersCodingKeys.appMetricaUUID.rawValue: idsOld.appMetricaUUID?.rawValue
        ]
        XCTAssertEqual(keychain.storage, expectedDict.compactMapValues { $0 })
    }
    
    func testGetValue() throws {
        let ids = IdentifiersStorageData.generateISD().withoutAppMetricaUUID
        
        keychain.storage = [
            IdentifiersCodingKeys.deviceID.rawValue: ids.deviceID!.rawValue,
            IdentifiersCodingKeys.deviceIDHash.rawValue: ids.deviceIDHash!.rawValue,
        ]
        
        XCTAssertEqual(try provider.fetchIdentifiers().data, ids)
    }
    
    func testLocked() throws {
        keychain.isLocked = true
        
        XCTAssertEqual(try provider.fetchIdentifiers(), .locked)
    }
    
    func testNone() throws {
        XCTAssertEqual(try provider.fetchIdentifiers(), .none)
    }
    
}
