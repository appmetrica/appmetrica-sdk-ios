import Foundation
import Testing
@testable import AppMetricaProductFlow

struct FlowResultEventAssemblerTests {

    @Test func testConvert_minimal_setsRequiredFields() {
        let builder = FlowResultEventBuilder(status: .success, productId: "loan")

        let result = FlowResultEventAssembler().assemble(builder: builder)

        #expect(result.value.eventType == .eventTypeFlowResult)
        #expect(result.value.productID == Data("loan".utf8))
        #expect(!result.value.hasProductOfferID)
        #expect(result.value.resultInfo.status == .success)
        #expect(!result.value.hasPrice)
        #expect(!result.value.hasPayload)
        #expect(result.bytesTruncated == 0)
    }

    @Test func testConvert_byProductOfferId_setsOfferId() {
        let builder = FlowResultEventBuilder(status: .success, productOfferId: "offer-1")

        let result = FlowResultEventAssembler().assemble(builder: builder)

        #expect(!result.value.hasProductID)
        #expect(result.value.productOfferID == Data("offer-1".utf8))
    }

    @Test func testConvert_full_setsAllFields() {
        let builder = FlowResultEventBuilder(status: .fail, productId: "loan")
            .withProductOfferId("offer-1")
            .withPrice(OfferPrice(amount: 10, unit: "USD"))
            .withPayload(["k": "v"])

        let result = FlowResultEventAssembler().assemble(builder: builder)

        #expect(result.value.productID == Data("loan".utf8))
        #expect(result.value.productOfferID == Data("offer-1".utf8))
        #expect(result.value.resultInfo.status == .fail)
        #expect(result.value.price.unit == Data("USD".utf8))
        #expect(result.value.payload.pairs.count == 1)
    }

    @Test(arguments: [
        (ProductFlowStatus.success,   ProductFlowEventProto.ResultInfo.Status.success),
        (ProductFlowStatus.declined,  ProductFlowEventProto.ResultInfo.Status.declined),
        (ProductFlowStatus.pending,   ProductFlowEventProto.ResultInfo.Status.pending),
        (ProductFlowStatus.cancelled, ProductFlowEventProto.ResultInfo.Status.cancelled),
        (ProductFlowStatus.expired,   ProductFlowEventProto.ResultInfo.Status.expired),
        (ProductFlowStatus.fail,      ProductFlowEventProto.ResultInfo.Status.fail),
    ])
    func testConvert_statusMapping(input: ProductFlowStatus,
                                   expected: ProductFlowEventProto.ResultInfo.Status) {
        let builder = FlowResultEventBuilder(status: input, productId: "loan")

        let result = FlowResultEventAssembler().assemble(builder: builder)

        #expect(result.value.resultInfo.status == expected)
    }

    @Test func testConvert_truncation_isAccumulated() {
        let longId = NonEmptyString(String(repeating: "p", count: ProductFlowConstants.maxStringLength + 8))!

        let result = FlowResultEventAssembler()
            .assemble(builder: FlowResultEventBuilder(status: .success, productId: longId))

        #expect(result.bytesTruncated == 8)
    }
}
