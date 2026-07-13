import Foundation
import Testing
@testable import AppMetricaProductFlow

struct OfferReferrerObjCTests {

    @Test func testInit_storesAllFields() {
        let referrer = OfferReferrerObjC(type: "banner", identifier: "id", screen: "main")

        #expect(referrer.type == "banner")
        #expect(referrer.identifier == "id")
        #expect(referrer.screen == "main")
    }

    @Test func testInit_acceptsNils() {
        let referrer = OfferReferrerObjC(type: nil, identifier: nil, screen: nil)

        #expect(referrer.type == nil)
        #expect(referrer.identifier == nil)
        #expect(referrer.screen == nil)
    }

    @Test func testSwiftValue_roundTrips() {
        let referrer = OfferReferrerObjC(type: "banner", identifier: "id", screen: "main")

        let swift = referrer.swiftValue

        #expect(swift.type == "banner")
        #expect(swift.identifier == "id")
        #expect(swift.screen == "main")
    }

    @Test func testInitFromSwift_copiesAllFields() {
        let swift = OfferReferrer(type: "banner", identifier: "id", screen: "main")

        let referrer = OfferReferrerObjC(from: swift)

        #expect(referrer.type == "banner")
        #expect(referrer.identifier == "id")
        #expect(referrer.screen == "main")
    }
}
