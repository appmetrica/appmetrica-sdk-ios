import Foundation

protocol ReferrerConverting {
    func convert(_ referrer: OfferReferrer) -> TruncatedData<ProductFlowEventProto.Referrer>
}

struct ReferrerConverter: ReferrerConverting {
    private let stringConverter: any StringConverting

    init(stringConverter: any StringConverting = StringConverter()) {
        self.stringConverter = stringConverter
    }

    func convert(_ referrer: OfferReferrer) -> TruncatedData<ProductFlowEventProto.Referrer> {
        var proto = ProductFlowEventProto.Referrer()
        var bytesTruncated = 0
        if let type = referrer.type {
            let result = stringConverter.convert(type)
            proto.type = result.value
            bytesTruncated += result.bytesTruncated
        }
        if let identifier = referrer.identifier {
            let result = stringConverter.convert(identifier)
            proto.identifier = result.value
            bytesTruncated += result.bytesTruncated
        }
        if let screen = referrer.screen {
            let result = stringConverter.convert(screen)
            proto.screen = result.value
            bytesTruncated += result.bytesTruncated
        }
        return .init(value: proto, bytesTruncated: bytesTruncated)
    }
}
