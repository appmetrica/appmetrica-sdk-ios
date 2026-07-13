import Foundation

protocol PayloadConverting {
    func convert(_ dict: [String: String]) -> TruncatedData<ProductFlowEventProto.Payload>
}

struct PayloadConverter: PayloadConverting {
    private let stringConverter: any StringConverting
    private let maxBytes: Int

    init(
        stringConverter: any StringConverting = StringConverter(),
        maxBytes: Int = ProductFlowConstants.maxPayloadBytes
    ) {
        self.stringConverter = stringConverter
        self.maxBytes = maxBytes
    }

    func convert(_ dict: [String: String]) -> TruncatedData<ProductFlowEventProto.Payload> {
        var proto = ProductFlowEventProto.Payload()
        var storedBytes = 0
        var bytesTruncated = 0
        var truncatedPairs: UInt32 = 0
        var capacityReached = false

        let sortedEntries = dict.sorted { lhs, rhs in
            let lhsValueSize = lhs.value.count
            let rhsValueSize = rhs.value.count
            return lhsValueSize == rhsValueSize ? lhs.key < rhs.key : lhsValueSize < rhsValueSize
        }

        for (key, value) in sortedEntries {
            let originalPairBytes = key.count + value.count
            let keyResult = stringConverter.convert(key)
            let valueResult = stringConverter.convert(value)
            let trimmedPairBytes = keyResult.value.count + valueResult.value.count

            if capacityReached || storedBytes + trimmedPairBytes > maxBytes {
                capacityReached = true
                truncatedPairs += 1
                bytesTruncated += originalPairBytes
            } else {
                bytesTruncated += keyResult.bytesTruncated + valueResult.bytesTruncated
                storedBytes += trimmedPairBytes
                var pair = ProductFlowEventProto.Payload.Pair()
                pair.key = keyResult.value
                pair.value = valueResult.value
                proto.pairs.append(pair)
            }
        }

        proto.truncatedPairsCount = truncatedPairs
        return .init(value: proto, bytesTruncated: bytesTruncated)
    }
}
