
import Foundation
import XCTest
@testable import AppMetricaIdentifiers
import AppMetricaKeychain

final class IdentifierUpdaterTests: XCTestCase {
    
    var appKeychain: IdentifiersStorageMock!
    var appSettings: IdentifiersStorageMock!
    var groupKeychain: IdentifiersStorageMock!
    var groupSettings: IdentifiersStorageMock!
    var vendorKeychain: IdentifiersStorageMock!
    
    var sourcesSet: IdentifierSet<IdentifiersStorageMock>!
    var providerSet: IdentifierSet<MutableIdentifiersStorable>!
    
    override func setUp() {
        super.setUp()
        
        appKeychain = IdentifiersStorageMock()
        appSettings = IdentifiersStorageMock()
        groupKeychain = IdentifiersStorageMock()
        groupSettings = IdentifiersStorageMock()
        vendorKeychain = IdentifiersStorageMock()
        
    }
    
    private func createSourceSet() {
        sourcesSet = IdentifierSet()
        
        sourcesSet[.privateKeychain] = appKeychain
        sourcesSet[.privateFile] = appSettings
        sourcesSet[.groupKeychain] = groupKeychain
        sourcesSet[.groupFile] = groupSettings
        sourcesSet[.vendorKeychain] = vendorKeychain
        
        providerSet = sourcesSet.map { $0 }
    }
    
    private func createAppOnlySourceSet() {
        sourcesSet = IdentifierSet()
        
        sourcesSet[.privateKeychain] = appKeychain
        sourcesSet[.privateFile] = appSettings
        sourcesSet[.vendorKeychain] = vendorKeychain
        
        providerSet = sourcesSet.map { $0 }
    }
    
    func testSaveToAllSources() throws {
        createSourceSet()
        
        for i in IdentifierSource.allCases {
            sourcesSet[i]?.saveExpectation = expectation(description: "Expectation \(i)")
        }

        let lid = IdentifiersStorageData.generateISD()
        
        try IdentifierUpdater.updateIdentifiers(
            providers: providerSet, 
            id: lid,
            sourcesToUpdate: IdentifierSource.allSet,
            handleVendorError: true
        )
        
        wait(for: Array(sourcesSet).compactMap { $0?.saveExpectation })
        
        sourcesSet.actualSet.forEach {
            XCTAssertEqual($0?.value.data, lid)
        }
    }
    
    func testSaveFailedForAllSources() {
        createSourceSet()
        
        for i in IdentifierSource.allCases {
            sourcesSet[i]?.saveExpectation = expectation(description: "Expectation \(i)")
            sourcesSet[i]?.saveError = CustomError()
        }
        
        let lid = IdentifiersStorageData.generateISD()
        
        func updateIndentifiers() throws {
            try IdentifierUpdater.updateIdentifiers(
                providers: providerSet,
                id: lid,
                sourcesToUpdate: IdentifierSource.allActualSet,
                handleVendorError: true
            )
        }
        
        XCTAssertThrowsError(try updateIndentifiers()) {
            if let err = $0 as? IdentifierUpdateError, case .writingToAllStorage = err {
                return
            }
            XCTAssert(false)
        }
        
        wait(for: Array(sourcesSet).compactMap { $0?.saveExpectation })
        for i in IdentifierSource.allCases {
            XCTAssertNil(sourcesSet[i]?.value.data)
        }
    }
    
    func testSaveFailedForVendor() {
        createSourceSet()
        
        for i in IdentifierSource.allSet.subtracting([.vendorKeychain]) {
            sourcesSet[i]?.saveExpectation = expectation(description: "Expectation \(i)")
            sourcesSet[i]?.saveExpectation?.isInverted = true
        }
        vendorKeychain.saveExpectation = expectation(description: "Vendor expectation")
        vendorKeychain.saveError = KeychainError(.duplicate)
        
        let lid = IdentifiersStorageData.generateISD()
        
        XCTAssertThrowsError(try IdentifierUpdater.updateIdentifiers(providers: providerSet, id: lid, sourcesToUpdate: IdentifierSource.allSet, handleVendorError: true)) {
            if let err = $0 as? IdentifierUpdateError, case .vendorDuplicate = err {
                return
            }
            XCTAssert(false)
        }
        
        wait(for: Array(sourcesSet).compactMap { $0?.saveExpectation }, timeout: 1)
        for i in IdentifierSource.allSet {
            XCTAssertNil(sourcesSet[i]?.value.data)
        }
    }
    
    func testSavePartial() {
        createSourceSet()
        
        let itemsToSave: IdentifierSourceSet = [.privateKeychain, .groupKeychain]
        let itemsDontTouch = IdentifierSource.allSet.subtracting(itemsToSave)
        
        for i in itemsToSave {
            sourcesSet[i]?.saveExpectation = expectation(description: "Expectation \(i)")
        }
        for i in itemsDontTouch {
            sourcesSet[i]?.saveExpectation = expectation(description: "Expectation \(i)")
            sourcesSet[i]?.saveExpectation?.isInverted = true
        }
        
        let lid = IdentifiersStorageData.generateISD()
        
        XCTAssertNoThrow(try IdentifierUpdater.updateIdentifiers(providers: providerSet, id: lid, sourcesToUpdate: itemsToSave, handleVendorError: true))
        
        wait(for: Array(sourcesSet).compactMap { $0?.saveExpectation }, timeout: 1)
        for i in itemsToSave {
            XCTAssertEqual(sourcesSet[i]?.value.data, lid)
        }
        for i in itemsDontTouch {
            XCTAssertNil(sourcesSet[i]?.value.data)
        }
    }
    
}
