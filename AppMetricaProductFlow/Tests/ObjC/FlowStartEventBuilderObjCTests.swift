import Foundation
import Testing
import AppMetricaCore
@testable import AppMetricaProductFlow

struct FlowStartEventBuilderObjCTests {

    @Test func testInit_setsProductId_othersAreNil() {
        let builder = ProductFlowEventsObjC.flowStart(productId: "loan")

        #expect(builder?.swiftBuilder.productId.rawValue == "loan")
        #expect(builder?.swiftBuilder.productOfferId == nil)
        #expect(builder?.swiftBuilder.price == nil)
        #expect(builder?.swiftBuilder.payload == nil)
    }

    @Test func testWithers_setEveryOptionalField() {
        let price = OfferPriceObjC(amount: NSDecimalNumber(value: 100), unit: "RUB")

        let builder = ProductFlowEventsObjC.flowStart(productId: "loan")!
            .withProductOfferId("offer-1")!
            .withPrice(price)
            .withPayload(["k": "v"])

        #expect(builder.swiftBuilder.productOfferId == "offer-1")
        #expect(builder.swiftBuilder.price?.unit == "RUB")
        #expect(builder.swiftBuilder.payload == ["k": "v"])
    }

    @Test func testWithers_mutateAndReturnSameInstance() {
        let original = ProductFlowEventsObjC.flowStart(productId: "loan")!

        let result = original.withProductOfferId("offer-1")

        #expect(result === original)
        #expect(original.swiftBuilder.productOfferId == "offer-1")
    }

    @Test func testWithProductOfferId_returnsNil_forEmptyString() {
        let builder = ProductFlowEventsObjC.flowStart(productId: "loan")!

        #expect(builder.withProductOfferId("") == nil)
    }

    @Test func testBuild_returnsEvent() {
        let event = ProductFlowEventsObjC.flowStart(productId: "loan")?.build()

        #expect(event is AppMetricaEvent)
    }
}
