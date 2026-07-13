import Foundation
import Testing
import AppMetricaCore
@testable import AppMetricaProductFlow

struct OfferShownEventBuilderObjCTests {

    @Test func testInit_setsRequiredFields_othersAreNil() {
        let builder = ProductFlowEventsObjC.offerShown(productOfferId: "offer-1", offerType: "insurance")

        #expect(builder?.swiftBuilder.productOfferId.rawValue == "offer-1")
        #expect(builder?.swiftBuilder.offerType.rawValue == "insurance")
        #expect(builder?.swiftBuilder.productId == nil)
        #expect(builder?.swiftBuilder.benefitType == nil)
        #expect(builder?.swiftBuilder.price == nil)
        #expect(builder?.swiftBuilder.payload == nil)
        #expect(builder?.swiftBuilder.referrer == nil)
    }

    @Test func testWithers_setEveryOptionalField() {
        let price = OfferPriceObjC(amount: NSDecimalNumber(string: "9.99"), unit: "USD")
        let referrer = OfferReferrerObjC(type: "banner", identifier: "id", screen: "main")

        let builder = ProductFlowEventsObjC.offerShown(productOfferId: "offer-1", offerType: "insurance")!
            .withProductId("loan")!
            .withBenefitType("cashback")
            .withPrice(price)
            .withPayload(["k": "v"])
            .withReferrer(referrer)

        #expect(builder.swiftBuilder.productId == "loan")
        #expect(builder.swiftBuilder.benefitType == "cashback")
        #expect(builder.swiftBuilder.price?.amount == Decimal(string: "9.99")!)
        #expect(builder.swiftBuilder.price?.unit == "USD")
        #expect(builder.swiftBuilder.payload == ["k": "v"])
        #expect(builder.swiftBuilder.referrer?.type == "banner")
        #expect(builder.swiftBuilder.referrer?.identifier == "id")
        #expect(builder.swiftBuilder.referrer?.screen == "main")
    }

    @Test func testWithers_mutateAndReturnSameInstance() {
        let original = ProductFlowEventsObjC.offerShown(productOfferId: "offer-1", offerType: "insurance")!

        let result = original.withProductId("loan")

        #expect(result === original)
        #expect(original.swiftBuilder.productId == "loan")
    }

    @Test func testWithProductId_returnsNil_forEmptyString() {
        let builder = ProductFlowEventsObjC.offerShown(productOfferId: "offer-1", offerType: "insurance")!

        #expect(builder.withProductId("") == nil)
    }

    @Test func testWithProductId_acceptsNil_clearsField() {
        let builder = ProductFlowEventsObjC.offerShown(productOfferId: "offer-1", offerType: "insurance")!
            .withProductId("loan")!
            .withProductId(nil)

        #expect(builder?.swiftBuilder.productId == nil)
    }

    @Test func testBuild_returnsEvent() {
        let event = ProductFlowEventsObjC.offerShown(productOfferId: "offer-1", offerType: "insurance")?.build()

        #expect(event is AppMetricaEvent)
    }
}
