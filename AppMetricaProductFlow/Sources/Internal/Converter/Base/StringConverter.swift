import Foundation

protocol StringConverting {
    func convert(_ string: String) -> TruncatedData<Data>
}

struct StringConverter: StringConverting {
    let maxLength: Int

    init(maxLength: Int = ProductFlowConstants.maxStringLength) {
        self.maxLength = maxLength
    }

    func convert(_ string: String) -> TruncatedData<Data> {
        let data = Data(string.prefix(maxLength).utf8)
        let bytesTruncated = string.utf8.count - data.count
        return .init(value: data, bytesTruncated: bytesTruncated)
    }
}
