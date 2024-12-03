
import Foundation
import XCTest
@testable import AppMetricaIdentifiers

class RandomAppMetricaUUIDGeneratorTests: XCTestCase {
    
    var generator: RandomAppMetricaUUIDGenerator!
    
    override func setUp() {
        super.setUp()
        
        generator = RandomAppMetricaUUIDGenerator()
    }
    
    func testResultValue() {
        let result = generator.generateAppMetricaUUID()
        let str = result.rawValue
        
        XCTAssert(!str.isEmpty)
        XCTAssertEqual(str.count, 16*2) // uuid is 16 bytes, 2 char each byte in hexidemical repsentation
        XCTAssert(str.contains(where: { $0.isHexDigit } ))
    }
    
}
