import Foundation
import Testing
import AppMetricaCore
@testable import AppMetricaProductFlow

struct FlowStepEventBuilderObjCTests {

    @Test func testInitWithProductId_setsRequiredFields() {
        let builder = ProductFlowEventsObjC.flowStep(productId: "loan", stepType: "form")

        #expect(builder?.swiftBuilder.productId?.rawValue == "loan")
        #expect(builder?.swiftBuilder.productOfferId == nil)
        #expect(builder?.swiftBuilder.stepType.rawValue == "form")
    }

    @Test func testInitWithProductOfferId_setsRequiredFields() {
        let builder = ProductFlowEventsObjC.flowStep(productOfferId: "offer-1", stepType: "form")

        #expect(builder?.swiftBuilder.productId == nil)
        #expect(builder?.swiftBuilder.productOfferId?.rawValue == "offer-1")
        #expect(builder?.swiftBuilder.stepType.rawValue == "form")
    }

    @Test func testWithers_setEveryOptionalField() {
        let price = OfferPriceObjC(amount: NSDecimalNumber(value: 100), unit: "RUB")

        let builder = ProductFlowEventsObjC.flowStep(productId: "loan", stepType: "form")!
            .withProductOfferId("offer-1")!
            .withStepOption("submitted")!
            .withPrice(price)
            .withPayload(["k": "v"])

        #expect(builder.swiftBuilder.productOfferId?.rawValue == "offer-1")
        #expect(builder.swiftBuilder.stepOption == "submitted")
        #expect(builder.swiftBuilder.price?.unit == "RUB")
        #expect(builder.swiftBuilder.payload == ["k": "v"])
    }

    @Test func testWithers_mutateAndReturnSameInstance() {
        let original = ProductFlowEventsObjC.flowStep(productId: "loan", stepType: "form")!

        let result = original.withStepOption("submitted")

        #expect(result === original)
        #expect(original.swiftBuilder.stepOption == "submitted")
    }

    @Test func testWithers_returnNil_forEmptyStrings() {
        let builder = ProductFlowEventsObjC.flowStep(productId: "loan", stepType: "form")!

        #expect(builder.withProductId("") == nil)
        #expect(builder.withProductOfferId("") == nil)
        #expect(builder.withStepOption("") == nil)
    }

    @Test func testBuild_returnsEvent() {
        let event = ProductFlowEventsObjC.flowStep(productId: "loan", stepType: "form")?.build()

        #expect(event is AppMetricaEvent)
    }
}
