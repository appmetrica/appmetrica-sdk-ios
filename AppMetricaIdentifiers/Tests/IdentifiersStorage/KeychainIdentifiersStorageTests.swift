
import Foundation
import XCTest
import AppMetricaTestUtils
import AppMetricaKeychain
@testable import AppMetricaIdentifiers

class KeychainIdentifiersStorageTests: XCTestCase {
    
    var keychain: KeychainMock!
    var provider: KeychainIdentifiersStorage!
    
    override func setUp() {
        super.setUp()
        
        keychain = KeychainMock()
        provider = KeychainIdentifiersStorage(keychain: keychain)
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
        
        XCTAssertNoThrow(try provider.saveIdentifiers(ids))
        let expectedDict: [String: String?] = [
            IdentifiersCodingKeys.deviceID.rawValue: ids.deviceID?.rawValue,
            IdentifiersCodingKeys.deviceIDHash.rawValue: ids.deviceIDHash?.rawValue,
            IdentifiersCodingKeys.appMetricaUUID.rawValue: ids.appMetricaUUID?.rawValue
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
    
    func testRemoveDeviceIDHashValue() throws {
        let ids1 = IdentifiersStorageData.generateISD().withoutAppMetricaUUID
        var ids2 = IdentifiersStorageData.generateISD().withoutAppMetricaUUID
        ids2.deviceIDHash = nil
        ids2.appMetricaUUID = nil
        
        keychain.storage = [
            IdentifiersCodingKeys.deviceID.rawValue: ids1.deviceID!.rawValue,
            IdentifiersCodingKeys.deviceIDHash.rawValue: ids1.deviceIDHash!.rawValue,
        ]
        
        try provider.saveIdentifiers(ids2)
        XCTAssertEqual(keychain.storage, [IdentifiersCodingKeys.deviceID.rawValue: ids2.deviceID!.rawValue])
    }
    
    func testNotRemoveAllIdentifiers() throws {
        let ids1 = IdentifiersStorageData.generateISD().withoutAppMetricaUUID
        
        let storage = [
            IdentifiersCodingKeys.deviceID.rawValue: ids1.deviceID!.rawValue,
            IdentifiersCodingKeys.deviceIDHash.rawValue: ids1.deviceIDHash!.rawValue,
        ]
        
        keychain.storage = storage

        try provider.saveIdentifiers(IdentifiersStorageData())
        XCTAssertEqual(keychain.storage, storage)
    }
    
    func testLocked() throws {
        keychain.isLocked = true
        
        XCTAssertEqual(try provider.fetchIdentifiers(), .locked)
    }
    
    func testNone() throws {
        XCTAssertEqual(try provider.fetchIdentifiers(), .none)
    }
    
}
