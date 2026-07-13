import Foundation
import AppMetricaCore

/// Builds the "flow start" product flow event, reported when the user begins acquiring a product.
///
/// This event also serves as the offer-to-acquisition conversion signal. Create instances via
/// ``ProductFlowEvents/flowStart(productId:)``, attach optional details with the `with...`
/// methods, then call ``build()``.
public struct FlowStartEventBuilder {
    let productId: NonEmptyString
    var productOfferId: NonEmptyString?
    var price: OfferPrice?
    var payload: [String: String]?

    var assembler: any ProductFlowEventAssembling<FlowStartEventBuilder> = FlowStartEventAssembler()

    init(productId: NonEmptyString) {
        self.productId = productId
    }

    /// Sets the identifier of the specific offer variant this flow was started from.
    /// - Returns: A copy of the builder with the value set.
    public func withProductOfferId(_ value: NonEmptyString) -> Self {
        var copy = self; copy.productOfferId = value; return copy
    }

    /// Sets the price of the product at the time the flow was started.
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
