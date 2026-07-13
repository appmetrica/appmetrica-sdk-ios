import Foundation
import Testing
@testable import AppMetricaProductFlow

struct FlowStartEventAssemblerTests {

    @Test func testConvert_minimal_setsRequiredFields() {
        let result = FlowStartEventAssembler().assemble(builder: FlowStartEventBuilder(productId: "loan"))

        #expect(result.value.eventType == .eventTypeFlowStart)
        #expect(result.value.productID == Data("loan".utf8))
        #expect(!result.value.hasProductOfferID)
        #expect(!result.value.hasPrice)
        #expect(!result.value.hasPayload)
        #expect(result.bytesTruncated == 0)
    }

    @Test func testConvert_full_setsAllFields() {
        let builder = FlowStartEventBuilder(productId: "loan")
            .withProductOfferId("offer-1")
            .withPrice(OfferPrice(amount: 100, unit: "RUB"))
            .withPayload(["k": "v"])

        let result = FlowStartEventAssembler().assemble(builder: builder)

        #expect(result.value.productID == Data("loan".utf8))
        #expect(result.value.productOfferID == Data("offer-1".utf8))
        #expect(result.value.price.unit == Data("RUB".utf8))
        #expect(result.value.hasPrice)
        #expect(result.value.payload.pairs.count == 1)
        #expect(result.bytesTruncated == 0)
    }

    @Test func testConvert_truncation_isAccumulated() {
        let longId = NonEmptyString(String(repeating: "p", count: ProductFlowConstants.maxStringLength + 4))!

        let result = FlowStartEventAssembler().assemble(builder: FlowStartEventBuilder(productId: longId))

        #expect(result.bytesTruncated == 4)
    }
}
