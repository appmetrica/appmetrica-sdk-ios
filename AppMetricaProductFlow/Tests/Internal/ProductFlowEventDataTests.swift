import Foundation
import Testing
import SwiftProtobuf
@testable import AppMetricaProductFlow

struct ProductFlowEventDataTests {

    @Test func testType_isProductFlowEventType() {
        let event = ProductFlowEventData(proto: ProductFlowEventProto(), bytesTruncated: 0)

        #expect(event.type == ProductFlowConstants.eventType)
    }

    @Test func testName_isNil() {
        let event = ProductFlowEventData(proto: ProductFlowEventProto(), bytesTruncated: 0)

        #expect(event.name == nil)
    }

    @Test func testBytesTruncated_storesValue() {
        let event = ProductFlowEventData(proto: ProductFlowEventProto(), bytesTruncated: 42)

        #expect(event.bytesTruncated == 42)
    }

    @Test func testData_matchesSerializedProto() throws {
        var proto = ProductFlowEventProto()
        proto.eventType = .eventTypeOfferShown
        proto.productID = Data("loan".utf8)

        let event = ProductFlowEventData(proto: proto, bytesTruncated: 0)

        let data = try #require(event.data)
        let decoded = try ProductFlowEventProto(serializedBytes: data)
        #expect(decoded.eventType == .eventTypeOfferShown)
        #expect(decoded.productID == Data("loan".utf8))
    }

    @Test func testData_isStableUnderConcurrentAccess() {
        var proto = ProductFlowEventProto()
        proto.eventType = .eventTypeOfferShown
        proto.productID = Data("loan".utf8)
        let event = ProductFlowEventData(proto: proto, bytesTruncated: 0)
        let expected = event.data

        DispatchQueue.concurrentPerform(iterations: 200) { _ in
            _ = event.data
        }

        #expect(event.data == expected)
        #expect(expected != nil)
    }

    @Test func testCopy_returnsSelf() {
        let event = ProductFlowEventData(proto: ProductFlowEventProto(), bytesTruncated: 0)

        #expect(event.copy() as? ProductFlowEventData === event)
    }
}
