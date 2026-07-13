import Foundation

struct FlowResultEventAssembler: ProductFlowEventAssembling {
    let stringConverter: any StringConverting
    let amountConverter: any AmountConverting
    let payloadConverter: any PayloadConverting

    init(
        stringConverter: any StringConverting = StringConverter(),
        amountConverter: any AmountConverting = AmountConverter(),
        payloadConverter: any PayloadConverting = PayloadConverter()
    ) {
        self.stringConverter = stringConverter
        self.amountConverter = amountConverter
        self.payloadConverter = payloadConverter
    }

    func assemble(builder: FlowResultEventBuilder) -> AssemblyResult {
        var proto = ProductFlowEventProto()
        proto.eventType = .eventTypeFlowResult
        var bytesTruncated = 0

        var resultInfo = ProductFlowEventProto.ResultInfo()
        resultInfo.status = protoStatus(from: builder.status)
        proto.resultInfo = resultInfo

        if let productId = builder.productId {
            let result = stringConverter.convert(productId.rawValue)
            proto.productID = result.value
            bytesTruncated += result.bytesTruncated
        }
        if let productOfferId = builder.productOfferId {
            let result = stringConverter.convert(productOfferId.rawValue)
            proto.productOfferID = result.value
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

    private func protoStatus(from status: ProductFlowStatus) -> ProductFlowEventProto.ResultInfo.Status {
        switch status {
        case .success: return .success
        case .declined: return .declined
        case .pending: return .pending
        case .cancelled: return .cancelled
        case .expired: return .expired
        case .fail: return .fail
        }
    }
}
