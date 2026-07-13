import Foundation
import Testing
@testable import AppMetricaProductFlow

struct OfferPriceTests {

    @Test func testInit_storesAmountAndUnit() {
        let price = OfferPrice(amount: Decimal(string: "123.45")!, unit: "USD")

        #expect(price.amount == Decimal(string: "123.45"))
        #expect(price.unit == "USD")
    }
}
