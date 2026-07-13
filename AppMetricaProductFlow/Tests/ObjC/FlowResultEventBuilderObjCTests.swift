import Foundation
import Testing
import AppMetricaCore
@testable import AppMetricaProductFlow

struct FlowResultEventBuilderObjCTests {

    @Test func testInitWithProductId_setsRequiredFields() {
        let builder = ProductFlowEventsObjC.flowResult(productId: "loan", status: .success)

        #expect(builder?.swiftBuilder.status == .success)
        #expect(builder?.swiftBuilder.productId?.rawValue == "loan")
        #expect(builder?.swiftBuilder.productOfferId == nil)
    }

    @Test func testInitWithProductOfferId_setsRequiredFields() {
        let builder = ProductFlowEventsObjC.flowResultForOffer(productOfferId: "offer-1", status: .declined)

        #expect(builder?.swiftBuilder.status == .declined)
        #expect(builder?.swiftBuilder.productId == nil)
        #expect(builder?.swiftBuilder.productOfferId?.rawValue == "offer-1")
    }

    @Test func testWithers_setEveryOptionalField() {
        let price = OfferPriceObjC(amount: NSDecimalNumber(value: 100), unit: "RUB")

        let builder = ProductFlowEventsObjC.flowResult(productId: "loan", status: .success)!
            .withProductOfferId("offer-1")!
            .withPrice(price)
            .withPayload(["k": "v"])

        #expect(builder.swiftBuilder.productOfferId?.rawValue == "offer-1")
        #expect(builder.swiftBuilder.price?.unit == "RUB")
        #expect(builder.swiftBuilder.payload == ["k": "v"])
    }

    @Test func testWithers_mutateAndReturnSameInstance() {
        let original = ProductFlowEventsObjC.flowResult(productId: "loan", status: .success)!

        let result = original.withProductOfferId("offer-1")

        #expect(result === original)
        #expect(original.swiftBuilder.productOfferId == "offer-1")
    }

    @Test func testWithers_returnNil_forEmptyStrings() {
        let builder = ProductFlowEventsObjC.flowResult(productId: "loan", status: .success)!

        #expect(builder.withProductId("") == nil)
        #expect(builder.withProductOfferId("") == nil)
    }
}
