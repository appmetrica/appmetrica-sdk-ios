import Foundation
import Testing
@testable import AppMetricaProductFlow

struct OfferShownEventAssemblerTests {

    @Test func testConvert_minimal_setsRequiredFields() {
        let builder = OfferShownEventBuilder(productOfferId: "offer-1", offerType: "insurance")

        let result = OfferShownEventAssembler().assemble(builder: builder)

        #expect(result.value.eventType == .eventTypeOfferShown)
        #expect(result.value.productOfferID == Data("offer-1".utf8))
        #expect(result.value.shownInfo.offerType == Data("insurance".utf8))
        #expect(!result.value.shownInfo.hasBenefitType)
        #expect(!result.value.shownInfo.hasReferrer)
        #expect(!result.value.hasProductID)
        #expect(!result.value.hasPrice)
        #expect(!result.value.hasPayload)
        #expect(result.bytesTruncated == 0)
    }

    @Test func testConvert_full_setsAllFields() {
        let builder = OfferShownEventBuilder(productOfferId: "offer-1", offerType: "insurance")
            .withProductId("loan")
            .withBenefitType("cashback")
            .withPrice(OfferPrice(amount: Decimal(string: "9.99")!, unit: "USD"))
            .withPayload(["k": "v"])
            .withReferrer(OfferReferrer(type: "banner", identifier: "id-1", screen: "main"))

        let result = OfferShownEventAssembler().assemble(builder: builder)

        #expect(result.value.productOfferID == Data("offer-1".utf8))
        #expect(result.value.productID == Data("loan".utf8))
        #expect(result.value.shownInfo.offerType == Data("insurance".utf8))
        #expect(result.value.shownInfo.benefitType == Data("cashback".utf8))
        #expect(result.value.shownInfo.referrer.type == Data("banner".utf8))
        #expect(result.value.shownInfo.referrer.identifier == Data("id-1".utf8))
        #expect(result.value.shownInfo.referrer.screen == Data("main".utf8))
        #expect(result.value.price.unit == Data("USD".utf8))
        #expect(result.value.price.mantissa == 999)
        #expect(result.value.price.exponent == -2)
        #expect(result.value.payload.pairs.count == 1)
        #expect(result.bytesTruncated == 0)
    }

    @Test func testConvert_truncation_isAccumulated() {
        let longId = NonEmptyString(String(repeating: "o", count: ProductFlowConstants.maxStringLength + 3))!
        let longType = NonEmptyString(String(repeating: "t", count: ProductFlowConstants.maxStringLength + 7))!

        let result = OfferShownEventAssembler()
            .assemble(builder: OfferShownEventBuilder(productOfferId: longId, offerType: longType))

        #expect(result.bytesTruncated == 10)
    }
}
