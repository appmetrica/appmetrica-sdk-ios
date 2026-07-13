import Foundation
import Testing
@testable import AppMetricaProductFlow

struct PayloadConverterTests {

    @Test func testConvert_emptyDict_isEmpty() {
        let result = PayloadConverter().convert([:])

        #expect(result.value.pairs.isEmpty)
        #expect(result.value.truncatedPairsCount == 0)
        #expect(result.bytesTruncated == 0)
    }

    @Test func testConvert_singleSmallPair_isStored() {
        let result = PayloadConverter().convert(["k": "v"])

        #expect(result.value.pairs.count == 1)
        #expect(result.value.pairs[0].key == Data("k".utf8))
        #expect(result.value.pairs[0].value == Data("v".utf8))
        #expect(result.value.truncatedPairsCount == 0)
        #expect(result.bytesTruncated == 0)
    }

    @Test func testConvert_longKeyAndValue_truncatedByStringConverter() {
        let converter = PayloadConverter(stringConverter: StringConverter(maxLength: 2))

        let result = converter.convert(["abcd": "efgh"])

        #expect(result.value.pairs.count == 1)
        #expect(result.value.pairs[0].key == Data("ab".utf8))
        #expect(result.value.pairs[0].value == Data("ef".utf8))
        #expect(result.bytesTruncated == 4)
    }

    @Test func testConvert_pairExceedsTotalBudget_isDroppedAndCounted() {
        let converter = PayloadConverter(maxBytes: 1)

        let result = converter.convert(["kk": "vv"])

        #expect(result.value.pairs.isEmpty)
        #expect(result.value.truncatedPairsCount == 1)
        #expect(result.bytesTruncated == 4)
    }

    @Test func testConvert_someFitSomeDont_pairsAreCountedAndStored() {
        let converter = PayloadConverter(maxBytes: 4)
        let dict = ["aa": "bb", "cc": "dd", "ee": "ff"]

        let result = converter.convert(dict)

        #expect(result.value.pairs.count == 1)
        #expect(result.value.pairs[0].key == Data("aa".utf8))
        #expect(result.value.pairs[0].value == Data("bb".utf8))
        #expect(result.value.truncatedPairsCount == 2)
        #expect(result.bytesTruncated == 8)
    }

    @Test func testConvert_orderIsDeterministic_regardlessOfInsertionOrder() {
        let converter = PayloadConverter()
        let pairs = [("c", "3"), ("a", "1"), ("b", "2"), ("d", "4")]

        let forward = converter.convert(Dictionary(uniqueKeysWithValues: pairs))
        let reversed = converter.convert(Dictionary(uniqueKeysWithValues: pairs.reversed()))

        let expectedKeys = [Data("a".utf8), Data("b".utf8), Data("c".utf8), Data("d".utf8)]
        #expect(forward.value.pairs.map(\.key) == expectedKeys)
        #expect(reversed.value.pairs.map(\.key) == expectedKeys)
    }

    @Test func testConvert_sortsByValueSize_notByKey() {
        let converter = PayloadConverter(maxBytes: 6)
        let dict = ["a": "22222", "z": "1"]

        let result = converter.convert(dict)

        #expect(result.value.pairs.count == 1)
        #expect(result.value.pairs[0].key == Data("z".utf8))
        #expect(result.value.pairs[0].value == Data("1".utf8))
        #expect(result.value.truncatedPairsCount == 1)
    }

    @Test func testConvert_onceCapacityReached_allRemainingPairsAreDroppedEvenIfTheyWouldFit() {
        let converter = PayloadConverter(maxBytes: 5)
        let dict = [
            "xxxxxx": "a",
            "b": "bb"
        ]

        let result = converter.convert(dict)

        #expect(result.value.pairs.isEmpty)
        #expect(result.value.truncatedPairsCount == 2)
        #expect(result.bytesTruncated == 10)
    }
}
