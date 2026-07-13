import Foundation
import AppMetricaCore

/// Builds the "offer shown" product flow event, reported when an offer is displayed to the user.
///
/// Create instances via ``ProductFlowEvents/offerShown(productOfferId:offerType:)``, attach
/// optional details with the `with...` methods, then call ``build()``.
public struct OfferShownEventBuilder {
    let productOfferId: NonEmptyString
    let offerType: NonEmptyString
    var productId: NonEmptyString?
    var benefitType: String?
    var price: OfferPrice?
    var payload: [String: String]?
    var referrer: OfferReferrer?

    var assembler: any ProductFlowEventAssembling<OfferShownEventBuilder> = OfferShownEventAssembler()

    init(productOfferId: NonEmptyString, offerType: NonEmptyString) {
        self.productOfferId = productOfferId
        self.offerType = offerType
    }

    /// Sets the identifier of the product type this offer belongs to, e.g. `"personal_loan"`, `"deposit_6m"`.
    /// - Returns: A copy of the builder with the value set.
    public func withProductId(_ value: NonEmptyString?) -> Self {
        var copy = self; copy.productId = value; return copy
    }

    /// Sets the type of benefit advertised by the offer, e.g. `"discount_percentage"`, `"cashback"`, `"trial"`.
    /// - Returns: A copy of the builder with the value set.
    public func withBenefitType(_ value: String?) -> Self {
        var copy = self; copy.benefitType = value; return copy
    }

    /// Sets the price shown alongside the offer.
    /// - Returns: A copy of the builder with the value set.
    public func withPrice(_ value: OfferPrice?) -> Self {
        var copy = self; copy.price = value; return copy
    }

    /// Sets arbitrary key-value metadata to attach to the event.
    ///
    /// - Note: The total encoded payload is capped; pairs exceeding the limit are dropped.
    /// - Returns: A copy of the builder with the value set.
    public func withPayload(_ value: [String: String]?) -> Self {
        var copy = self; copy.payload = value; return copy
    }

    /// Sets the source that caused the offer to be shown, e.g. a banner, button, or notification.
    /// - Returns: A copy of the builder with the value set.
    public func withReferrer(_ value: OfferReferrer?) -> Self {
        var copy = self; copy.referrer = value; return copy
    }

    /// Assembles the event so it can be reported via `AppMetrica.report(event:)`.
    public func build() -> any AppMetricaEvent {
        return ProductFlowInternalEvent(assembler: assembler, builder: self)
    }
}
