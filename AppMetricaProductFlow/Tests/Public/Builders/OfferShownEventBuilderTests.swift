import Foundation
import Testing
@testable import AppMetricaProductFlow

struct OfferShownEventBuilderTests {

    @Test func testInit_setsRequiredFields_othersAreNil() {
        let builder = OfferShownEventBuilder(productOfferId: "offer-1", offerType: "insurance")

        #expect(builder.productOfferId == "offer-1")
        #expect(builder.offerType == "insurance")
        #expect(builder.productId == nil)
        #expect(builder.benefitType == nil)
        #expect(builder.price == nil)
        #expect(builder.payload == nil)
        #expect(builder.referrer == nil)
    }

    @Test func testWithers_setEveryOptionalField() {
        let price = OfferPrice(amount: 9.99, unit: "USD")
        let referrer = OfferReferrer(type: "banner", identifier: "id", screen: "main")

        let builder = OfferShownEventBuilder(productOfferId: "offer-1", offerType: "insurance")
            .withProductId("loan")
            .withBenefitType("cashback")
            .withPrice(price)
            .withPayload(["k": "v"])
            .withReferrer(referrer)

        #expect(builder.productId == "loan")
        #expect(builder.benefitType == "cashback")
        #expect(builder.price?.amount == price.amount)
        #expect(builder.price?.unit == price.unit)
        #expect(builder.payload == ["k": "v"])
        #expect(builder.referrer?.type == "banner")
        #expect(builder.referrer?.identifier == "id")
        #expect(builder.referrer?.screen == "main")
    }

    @Test func testWithers_areImmutable_originalIsUnchanged() {
        let original = OfferShownEventBuilder(productOfferId: "offer-1", offerType: "insurance")

        _ = original.withProductId("loan")

        #expect(original.productId == nil)
    }

    @Test func testBuild_usesInjectedAssembler_andPassesSelf() throws {
        var builder = OfferShownEventBuilder(productOfferId: "offer-1", offerType: "insurance")
        var proto = ProductFlowEventProto()
        proto.eventType = .eventTypeOfferShown
        let mock = MockOfferShownEventAssembler(result: .init(value: proto, bytesTruncated: 42))
        builder.assembler = mock

        let event = try #require(builder.build() as? ProductFlowInternalEvent)

        #expect(mock.receivedBuilder?.productOfferId == builder.productOfferId)
        let data = try #require(event.eventData as? ProductFlowEventData)
        #expect(data.bytesTruncated == 42)
    }
}

private final class MockOfferShownEventAssembler: ProductFlowEventAssembling {
    let result: AssemblyResult
    private(set) var receivedBuilder: OfferShownEventBuilder?

    init(result: AssemblyResult) {
        self.result = result
    }

    func assemble(builder: OfferShownEventBuilder) -> AssemblyResult {
        receivedBuilder = builder
        return result
    }
}
