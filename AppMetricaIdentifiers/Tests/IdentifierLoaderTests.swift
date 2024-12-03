
import Foundation
import XCTest
@testable import AppMetricaIdentifiers


final class IdentifierLoaderTests: XCTestCase {
    
    var appKeychain: IdentifiersStorageMock!
    var appSettings: IdentifiersStorageMock!
    var groupKeychain: IdentifiersStorageMock!
    var groupSettings: IdentifiersStorageMock!
    var vendorKeychain: IdentifiersStorageMock!
    
    var sourcesSet: IdentifierSet<IdentifiersStorageMock>!
    var providers: IdentifierSet<MutableIdentifiersStorable>!
    
    override func setUp() {
        super.setUp()
        
        appKeychain = IdentifiersStorageMock()
        appSettings = IdentifiersStorageMock()
        groupKeychain = IdentifiersStorageMock()
        groupSettings = IdentifiersStorageMock()
        vendorKeychain = IdentifiersStorageMock()
        
        sourcesSet = IdentifierSet<IdentifiersStorageMock>()
        sourcesSet[.privateKeychain] = appKeychain
        sourcesSet[.privateFile] = appSettings
        sourcesSet[.groupKeychain] = groupKeychain
        sourcesSet[.groupFile] = groupSettings
        sourcesSet[.vendorKeychain] = vendorKeychain
        
        providers = sourcesSet.map { $0 }
    }
    
    func testLoadAllProviers() {
        var dataSet = IdentifierSet<IdentifiersStorageData>()
        dataSet[.privateKeychain] = .generateISD().withoutAppMetricaUUID
        dataSet[.privateFile] = .generateISD()
        dataSet[.groupKeychain] = .generateISD().withoutAppMetricaUUID
        dataSet[.groupFile] = .generateISD()
        dataSet[.vendorKeychain] = .generateISD().withoutAppMetricaUUID
        
        for i in IdentifierSource.allCases {
            sourcesSet[i]!.value = .data(dataSet[i]!)
            sourcesSet[i]!.fetchExpectation = expectation(description: "Expectation for \(i)")
        }
        
        
        
        let result = IdentifierLoader.loadIdentifiers(providers: providers)
        
        wait(for: Array(sourcesSet).map { $0!.fetchExpectation! })
        XCTAssertEqual(result.identifierSet, dataSet.map { KeychainValueState(data: $0) })
    }
    
    func testErrors() {
        var dataSet = IdentifierSet<IdentifiersStorageData>()
        dataSet[.privateKeychain] = .generateISD().withoutAppMetricaUUID
        dataSet[.privateFile] = .generateISD()
        dataSet[.groupKeychain] = .generateISD().withoutAppMetricaUUID
        dataSet[.groupFile] = .generateISD()
        dataSet[.vendorKeychain] = .generateISD().withoutAppMetricaUUID
        
        for i in IdentifierSource.allCases {
            sourcesSet[i]!.fetchError = IdentifierStorageError.underlying(CustomError())
            sourcesSet[i]!.fetchExpectation = expectation(description: "Expectation for \(i)")
        }
        
        let result = IdentifierLoader.loadIdentifiers(providers: providers)
        
        wait(for: Array(sourcesSet).map { $0!.fetchExpectation! })
        
        XCTAssertEqual(result.identifierSet.filledSources.count, 0)
    }
    
    func testLocked() {
        var dataSet = IdentifierSet<KeychainValueState<IdentifiersStorageData>>()
        dataSet[.privateKeychain] = .locked
        dataSet[.privateFile] = .data(.generateISD())
        dataSet[.groupKeychain] = .locked
        dataSet[.groupFile] = .data(.generateISD())
        dataSet[.vendorKeychain] = .locked
        
        for i in IdentifierSource.allCases {
            sourcesSet[i]!.value = dataSet[i]!
            sourcesSet[i]!.fetchExpectation = expectation(description: "Expectation for \(i)")
        }
        
        let result = IdentifierLoader.loadIdentifiers(providers: providers)
        
        wait(for: Array(sourcesSet).compactMap { $0!.fetchExpectation })
        
        XCTAssertEqual(result.identifierSet[.privateKeychain], KeychainValueState.locked)
        XCTAssertEqual(result.identifierSet[.groupKeychain], KeychainValueState.locked)
        XCTAssertEqual(result.identifierSet[.vendorKeychain], KeychainValueState.locked)
        XCTAssertEqual(result.identifierSet[.privateFile], dataSet[.privateFile]!)
        XCTAssertEqual(result.identifierSet[.groupFile], dataSet[.groupFile]!)
        
    }
    
}
