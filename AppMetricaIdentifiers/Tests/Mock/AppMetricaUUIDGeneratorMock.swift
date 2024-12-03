
import Foundation
import XCTest
@testable import AppMetricaIdentifiers

final class AppMetricaUUIDGeneratorMock: AppMetricaUUIDGenerator {
    
    var appMetricaUUID: AppMetricaUUID
    var generateAppMetricaExpectation: XCTestExpectation?
    
    init(value: AppMetricaUUID) {
        self.appMetricaUUID = value
    }
    
    func generateAppMetricaUUID() -> AppMetricaUUID {
        generateAppMetricaExpectation?.fulfill()
        return appMetricaUUID
    }
    
    
}
