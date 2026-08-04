import AppMetricaCore
import AppMetricaCoreExtension
import Foundation
import XCTest

class MockAppMetrica: AppMetrica {
    nonisolated(unsafe) static var reportEventCalled = false
    nonisolated(unsafe) static var lastReportedEventName: String?
    nonisolated(unsafe) static var lastReportedEventParameters: [AnyHashable: Any]?
    nonisolated(unsafe) static var shouldFailReporting = false
    
    nonisolated(unsafe) static var anonymousConfiguration: AppMetricaConfiguration?
    nonisolated(unsafe) static var anonymousActivationExpectation: XCTestExpectation = XCTestExpectation()
    
    nonisolated(unsafe) static var libraryAdapterConfiguration: AppMetricaLibraryAdapterConfiguration?
    nonisolated(unsafe) static var setupLibraryAdapterConfigurationExpectation: XCTestExpectation = XCTestExpectation()
    
    nonisolated(unsafe) static var locationTrackingEnabledValue: Bool?
    nonisolated(unsafe) static var locationTrackingEnabledExpectation: XCTestExpectation = XCTestExpectation()
    
    nonisolated(unsafe) static var advertisingIdentifierTrackingEnabledValue: Bool?
    nonisolated(unsafe) static var advertisingIdentifierTrackingEnabledExpectation: XCTestExpectation = XCTestExpectation()

    nonisolated(unsafe) static var customHostsValue: [String]?
    nonisolated(unsafe) static var customHostsExpectation: XCTestExpectation = XCTestExpectation()
    
    nonisolated(unsafe) static var autocollectedData: String?
    nonisolated(unsafe) static var subscribeForAutocollectedDataExpectation: XCTestExpectation = XCTestExpectation()
    
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

    override class func setLibraryAdapterCustomHosts(_ customHosts: [String]?) {
        customHostsValue = customHosts
        customHostsExpectation.fulfill()
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
        setupLibraryAdapterConfigurationExpectation = XCTestExpectation(description: "Should setup library adapter configuration")
        locationTrackingEnabledExpectation = XCTestExpectation(description: "Should set location tracking")
        advertisingIdentifierTrackingEnabledExpectation = XCTestExpectation(description: "Should set advertising identifier tracking")
        customHostsExpectation = XCTestExpectation(description: "Should set custom hosts")
        subscribeForAutocollectedDataExpectation = XCTestExpectation(description: "Should subscribe for autocollected data")
        anonymousConfiguration = nil
        libraryAdapterConfiguration = nil
        locationTrackingEnabledValue = nil
        advertisingIdentifierTrackingEnabledValue = nil
        customHostsValue = nil
        autocollectedData = nil

        reportEventCalled = false
        lastReportedEventName = nil
        lastReportedEventParameters = nil
        shouldFailReporting = false
    }
}
