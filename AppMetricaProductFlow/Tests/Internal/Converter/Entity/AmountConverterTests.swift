import Foundation
import Testing
@testable import AppMetricaProductFlow

struct AmountConverterTests {

    @Test func testConvert_writesUnitMantissaAndExponent() {
        let price = OfferPrice(amount: Decimal(string: "12.34")!, unit: "USD")

        let result = AmountConverter().convert(price)

        #expect(result.value.unit == Data("USD".utf8))
        #expect(result.value.mantissa == 1234)
        #expect(result.value.exponent == -2)
        #expect(result.bytesTruncated == 0)
    }

    @Test func testConvert_zeroAmount() {
        let result = AmountConverter().convert(OfferPrice(amount: 0, unit: "USD"))

        #expect(result.value.mantissa == 0)
        #expect(result.value.exponent == 0)
    }

    @Test func testConvert_negativeAmount_preservesSign() {
        let price = OfferPrice(amount: Decimal(string: "-12.34")!, unit: "USD")

        let result = AmountConverter().convert(price)

        #expect(result.value.mantissa == -1234)
        #expect(result.value.exponent == -2)
    }

    @Test func testConvert_longUnit_truncatesAndReportsBytes() {
        let price = OfferPrice(amount: 1, unit: String(repeating: "u", count: ProductFlowConstants.maxStringLength + 5))

        let result = AmountConverter().convert(price)

        #expect(result.value.unit.count == ProductFlowConstants.maxStringLength)
        #expect(result.bytesTruncated == 5)
    }

    @Test func testConvert_usesInjectedStringConverter() {
        let price = OfferPrice(amount: 1, unit: "abcdef")

        let result = AmountConverter(stringConverter: StringConverter(maxLength: 3)).convert(price)

        #expect(result.value.unit == Data("abc".utf8))
        #expect(result.bytesTruncated == 3)
    }
}
