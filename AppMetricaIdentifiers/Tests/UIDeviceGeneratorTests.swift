
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
    
    func testIdentifierForVendor() {
        XCTAssertEqual(generator.generateDeviceID()?.rawValue, UIDevice.current.identifierForVendor?.uuidString)
    }
    
}
