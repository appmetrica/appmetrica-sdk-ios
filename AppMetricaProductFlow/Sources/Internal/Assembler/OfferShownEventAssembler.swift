import Foundation

struct OfferShownEventAssembler: ProductFlowEventAssembling {
    let stringConverter: any StringConverting
    let amountConverter: any AmountConverting
    let payloadConverter: any PayloadConverting
    let referrerConverter: any ReferrerConverting

    init(
        stringConverter: any StringConverting = StringConverter(),
        amountConverter: any AmountConverting = AmountConverter(),
        payloadConverter: any PayloadConverting = PayloadConverter(),
        referrerConverter: any ReferrerConverting = ReferrerConverter()
    ) {
        self.stringConverter = stringConverter
        self.amountConverter = amountConverter
        self.payloadConverter = payloadConverter
        self.referrerConverter = referrerConverter
    }

    func assemble(builder: OfferShownEventBuilder) -> AssemblyResult {
        var proto = ProductFlowEventProto()
        proto.eventType = .eventTypeOfferShown
        var bytesTruncated = 0

        let productOfferIdResult = stringConverter.convert(builder.productOfferId.rawValue)
        proto.productOfferID = productOfferIdResult.value
        bytesTruncated += productOfferIdResult.bytesTruncated

        var shownInfo = ProductFlowEventProto.ShownInfo()
        let offerTypeResult = stringConverter.convert(builder.offerType.rawValue)
        shownInfo.offerType = offerTypeResult.value
        bytesTruncated += offerTypeResult.bytesTruncated
        if let benefitType = builder.benefitType {
            let result = stringConverter.convert(benefitType)
            shownInfo.benefitType = result.value
            bytesTruncated += result.bytesTruncated
        }
        if let referrer = builder.referrer {
            let result = referrerConverter.convert(referrer)
            shownInfo.referrer = result.value
            bytesTruncated += result.bytesTruncated
        }
        proto.shownInfo = shownInfo

        if let productId = builder.productId {
            let result = stringConverter.convert(productId.rawValue)
            proto.productID = result.value
            bytesTruncated += result.bytesTruncated
        }
        if let price = builder.price {
            let result = amountConverter.convert(price)
            proto.price = result.value
            bytesTruncated += result.bytesTruncated
        }
        if let payload = builder.payload {
            let result = payloadConverter.convert(payload)
            proto.payload = result.value
            bytesTruncated += result.bytesTruncated
        }

        return AssemblyResult(value: proto, bytesTruncated: bytesTruncated)
    }
}
