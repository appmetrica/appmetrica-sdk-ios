import Foundation
import Testing
@testable import AppMetricaProductFlow

struct StringConverterTests {

    @Test func testConvert_shortString_returnsFullBytes() {
        let result = StringConverter().convert("hello")

        #expect(result.value == Data("hello".utf8))
        #expect(result.bytesTruncated == 0)
    }

    @Test func testConvert_emptyString_returnsEmptyData() {
        let result = StringConverter().convert("")

        #expect(result.value == Data())
        #expect(result.bytesTruncated == 0)
    }

    @Test func testConvert_longString_truncatesAndReportsBytes() {
        let converter = StringConverter(maxLength: 4)

        let result = converter.convert("abcdefgh")

        #expect(result.value == Data("abcd".utf8))
        #expect(result.bytesTruncated == 4)
    }

    @Test func testConvert_multibyteString_truncationCountsCharactersNonAscii() {
        let converter = StringConverter(maxLength: 2)

        let result = converter.convert("яяя")

        #expect(result.value == Data("яя".utf8))
        #expect(result.value.count == 4)
        #expect(result.bytesTruncated == 2)
    }

    @Test func testConvert_defaultMaxLength_isProductFlowConstants() {
        let input = String(repeating: "x", count: ProductFlowConstants.maxStringLength + 10)

        let result = StringConverter().convert(input)

        #expect(result.value.count == ProductFlowConstants.maxStringLength)
        #expect(result.bytesTruncated == 10)
    }
}
