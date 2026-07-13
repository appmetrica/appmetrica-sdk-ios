import Foundation
import Testing
@testable import AppMetricaProductFlow

struct FlowStepEventAssemblerTests {

    @Test func testConvert_byProductId_setsRequiredFields() {
        let builder = FlowStepEventBuilder(productId: "loan", stepType: "scoring")

        let result = FlowStepEventAssembler().assemble(builder: builder)

        #expect(result.value.eventType == .eventTypeStep)
        #expect(result.value.productID == Data("loan".utf8))
        #expect(!result.value.hasProductOfferID)
        #expect(result.value.stepInfo.stepType == Data("scoring".utf8))
        #expect(!result.value.stepInfo.hasStepOption)
        #expect(result.bytesTruncated == 0)
    }

    @Test func testConvert_byProductOfferId_setsOfferId() {
        let builder = FlowStepEventBuilder(productOfferId: "offer-1", stepType: "scoring")

        let result = FlowStepEventAssembler().assemble(builder: builder)

        #expect(!result.value.hasProductID)
        #expect(result.value.productOfferID == Data("offer-1".utf8))
    }

    @Test func testConvert_full_setsAllFields() {
        let builder = FlowStepEventBuilder(productId: "loan", stepType: "scoring")
            .withProductOfferId("offer-1")
            .withStepOption("variantA")
            .withPrice(OfferPrice(amount: 5, unit: "EUR"))
            .withPayload(["k": "v"])

        let result = FlowStepEventAssembler().assemble(builder: builder)

        #expect(result.value.productID == Data("loan".utf8))
        #expect(result.value.productOfferID == Data("offer-1".utf8))
        #expect(result.value.stepInfo.stepType == Data("scoring".utf8))
        #expect(result.value.stepInfo.stepOption == Data("variantA".utf8))
        #expect(result.value.price.unit == Data("EUR".utf8))
        #expect(result.value.payload.pairs.count == 1)
        #expect(result.bytesTruncated == 0)
    }

    @Test func testConvert_truncation_isAccumulated() {
        let longStep = NonEmptyString(String(repeating: "s", count: ProductFlowConstants.maxStringLength + 6))!

        let result = FlowStepEventAssembler()
            .assemble(builder: FlowStepEventBuilder(productId: "loan", stepType: longStep))

        #expect(result.bytesTruncated == 6)
    }
}
