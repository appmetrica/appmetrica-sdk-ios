import Foundation
import Testing
@testable import AppMetricaProductFlow

struct OfferReferrerTests {

    @Test func testInit_default_allFieldsNil() {
        let referrer = OfferReferrer()

        #expect(referrer.type == nil)
        #expect(referrer.identifier == nil)
        #expect(referrer.screen == nil)
    }

    @Test func testInit_storesAllFields() {
        let referrer = OfferReferrer(type: "banner", identifier: "id-42", screen: "main")

        #expect(referrer.type == "banner")
        #expect(referrer.identifier == "id-42")
        #expect(referrer.screen == "main")
    }
}
