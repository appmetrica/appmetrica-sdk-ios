
import Foundation
import XCTest
import AppMetricaTestUtils
@testable import AppMetricaIdentifiers

final class ReadOnlyKeyValueIdentifiersStorageTests: XCTestCase {
    
    var kvMock: KeyValueStorageMock!
    var storage: ReadOnlyKeyValueIdentifiersStorage!
    
    let prefix = "test-prefix-"
    
    override func setUp() {
        super.setUp()
        
        kvMock = KeyValueStorageMock()
        storage = ReadOnlyKeyValueIdentifiersStorage(storage: kvMock, prefix: prefix)
    }
    
    func testFetchIdentifiers() throws {
        let newId = IdentifiersStorageData.generateISD().withoutAppMetricaUUID
        
        kvMock.storage = [
            "\(prefix)AMAMetricaPersistentConfigurationDeviceIDStorageKey": newId.deviceID!.rawValue,
            "\(prefix)AMAMetricaPersistentConfigurationDeviceIDHashStorageKey": newId.deviceIDHash!.rawValue,
        ]
        
        let loadedId = try storage.fetchIdentifiers()
        XCTAssertEqual(newId, loadedId.data)
    }
    
    func testFetchIdentifiersIfStorageIsEmpty() throws {
        let loadedId = try storage.fetchIdentifiers()
        XCTAssert(loadedId.isNone)
    }
    
    func testFetchIdentifiersIfStorageThrowError() {
        kvMock.error = CustomError()
        
        XCTAssertThrowsError(try storage.fetchIdentifiers())
    }
    
}
