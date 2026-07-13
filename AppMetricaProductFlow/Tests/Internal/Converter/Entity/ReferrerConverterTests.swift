import Foundation
import Testing
@testable import AppMetricaProductFlow

struct ReferrerConverterTests {

    @Test func testConvert_allFields_writeBytes() {
        let referrer = OfferReferrer(type: "banner", identifier: "id-1", screen: "main")

        let result = ReferrerConverter().convert(referrer)

        #expect(result.value.type == Data("banner".utf8))
        #expect(result.value.identifier == Data("id-1".utf8))
        #expect(result.value.screen == Data("main".utf8))
        #expect(result.bytesTruncated == 0)
    }

    @Test func testConvert_allNil_writesEmptyFields() {
        let result = ReferrerConverter().convert(OfferReferrer())

        #expect(!result.value.hasType)
        #expect(!result.value.hasIdentifier)
        #expect(!result.value.hasScreen)
        #expect(result.bytesTruncated == 0)
    }

    @Test func testConvert_someFieldsNil_writesOnlyPresent() {
        let referrer = OfferReferrer(type: "banner", identifier: nil, screen: "main")

        let result = ReferrerConverter().convert(referrer)

        #expect(result.value.hasType)
        #expect(!result.value.hasIdentifier)
        #expect(result.value.hasScreen)
    }

    @Test func testConvert_truncationAcrossFields_isSummed() {
        let referrer = OfferReferrer(type: "ab", identifier: "cd", screen: "ef")

        let result = ReferrerConverter(stringConverter: StringConverter(maxLength: 1)).convert(referrer)

        #expect(result.value.type == Data("a".utf8))
        #expect(result.value.identifier == Data("c".utf8))
        #expect(result.value.screen == Data("e".utf8))
        #expect(result.bytesTruncated == 3)
    }
}
