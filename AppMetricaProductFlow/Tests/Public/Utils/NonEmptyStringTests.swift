import Foundation
import Testing
@testable import AppMetricaProductFlow

struct NonEmptyStringTests {

    @Test func testInit_nonEmpty_succeedsAndKeepsRawValue() {
        let raw: String = "loan"
        let value = NonEmptyString(raw)

        #expect(value?.rawValue == "loan")
    }

    @Test func testInit_empty_returnsNil() {
        let empty: String = ""

        #expect(NonEmptyString(empty) == nil)
    }

    @Test func testInit_whitespaceOnly_isAllowed() {
        let raw: String = " "
        let value = NonEmptyString(raw)

        #expect(value?.rawValue == " ")
    }

    @Test func testStringLiteral_producesExpectedRawValue() {
        let value: NonEmptyString = "loan"

        #expect(value.rawValue == "loan")
    }

    @Test func testEquatable_sameRawValueAreEqual_differentAreNot() {
        let a: NonEmptyString = "loan"
        let b: NonEmptyString = "loan"
        let c: NonEmptyString = "offer"

        #expect(a == b)
        #expect(a != c)
    }

    @Test func testHashable_dedupesInSet() {
        let set: Set<NonEmptyString> = ["loan", "loan", "offer"]

        #expect(set.count == 2)
    }

    @Test func testDescription_returnsRawValue() {
        let value: NonEmptyString = "loan"

        #expect(value.description == "loan")
        #expect("\(value)" == "loan")
    }
}
