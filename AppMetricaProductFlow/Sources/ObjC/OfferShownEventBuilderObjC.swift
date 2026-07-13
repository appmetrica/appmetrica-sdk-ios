import Foundation
import AppMetricaCore

/// Objective-C builder for the "offer shown" product flow event.
///
/// Mirrors ``OfferShownEventBuilder``. Create instances via
/// ``ProductFlowEventsObjC/offerShown(productOfferId:offerType:)``, attach optional details
/// with the `with...` methods, then call `build`.
@objc(AMAOfferShownEventBuilder)
public final class OfferShownEventBuilderObjC: NSObject {
    var swiftBuilder: OfferShownEventBuilder

    init(swiftBuilder: OfferShownEventBuilder) {
        self.swiftBuilder = swiftBuilder
    }

    /// Sets the identifier of the product type this offer belongs to, e.g. `"personal_loan"`, `"deposit_6m"`.
    /// - Returns: `self`, or `nil` if `value` is non-nil and empty.
    @objc public func withProductId(_ value: String?) -> OfferShownEventBuilderObjC? {
        guard let value else {
            swiftBuilder = swiftBuilder.withProductId(nil)
            return self
        }
        guard let nonEmpty = NonEmptyString(value) else { return nil }
        swiftBuilder = swiftBuilder.withProductId(nonEmpty)
        return self
    }

    /// Sets the type of benefit advertised by the offer, e.g. `"discount_percentage"`, `"cashback"`, `"trial"`.
    /// - Returns: `self`.
    @objc public func withBenefitType(_ value: String?) -> OfferShownEventBuilderObjC {
        swiftBuilder = swiftBuilder.withBenefitType(value)
        return self
    }

    /// Sets the price shown alongside the offer.
    /// - Returns: `self`.
    @objc public func withPrice(_ value: OfferPriceObjC?) -> OfferShownEventBuilderObjC {
        swiftBuilder = swiftBuilder.withPrice(value?.swiftValue)
        return self
    }

    /// Sets arbitrary key-value metadata to attach to the event.
    ///
    /// - Note: The total encoded payload is capped; pairs exceeding the limit are dropped.
    /// - Returns: `self`.
    @objc public func withPayload(_ value: [String: String]?) -> OfferShownEventBuilderObjC {
        swiftBuilder = swiftBuilder.withPayload(value)
        return self
    }

    /// Sets the source that caused the offer to be shown, e.g. a banner, button, or notification.
    /// - Returns: `self`.
    @objc public func withReferrer(_ value: OfferReferrerObjC?) -> OfferShownEventBuilderObjC {
        swiftBuilder = swiftBuilder.withReferrer(value?.swiftValue)
        return self
    }

    /// Assembles the event so it can be reported via `AppMetrica.report(event:)`.
    @objc public func build() -> AppMetricaEvent {
        swiftBuilder.build()
    }
}
