
import Foundation
import XCTest
@testable import AppMetricaSynchronization

final class FileLockTests: XCTestCase {
    
    let filePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] + "/test.lock"
    
    var flockFactory1: FileLockFactory!
    var flockFactory2: FileLockFactory!
    
    override func setUp() {
        super.setUp()
        
        flockFactory1 = FileLockFactory(filePath: filePath)
        flockFactory2 = FileLockFactory(filePath: filePath)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testBlockExclusive() throws {
        let flock1 = try flockFactory1.open()
        let flock2 = try flockFactory2.open()
        
        flock1.lockExclusive()
        XCTAssertFalse(flock2.tryLockExculusive())
        flock1.unlock()
        
        flock2.lockExclusive()
        XCTAssertFalse(flock1.tryLockExculusive())
        flock2.unlock()
    }
    
    func testSharedBlock() throws {
        let flock1 = try flockFactory1.open()
        let flock2 = try flockFactory2.open()
        
        flock1.lockShared()
        XCTAssertFalse(flock2.tryLockExculusive())
        XCTAssertTrue(flock2.tryLockShared())
        
        flock1.unlock()
        flock2.unlock()
    }
    
    func testSharedExclusiveBlock() throws {
        let flock1 = try flockFactory1.open()
        let flock2 = try flockFactory2.open()
        
        flock1.lockShared()
        flock1.lockExclusive()
        
        XCTAssertFalse(flock2.tryLockShared())
        XCTAssertFalse(flock2.tryLockExculusive())
        
        flock1.unlock()
    }
    
}


