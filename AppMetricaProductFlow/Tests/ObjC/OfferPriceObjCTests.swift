import Foundation
import Testing
@testable import AppMetricaProductFlow

struct OfferPriceObjCTests {

    @Test func testInit_storesProperties() {
        let price = OfferPriceObjC(amount: NSDecimalNumber(string: "9.99"), unit: "USD")

        #expect(price.amount == NSDecimalNumber(string: "9.99"))
        #expect(price.unit == "USD")
    }

    @Test func testSwiftValue_roundTripsDecimal() {
        let price = OfferPriceObjC(amount: NSDecimalNumber(string: "9.99"), unit: "USD")

        let swift = price.swiftValue

        #expect(swift.amount == Decimal(string: "9.99")!)
        #expect(swift.unit == "USD")
    }

    @Test func testInitFromSwift_bridgesDecimal() {
        let swift = OfferPrice(amount: Decimal(string: "1234.5678")!, unit: "EUR")

        let price = OfferPriceObjC(from: swift)

        #expect(price.amount == NSDecimalNumber(string: "1234.5678"))
        #expect(price.unit == "EUR")
    }
}
