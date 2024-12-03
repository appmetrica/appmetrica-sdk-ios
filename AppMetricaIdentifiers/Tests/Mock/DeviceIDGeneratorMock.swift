
import Foundation
import XCTest
@testable import AppMetricaIdentifiers

final class DeviceIDGeneratorMock: DeviceIDGenerator {
    
    var deviceID: DeviceID?
    var generateExpectation: XCTestExpectation?
    
    init(deviceID: DeviceID?) {
        self.deviceID = deviceID
    }
    
    func generateDeviceID() -> DeviceID? {
        generateExpectation?.fulfill()
        return deviceID
    }
    
}
