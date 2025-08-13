import XCTest

@testable import AppMetricaCore
@testable import AppMetricaLibraryAdapter

class AppMetricaLibraryAdapterTests: XCTestCase {

    var adapter: AppMetricaLibraryAdapter!

    override func setUp() {
        super.setUp()
        MockAppMetrica.reset()
        adapter = AppMetricaLibraryAdapter(appMetrica: MockAppMetrica.self)
    }

    override func tearDown() {
        adapter = nil
        super.tearDown()
    }

    func testActivate() {
        adapter.activate()
        
        wait(for: [MockAppMetrica.anonymousActivationExpectation], timeout: 1)
    }
    
    func testActivateWithConfig() {
        let config = MutableLibraryAdapterConfiguration()
        config.advIdentifiersTrackingEnabled = true
        config.locationTrackingEnabled = true
        
        adapter.activate(configuration: config)
        
        wait(
            for: [
                MockAppMetrica.anonymousActivationExpectation,
                MockAppMetrica.setupLibraryAdapterConfigurationExpectation,
            ],
            timeout: 1
        )
        XCTAssertEqual(MockAppMetrica.libraryAdapterConfiguration?.advertisingIdentifierTrackingEnabled, true)
        XCTAssertEqual(MockAppMetrica.libraryAdapterConfiguration?.locationTrackingEnabled, true)
    }
    
    func testSetLocationTrackingEnabled() {
        adapter.setLocationTracking(true)
        wait(for: [MockAppMetrica.locationTrackingEnabledExpectation], timeout: 1)
        XCTAssertEqual(MockAppMetrica.locationTrackingEnabledValue, true)
    }

    func testSetAdvTrackingEnabled() {
        adapter.setAdvertisingTracking(true)
        wait(for: [MockAppMetrica.advertisingIdentifierTrackingEnabledExpectation], timeout: 1)
        XCTAssertEqual(MockAppMetrica.advertisingIdentifierTrackingEnabledValue, true)
    }
    
    func testReportEventSuccess() {
        // Given
        let sender = "test_sender"
        let event = "test_event"
        let payload = "{\"key1\":\"value1\",\"key2\":42}"

        // When
        adapter.reportEvent(sender: sender, event: event, payload: payload) { _ in
            XCTFail("onFailure should not be called for successful reporting")
        }

        // Then
        XCTAssertTrue(MockAppMetrica.reportEventCalled)
        XCTAssertEqual(MockAppMetrica.lastReportedEventName, "appmetrica_system_event_42")

        guard let parameters = MockAppMetrica.lastReportedEventParameters else {
            XCTFail("Event parameters should not be nil")
            return
        }

        XCTAssertEqual(parameters["sender"] as? String, sender)
        XCTAssertEqual(parameters["event"] as? String, event)
        XCTAssertEqual(parameters["payload"] as? String, payload)
    }

    func testReportEventWithAppMetricaFailure() {
        // Given
        let expectation = self.expectation(description: "Report event with AppMetrica failure")
        let sender = "test_sender"
        let event = "test_event"
        let payload = "{\"key\":\"value\"}"
        MockAppMetrica.shouldFailReporting = true

        // When
        adapter.reportEvent(sender: sender, event: event, payload: payload) { error in
            XCTAssertNotNil(error)
            XCTAssertEqual((error as NSError).domain, "MockAppMetrica")
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 1.0, handler: nil)
        XCTAssertTrue(MockAppMetrica.reportEventCalled)
    }
    
}
