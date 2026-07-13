import Foundation
import AppMetricaCore

/// Builds the final product flow result event, reported once the acquisition funnel completes.
///
/// Create instances via ``ProductFlowEvents/flowResult(productId:status:)`` or
/// ``ProductFlowEvents/flowResult(productOfferId:status:)``, attach optional details with
/// the `with...` methods, then call ``build()``.
///
/// - Note: If the status is ``ProductFlowStatus/pending``, report a follow-up result event
///   with the final status once the asynchronous decision is known.
public struct FlowResultEventBuilder {
    let status: ProductFlowStatus
    var productId: NonEmptyString?
    var productOfferId: NonEmptyString?
    var price: OfferPrice?
    var payload: [String: String]?

    var assembler: any ProductFlowEventAssembling<FlowResultEventBuilder> = FlowResultEventAssembler()

    init(status: ProductFlowStatus, productId: NonEmptyString) {
        self.status = status
        self.productId = productId
        self.productOfferId = nil
    }

    init(status: ProductFlowStatus, productOfferId: NonEmptyString) {
        self.status = status
        self.productId = nil
        self.productOfferId = productOfferId
    }

    /// Sets the identifier of the product type this result belongs to.
    /// - Returns: A copy of the builder with the value set.
    public func withProductId(_ value: NonEmptyString) -> Self {
        var copy = self; copy.productId = value; return copy
    }

    /// Sets the identifier of the specific offer variant this result belongs to.
    /// - Returns: A copy of the builder with the value set.
    public func withProductOfferId(_ value: NonEmptyString) -> Self {
        var copy = self; copy.productOfferId = value; return copy
    }

    /// Sets the final price of the product.
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
