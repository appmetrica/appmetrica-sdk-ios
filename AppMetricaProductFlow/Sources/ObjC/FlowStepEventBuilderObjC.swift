import Foundation
import AppMetricaCore

/// Objective-C builder for a product flow step event.
///
/// Mirrors ``FlowStepEventBuilder``. Create instances via
/// ``ProductFlowEventsObjC/flowStep(productId:stepType:)`` or
/// ``ProductFlowEventsObjC/flowStep(productOfferId:stepType:)``, attach optional details
/// with the `with...` methods, then call `build`.
@objc(AMAFlowStepEventBuilder)
public final class FlowStepEventBuilderObjC: NSObject {
    var swiftBuilder: FlowStepEventBuilder

    init(swiftBuilder: FlowStepEventBuilder) {
        self.swiftBuilder = swiftBuilder
    }

    /// Sets the identifier of the product type this step belongs to.
    /// - Returns: `self`, or `nil` if `value` is empty.
    @objc public func withProductId(_ value: String) -> FlowStepEventBuilderObjC? {
        guard let value = NonEmptyString(value) else { return nil }
        swiftBuilder = swiftBuilder.withProductId(value)
        return self
    }

    /// Sets the identifier of the specific offer variant this step belongs to.
    /// - Returns: `self`, or `nil` if `value` is empty.
    @objc public func withProductOfferId(_ value: String) -> FlowStepEventBuilderObjC? {
        guard let value = NonEmptyString(value) else { return nil }
        swiftBuilder = swiftBuilder.withProductOfferId(value)
        return self
    }

    /// Sets the value or detail selected at this step, e.g. a chosen option or entered detail.
    /// - Returns: `self`, or `nil` if `value` is empty.
    @objc public func withStepOption(_ value: String) -> FlowStepEventBuilderObjC? {
        guard let value = NonEmptyString(value) else { return nil }
        swiftBuilder = swiftBuilder.withStepOption(value)
        return self
    }

    /// Sets the price of the product as known at this step.
    /// - Returns: `self`.
    @objc public func withPrice(_ value: OfferPriceObjC) -> FlowStepEventBuilderObjC {
        swiftBuilder = swiftBuilder.withPrice(value.swiftValue)
        return self
    }

    /// Sets arbitrary key-value metadata to attach to the event.
    ///
    /// - Note: The total encoded payload is capped; pairs exceeding the limit are dropped.
    /// - Returns: `self`.
    @objc public func withPayload(_ value: [String: String]) -> FlowStepEventBuilderObjC {
        swiftBuilder = swiftBuilder.withPayload(value)
        return self
    }

    /// Assembles the event so it can be reported via `AppMetrica.report(event:)`.
    @objc public func build() -> AppMetricaEvent {
        swiftBuilder.build()
    }
}
