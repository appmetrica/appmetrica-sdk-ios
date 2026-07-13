import Foundation
import AppMetricaCoreUtils

protocol AmountConverting {
    func convert(_ price: OfferPrice) -> TruncatedData<ProductFlowEventProto.Amount>
}

struct AmountConverter: AmountConverting {
    private let stringConverter: any StringConverting

    init(stringConverter: any StringConverting = StringConverter()) {
        self.stringConverter = stringConverter
    }

    func convert(_ price: OfferPrice) -> TruncatedData<ProductFlowEventProto.Amount> {
        var proto = ProductFlowEventProto.Amount()
        let unitResult = stringConverter.convert(price.unit)
        proto.unit = unitResult.value

        var mantissa: Int64 = 0
        var exponent: Int32 = 0
        DecimalUtils.fillMantissa(&mantissa, exponent: &exponent, withDecimal: price.amount as NSDecimalNumber)
        proto.mantissa = mantissa
        proto.exponent = exponent
        return .init(value: proto, bytesTruncated: unitResult.bytesTruncated)
    }
}
