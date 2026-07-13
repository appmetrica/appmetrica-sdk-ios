import Foundation
import AppMetricaCore

/// Objective-C builder for the final product flow result event.
///
/// Mirrors ``FlowResultEventBuilder``. Create instances via
/// ``ProductFlowEventsObjC/flowResult(productId:status:)`` or
/// ``ProductFlowEventsObjC/flowResultForOffer(productOfferId:status:)``, attach optional
/// details with the `with...` methods, then call `build`.
@objc(AMAFlowResultEventBuilder)
public final class FlowResultEventBuilderObjC: NSObject {
    var swiftBuilder: FlowResultEventBuilder

    init(swiftBuilder: FlowResultEventBuilder) {
        self.swiftBuilder = swiftBuilder
    }

    /// Sets the identifier of the product type this result belongs to.
    /// - Returns: `self`, or `nil` if `value` is empty.
    @objc public func withProductId(_ value: String) -> FlowResultEventBuilderObjC? {
        guard let value = NonEmptyString(value) else { return nil }
        swiftBuilder = swiftBuilder.withProductId(value)
        return self
    }

    /// Sets the identifier of the specific offer variant this result belongs to.
    /// - Returns: `self`, or `nil` if `value` is empty.
    @objc public func withProductOfferId(_ value: String) -> FlowResultEventBuilderObjC? {
        guard let value = NonEmptyString(value) else { return nil }
        swiftBuilder = swiftBuilder.withProductOfferId(value)
        return self
    }

    /// Sets the final price of the product.
    /// - Returns: `self`.
    @objc public func withPrice(_ value: OfferPriceObjC) -> FlowResultEventBuilderObjC {
        swiftBuilder = swiftBuilder.withPrice(value.swiftValue)
        return self
    }

    /// Sets arbitrary key-value metadata to attach to the event.
    ///
    /// - Note: The total encoded payload is capped; pairs exceeding the limit are dropped.
    /// - Returns: `self`.
    @objc public func withPayload(_ value: [String: String]) -> FlowResultEventBuilderObjC {
        swiftBuilder = swiftBuilder.withPayload(value)
        return self
    }

    /// Assembles the event so it can be reported via `AppMetrica.report(event:)`.
    @objc public func build() -> AppMetricaEvent {
        swiftBuilder.build()
    }
}
