import Foundation
import Testing
@testable import AppMetricaProductFlow

struct ProductFlowEventsObjCTests {

    @Test func testOfferShown_wiresRequiredFields() {
        let builder = ProductFlowEventsObjC.offerShown(productOfferId: "offer-1", offerType: "insurance")

        #expect(builder?.swiftBuilder.productOfferId.rawValue == "offer-1")
        #expect(builder?.swiftBuilder.offerType.rawValue == "insurance")
    }

    @Test func testFlowStart_wiresProductId() {
        let builder = ProductFlowEventsObjC.flowStart(productId: "loan")

        #expect(builder?.swiftBuilder.productId.rawValue == "loan")
    }

    @Test func testFlowStep_byProductId_wiresFields() {
        let builder = ProductFlowEventsObjC.flowStep(productId: "loan", stepType: "form")

        #expect(builder?.swiftBuilder.productId?.rawValue == "loan")
        #expect(builder?.swiftBuilder.productOfferId == nil)
        #expect(builder?.swiftBuilder.stepType.rawValue == "form")
    }

    @Test func testFlowStep_byProductOfferId_wiresFields() {
        let builder = ProductFlowEventsObjC.flowStep(productOfferId: "offer-1", stepType: "form")

        #expect(builder?.swiftBuilder.productId == nil)
        #expect(builder?.swiftBuilder.productOfferId?.rawValue == "offer-1")
        #expect(builder?.swiftBuilder.stepType.rawValue == "form")
    }

    @Test func testFlowResult_byProductId_wiresFields() {
        let builder = ProductFlowEventsObjC.flowResult(productId: "loan", status: .success)

        #expect(builder?.swiftBuilder.status == .success)
        #expect(builder?.swiftBuilder.productId?.rawValue == "loan")
        #expect(builder?.swiftBuilder.productOfferId == nil)
    }

    @Test func testFlowResultForOffer_byProductOfferId_wiresFields() {
        let builder = ProductFlowEventsObjC.flowResultForOffer(productOfferId: "offer-1", status: .declined)

        #expect(builder?.swiftBuilder.status == .declined)
        #expect(builder?.swiftBuilder.productId == nil)
        #expect(builder?.swiftBuilder.productOfferId?.rawValue == "offer-1")
    }

    @Test func testFactories_returnNil_forEmptyStrings() {
        #expect(ProductFlowEventsObjC.offerShown(productOfferId: "", offerType: "insurance") == nil)
        #expect(ProductFlowEventsObjC.offerShown(productOfferId: "offer-1", offerType: "") == nil)
        #expect(ProductFlowEventsObjC.flowStart(productId: "") == nil)
        #expect(ProductFlowEventsObjC.flowStep(productId: "", stepType: "form") == nil)
        #expect(ProductFlowEventsObjC.flowStep(productOfferId: "", stepType: "form") == nil)
        #expect(ProductFlowEventsObjC.flowStep(productId: "loan", stepType: "") == nil)
        #expect(ProductFlowEventsObjC.flowResult(productId: "", status: .success) == nil)
        #expect(ProductFlowEventsObjC.flowResultForOffer(productOfferId: "", status: .success) == nil)
    }
}
