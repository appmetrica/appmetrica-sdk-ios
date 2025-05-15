import AppMetricaCore
import Foundation
import XCTest

class MockAppMetrica: AppMetrica {
    static var reportEventCalled = false
    static var lastReportedEventName: String?
    static var lastReportedEventParameters: [AnyHashable: Any]?
    static var shouldFailReporting = false
    
    static var anonymousActivationAdTrackingEnabled: Bool?
    static var anonymousActivationExpectation: XCTestExpectation = XCTestExpectation()
    
    static var setAdProviderEnabledValue: Bool?
    static var setAdProviderEnabledExpectation: XCTestExpectation = XCTestExpectation()
    
    override class func setAdProviderEnabled(_ newValue: Bool) {
        setAdProviderEnabledValue = newValue
        setAdProviderEnabledExpectation.fulfill()
    }
    
    override class func activate(adIdentifierTrackingEnabled: Bool) {
        anonymousActivationAdTrackingEnabled = adIdentifierTrackingEnabled
        anonymousActivationExpectation.fulfill()
    }

    override class func reportEvent(
        name: String, parameters params: [AnyHashable: Any]?, onFailure: ((any Error) -> Void)? = nil
    ) {
        reportEventCalled = true
        lastReportedEventName = name
        lastReportedEventParameters = params
        
        if shouldFailReporting {
            onFailure?(
                NSError(
                    domain: "MockAppMetrica", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Mock reporting failure"]))
        }
    }
    
    class override func reportLibraryAdapterAdRevenueRelatedEvent(
        name: String,
        parameters params: [AnyHashable : Any]?,
        onFailure: ((any Error) -> Void)? = nil
    ) {
        reportEventCalled = true
        lastReportedEventName = name
        lastReportedEventParameters = params
        
        if shouldFailReporting {
            onFailure?(
                NSError(
                    domain: "MockAppMetrica", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Mock reporting failure"]))
        }
    }

    static func reset() {
        anonymousActivationExpectation = XCTestExpectation(description: "Should activate anonymously via extended interface")
        anonymousActivationAdTrackingEnabled = nil
        
        setAdProviderEnabledExpectation = XCTestExpectation(description: "Should call setAdProviderEnabled")
        setAdProviderEnabledValue = nil
        
        reportEventCalled = false
        lastReportedEventName = nil
        lastReportedEventParameters = nil
        shouldFailReporting = false
    }
}
