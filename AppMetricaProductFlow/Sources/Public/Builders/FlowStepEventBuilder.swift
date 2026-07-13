import Foundation
import AppMetricaCore

/// Builds a product flow step event, reported for any intermediate step of the funnel
/// (before or after the flow start), such as filling in parameters, uploading documents,
/// scoring, or payment.
///
/// Create instances via ``ProductFlowEvents/flowStep(productId:stepType:)`` or
/// ``ProductFlowEvents/flowStep(productOfferId:stepType:)``, attach optional details with
/// the `with...` methods, then call ``build()``.
public struct FlowStepEventBuilder {
    var productId: NonEmptyString?
    var productOfferId: NonEmptyString?
    let stepType: NonEmptyString
    var stepOption: NonEmptyString?
    var price: OfferPrice?
    var payload: [String: String]?

    var assembler: any ProductFlowEventAssembling<FlowStepEventBuilder> = FlowStepEventAssembler()

    init(productId: NonEmptyString, stepType: NonEmptyString) {
        self.productId = productId
        self.productOfferId = nil
        self.stepType = stepType
    }

    init(productOfferId: NonEmptyString, stepType: NonEmptyString) {
        self.productId = nil
        self.productOfferId = productOfferId
        self.stepType = stepType
    }

    /// Sets the identifier of the product type this step belongs to.
    /// - Returns: A copy of the builder with the value set.
    public func withProductId(_ value: NonEmptyString) -> Self {
        var copy = self; copy.productId = value; return copy
    }

    /// Sets the identifier of the specific offer variant this step belongs to.
    /// - Returns: A copy of the builder with the value set.
    public func withProductOfferId(_ value: NonEmptyString) -> Self {
        var copy = self; copy.productOfferId = value; return copy
    }

    /// Sets the value or detail selected at this step, e.g. a chosen option or entered detail.
    /// - Returns: A copy of the builder with the value set.
    public func withStepOption(_ value: NonEmptyString) -> Self {
        var copy = self; copy.stepOption = value; return copy
    }

    /// Sets the price of the product as known at this step.
    /// - Returns: A copy of the builder with the value set.
    public func withPrice(_ value: OfferPrice) -> Self {
        var copy = self; copy.price = value; return copy
    }

    /// Sets arbitrary key-value metadata to attach to the event.
    ///
    /// - Note: The total encoded payload is capped; pairs exceeding the limit are dropped.
    /// - Returns: A copy of the builder with the value set.
    public func withPayload(_ value: [String: String]) -> Self {
        var copy = self; copy.payload = value; return copy
    }

    /// Assembles the event so it can be reported via `AppMetrica.report(event:)`.
    public func build() -> any AppMetricaEvent {
        return ProductFlowInternalEvent(assembler: assembler, builder: self)
    }
}
