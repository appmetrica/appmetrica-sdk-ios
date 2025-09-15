import AppMetricaCore
import AppMetricaCoreExtension
import Foundation
import XCTest

class MockAppMetrica: AppMetrica {
    static var reportEventCalled = false
    static var lastReportedEventName: String?
    static var lastReportedEventParameters: [AnyHashable: Any]?
    static var shouldFailReporting = false
    
    static var anonymousConfiguration: AppMetricaConfiguration?
    static var anonymousActivationExpectation: XCTestExpectation = XCTestExpectation()
    
    static var libraryAdapterConfiguration: AppMetricaLibraryAdapterConfiguration?
    static var setupLibraryAdapterConfigurationExpectation: XCTestExpectation = XCTestExpectation()
    
    static var locationTrackingEnabledValue: Bool?
    static var locationTrackingEnabledExpectation: XCTestExpectation = XCTestExpectation()
    
    static var advertisingIdentifierTrackingEnabledValue: Bool?
    static var advertisingIdentifierTrackingEnabledExpectation: XCTestExpectation = XCTestExpectation()
    
    static var autocollectedData: String?
    static var subscribeForAutocollectedDataExpectation: XCTestExpectation = XCTestExpectation()
    
    override class func activate() {
        anonymousActivationExpectation.fulfill()
    }
    
    override class func setupLibraryAdapterConfiguration(_ configuration: AppMetricaLibraryAdapterConfiguration) {
        libraryAdapterConfiguration = configuration
        setupLibraryAdapterConfigurationExpectation.fulfill()
    }
    
    override class func setLibraryAdapterLocationTracking(_ locationTracking: Bool) {
        locationTrackingEnabledValue = locationTracking
        locationTrackingEnabledExpectation.fulfill()
    }
    
    override class func setLibraryAdapterAdvertisingIdentifierTracking(_ advertisingIdentifierTracking: Bool) {
        advertisingIdentifierTrackingEnabledValue = advertisingIdentifierTracking
        advertisingIdentifierTrackingEnabledExpectation.fulfill()
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
    
    override class func subscribeForAutocollectedData(apiKey: String) {
        autocollectedData = apiKey
        subscribeForAutocollectedDataExpectation.fulfill()
    }

    static func reset() {
        anonymousActivationExpectation = XCTestExpectation(description: "Should activate anonymously via extended interface")
        anonymousConfiguration = nil
        
        reportEventCalled = false
        lastReportedEventName = nil
        lastReportedEventParameters = nil
        shouldFailReporting = false
    }
}
