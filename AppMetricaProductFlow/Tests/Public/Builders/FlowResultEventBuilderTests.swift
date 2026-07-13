import Foundation
import Testing
@testable import AppMetricaProductFlow

struct FlowResultEventBuilderTests {

    @Test func testInit_byProductId_setsOnlyProductId() {
        let builder = FlowResultEventBuilder(status: .success, productId: "loan")

        #expect(builder.status == .success)
        #expect(builder.productId?.rawValue == "loan")
        #expect(builder.productOfferId == nil)
    }

    @Test func testInit_byProductOfferId_setsOnlyProductOfferId() {
        let builder = FlowResultEventBuilder(status: .fail, productOfferId: "offer-1")

        #expect(builder.status == .fail)
        #expect(builder.productId == nil)
        #expect(builder.productOfferId?.rawValue == "offer-1")
    }

    @Test func testWithers_setEveryOptionalField() {
        let price = OfferPrice(amount: 10, unit: "USD")

        let builder = FlowResultEventBuilder(status: .success, productId: "loan")
            .withProductOfferId("offer-1")
            .withPrice(price)
            .withPayload(["k": "v"])

        #expect(builder.productOfferId?.rawValue == "offer-1")
        #expect(builder.price?.unit == "USD")
        #expect(builder.payload == ["k": "v"])
    }

    @Test func testWithProductId_overridesInitialValue() {
        let builder = FlowResultEventBuilder(status: .success, productOfferId: "offer-1")
            .withProductId("loan")

        #expect(builder.productId?.rawValue == "loan")
        #expect(builder.productOfferId?.rawValue == "offer-1")
    }

    @Test func testWithers_areImmutable() {
        let original = FlowResultEventBuilder(status: .success, productId: "loan")

        _ = original.withPayload(["k": "v"])

        #expect(original.payload == nil)
    }

    @Test func testBuild_usesInjectedAssembler_andPassesSelf() throws {
        var builder = FlowResultEventBuilder(status: .success, productId: "loan")
        var proto = ProductFlowEventProto()
        proto.eventType = .eventTypeFlowResult
        let mock = MockFlowResultEventAssembler(result: .init(value: proto, bytesTruncated: 42))
        builder.assembler = mock

        let event = try #require(builder.build() as? ProductFlowInternalEvent)

        #expect(mock.receivedBuilder?.productId == builder.productId)
        let data = try #require(event.eventData as? ProductFlowEventData)
        #expect(data.bytesTruncated == 42)
    }
}

private final class MockFlowResultEventAssembler: ProductFlowEventAssembling {
    let result: AssemblyResult
    private(set) var receivedBuilder: FlowResultEventBuilder?

    init(result: AssemblyResult) {
        self.result = result
    }

    func assemble(builder: FlowResultEventBuilder) -> AssemblyResult {
        receivedBuilder = builder
        return result
    }
}
