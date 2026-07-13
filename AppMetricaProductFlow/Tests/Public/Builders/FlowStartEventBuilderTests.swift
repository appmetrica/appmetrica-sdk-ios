import Foundation
import Testing
@testable import AppMetricaProductFlow

struct FlowStartEventBuilderTests {

    @Test func testInit_setsProductId_othersAreNil() {
        let builder = FlowStartEventBuilder(productId: "loan")

        #expect(builder.productId == "loan")
        #expect(builder.productOfferId == nil)
        #expect(builder.price == nil)
        #expect(builder.payload == nil)
    }

    @Test func testWithers_setEveryOptionalField() {
        let price = OfferPrice(amount: 100, unit: "RUB")

        let builder = FlowStartEventBuilder(productId: "loan")
            .withProductOfferId("offer-1")
            .withPrice(price)
            .withPayload(["k": "v"])

        #expect(builder.productOfferId == "offer-1")
        #expect(builder.price?.unit == "RUB")
        #expect(builder.payload == ["k": "v"])
    }

    @Test func testWithers_areImmutable() {
        let original = FlowStartEventBuilder(productId: "loan")

        _ = original.withProductOfferId("offer-1")

        #expect(original.productOfferId == nil)
    }

    @Test func testBuild_usesInjectedAssembler_andPassesSelf() throws {
        var builder = FlowStartEventBuilder(productId: "loan")
        var proto = ProductFlowEventProto()
        proto.eventType = .eventTypeFlowStart
        let mock = MockFlowStartEventAssembler(result: .init(value: proto, bytesTruncated: 42))
        builder.assembler = mock

        let event = try #require(builder.build() as? ProductFlowInternalEvent)

        #expect(mock.receivedBuilder?.productId == builder.productId)
        let data = try #require(event.eventData as? ProductFlowEventData)
        #expect(data.bytesTruncated == 42)
    }
}

private final class MockFlowStartEventAssembler: ProductFlowEventAssembling {
    let result: AssemblyResult
    private(set) var receivedBuilder: FlowStartEventBuilder?

    init(result: AssemblyResult) {
        self.result = result
    }

    func assemble(builder: FlowStartEventBuilder) -> AssemblyResult {
        receivedBuilder = builder
        return result
    }
}
