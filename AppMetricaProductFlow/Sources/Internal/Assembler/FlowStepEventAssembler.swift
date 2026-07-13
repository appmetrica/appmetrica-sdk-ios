import Foundation

struct FlowStepEventAssembler: ProductFlowEventAssembling {
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

    func assemble(builder: FlowStepEventBuilder) -> AssemblyResult {
        var proto = ProductFlowEventProto()
        proto.eventType = .eventTypeStep
        var bytesTruncated = 0

        var stepInfo = ProductFlowEventProto.StepInfo()
        let stepTypeResult = stringConverter.convert(builder.stepType.rawValue)
        stepInfo.stepType = stepTypeResult.value
        bytesTruncated += stepTypeResult.bytesTruncated
        if let stepOption = builder.stepOption {
            let result = stringConverter.convert(stepOption.rawValue)
            stepInfo.stepOption = result.value
            bytesTruncated += result.bytesTruncated
        }
        proto.stepInfo = stepInfo

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
}
