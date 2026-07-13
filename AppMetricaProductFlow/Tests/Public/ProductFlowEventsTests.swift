import Foundation
import Testing
@testable import AppMetricaProductFlow

struct ProductFlowEventsTests {

    @Test func testOfferShown_returnsBuilderSeededWithIds() {
        let builder = ProductFlowEvents.offerShown(productOfferId: "offer-1", offerType: "insurance")

        #expect(builder.productOfferId == "offer-1")
        #expect(builder.offerType == "insurance")
        #expect(builder.productId == nil)
        #expect(builder.benefitType == nil)
        #expect(builder.price == nil)
        #expect(builder.payload == nil)
        #expect(builder.referrer == nil)
    }

    @Test func testFlowStart_returnsBuilderSeededWithProductId() {
        let builder = ProductFlowEvents.flowStart(productId: "loan")

        #expect(builder.productId == "loan")
        #expect(builder.productOfferId == nil)
        #expect(builder.price == nil)
        #expect(builder.payload == nil)
    }

    @Test func testFlowStep_byProductId() {
        let builder = ProductFlowEvents.flowStep(productId: "loan", stepType: "scoring")

        #expect(builder.productId?.rawValue == "loan")
        #expect(builder.productOfferId == nil)
        #expect(builder.stepType.rawValue == "scoring")
    }

    @Test func testFlowStep_byProductOfferId() {
        let builder = ProductFlowEvents.flowStep(productOfferId: "offer-1", stepType: "payment")

        #expect(builder.productId == nil)
        #expect(builder.productOfferId?.rawValue == "offer-1")
        #expect(builder.stepType.rawValue == "payment")
    }

    @Test func testFlowResult_byProductId() {
        let builder = ProductFlowEvents.flowResult(productId: "loan", status: .success)

        #expect(builder.productId?.rawValue == "loan")
        #expect(builder.productOfferId == nil)
        #expect(builder.status == .success)
    }

    @Test func testFlowResultForOffer_byProductOfferId() {
        let builder = ProductFlowEvents.flowResult(productOfferId: "offer-1", status: .fail)

        #expect(builder.productId == nil)
        #expect(builder.productOfferId?.rawValue == "offer-1")
        #expect(builder.status == .fail)
    }
}
