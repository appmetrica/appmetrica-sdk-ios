import Foundation
import Testing
import AppMetricaCoreExtension
@testable import AppMetricaProductFlow

struct ProductFlowInternalEventTests {

    @Test func testInit_withProtoAndBytesTruncated_buildsDataEvent() throws {
        var proto = ProductFlowEventProto()
        proto.eventType = .eventTypeOfferShown

        let event = ProductFlowInternalEvent(proto: proto, bytesTruncated: 7)

        let data = try #require(event.eventData as? ProductFlowEventData)
        #expect(data.bytesTruncated == 7)
        #expect(data.type == ProductFlowConstants.eventType)
    }

    @Test func testInit_withAssembler_usesAssemblyResult() throws {
        let assembler = StubAssembler(
            result: .init(value: makeProto(eventType: .eventTypeFlowStart), bytesTruncated: 11)
        )

        let event = ProductFlowInternalEvent(assembler: assembler, builder: ())

        let data = try #require(event.eventData as? ProductFlowEventData)
        #expect(data.bytesTruncated == 11)
    }

    @Test func testCopy_returnsSelf() {
        let event = ProductFlowInternalEvent(proto: ProductFlowEventProto(), bytesTruncated: 0)

        #expect(event.copy() as? ProductFlowInternalEvent === event)
    }

    private func makeProto(eventType: ProductFlowEventProto.ProductFlowEventType) -> ProductFlowEventProto {
        var proto = ProductFlowEventProto()
        proto.eventType = eventType
        return proto
    }
}

private struct StubAssembler: ProductFlowEventAssembling {
    let result: AssemblyResult
    func assemble(builder: Void) -> AssemblyResult { result }
}
