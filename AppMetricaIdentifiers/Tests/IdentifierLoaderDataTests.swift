import XCTest
@testable import AppMetricaIdentifiers

final class IdentifierLoaderDataTests: XCTestCase {
    
    func testUpdate() throws {
        let lid = IdentifiersStorageData.generateISD()
        let lid2 = IdentifiersStorageData.generateISD()
        
        var dataSet = IdentifierSet<IdentifiersStorageData>()
        
        dataSet[.privateKeychain] = lid.withoutAppMetricaUUID
        dataSet[.privateFile] = lid
        dataSet[.groupKeychain] = lid.withoutAppMetricaUUID
        dataSet[.groupFile] = lid
        dataSet[.vendorKeychain] = lid.withoutAppMetricaUUID
        
        var data = IdentifierLoaderData(identifierSet: dataSet.map { .data($0) })
        data.update(deviceID: lid2.deviceID!, deviceIDHash: lid2.deviceIDHash)
        
        data.identifierSet.forEach {
            XCTAssertEqual($0?.data?.withoutAppMetricaUUID, lid2.withoutAppMetricaUUID)
        }
    }

}
