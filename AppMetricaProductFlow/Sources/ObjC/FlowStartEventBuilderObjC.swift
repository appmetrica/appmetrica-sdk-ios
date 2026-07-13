import Foundation
import AppMetricaCore

/// Objective-C builder for the "flow start" product flow event.
///
/// Mirrors ``FlowStartEventBuilder``. Create instances via
/// ``ProductFlowEventsObjC/flowStart(productId:)``, attach optional details with the
/// `with...` methods, then call `build`.
@objc(AMAFlowStartEventBuilder)
public final class FlowStartEventBuilderObjC: NSObject {
    var swiftBuilder: FlowStartEventBuilder

    init(swiftBuilder: FlowStartEventBuilder) {
        self.swiftBuilder = swiftBuilder
    }

    /// Sets the identifier of the specific offer variant this flow was started from.
    /// - Returns: `self`, or `nil` if `value` is empty.
    @objc public func withProductOfferId(_ value: String) -> FlowStartEventBuilderObjC? {
        guard let value = NonEmptyString(value) else { return nil }
        swiftBuilder = swiftBuilder.withProductOfferId(value)
        return self
    }

    /// Sets the price of the product at the time the flow was started.
    /// - Returns: `self`.
    @objc public func withPrice(_ value: OfferPriceObjC) -> FlowStartEventBuilderObjC {
        swiftBuilder = swiftBuilder.withPrice(value.swiftValue)
        return self
    }

    /// Sets arbitrary key-value metadata to attach to the event.
    ///
    /// - Note: The total encoded payload is capped; pairs exceeding the limit are dropped.
    /// - Returns: `self`.
    @objc public func withPayload(_ value: [String: String]) -> FlowStartEventBuilderObjC {
        swiftBuilder = swiftBuilder.withPayload(value)
        return self
    }

    /// Assembles the event so it can be reported via `AppMetrica.report(event:)`.
    @objc public func build() -> AppMetricaEvent {
        swiftBuilder.build()
    }
}
