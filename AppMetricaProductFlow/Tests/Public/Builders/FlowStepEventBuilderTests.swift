import Foundation
import Testing
@testable import AppMetricaProductFlow

struct FlowStepEventBuilderTests {

    @Test func testInit_byProductId_setsOnlyProductId() {
        let builder = FlowStepEventBuilder(productId: "loan", stepType: "scoring")

        #expect(builder.productId?.rawValue == "loan")
        #expect(builder.productOfferId == nil)
        #expect(builder.stepType.rawValue == "scoring")
    }

    @Test func testInit_byProductOfferId_setsOnlyProductOfferId() {
        let builder = FlowStepEventBuilder(productOfferId: "offer-1", stepType: "scoring")

        #expect(builder.productId == nil)
        #expect(builder.productOfferId?.rawValue == "offer-1")
        #expect(builder.stepType.rawValue == "scoring")
    }

    @Test func testWithers_setEveryOptionalField() {
        let price = OfferPrice(amount: 5, unit: "EUR")

        let builder = FlowStepEventBuilder(productId: "loan", stepType: "scoring")
            .withProductOfferId("offer-1")
            .withStepOption("variantA")
            .withPrice(price)
            .withPayload(["k": "v"])

        #expect(builder.productId?.rawValue == "loan")
        #expect(builder.productOfferId?.rawValue == "offer-1")
        #expect(builder.stepOption == "variantA")
        #expect(builder.price?.unit == "EUR")
        #expect(builder.payload == ["k": "v"])
    }

    @Test func testWithProductId_overridesInitialValue() {
        let builder = FlowStepEventBuilder(productOfferId: "offer-1", stepType: "scoring")
            .withProductId("loan")

        #expect(builder.productId?.rawValue == "loan")
        #expect(builder.productOfferId?.rawValue == "offer-1")
    }

    @Test func testWithers_areImmutable() {
        let original = FlowStepEventBuilder(productId: "loan", stepType: "scoring")

        _ = original.withStepOption("variantA")

        #expect(original.stepOption == nil)
    }

    @Test func testBuild_usesInjectedAssembler_andPassesSelf() throws {
        var builder = FlowStepEventBuilder(productId: "loan", stepType: "scoring")
        var proto = ProductFlowEventProto()
        proto.eventType = .eventTypeStep
        let mock = MockFlowStepEventAssembler(result: .init(value: proto, bytesTruncated: 42))
        builder.assembler = mock

        let event = try #require(builder.build() as? ProductFlowInternalEvent)

        #expect(mock.receivedBuilder?.stepType == builder.stepType)
        let data = try #require(event.eventData as? ProductFlowEventData)
        #expect(data.bytesTruncated == 42)
    }
}

private final class MockFlowStepEventAssembler: ProductFlowEventAssembling {
    let result: AssemblyResult
    private(set) var receivedBuilder: FlowStepEventBuilder?

    init(result: AssemblyResult) {
        self.result = result
    }

    func assemble(builder: FlowStepEventBuilder) -> AssemblyResult {
        receivedBuilder = builder
        return result
    }
}
