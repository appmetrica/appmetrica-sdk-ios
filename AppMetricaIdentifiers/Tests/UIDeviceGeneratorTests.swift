
import Foundation
import UIKit
import XCTest
@testable import AppMetricaIdentifiers

final class UIDeviceGeneratorTests: XCTestCase {
    
    var generator: IdentifierForVendorGenerator!
    
    override func setUp() {
        super.setUp()
        
        generator = IdentifierForVendorGenerator()
    }
    
    @MainActor
    func testIdentifierForVendor() {
        XCTAssertEqual(generator.generateDeviceID()?.rawValue, UIDevice.current.identifierForVendor?.uuidString)
    }

    @MainActor
    func testIdentifierForVendorFromBackgroundTask() async {
        let expected = UIDevice.current.identifierForVendor?.uuidString
        let actual = await Task.detached {
            IdentifierForVendorGenerator().generateDeviceID()?.rawValue
        }.value
        XCTAssertEqual(actual, expected)
    }
    
}
