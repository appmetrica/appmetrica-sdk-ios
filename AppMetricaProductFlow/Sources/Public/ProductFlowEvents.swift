import Foundation

/// Entry point for building AppMetrica product flow events.
///
/// A product flow describes a purchase/acquisition funnel for a product or offer:
/// ``offerShown(productOfferId:offerType:)`` when an offer is displayed to the user,
/// ``flowStart(productId:)`` when the acquisition is initiated,
/// ``flowStep(productId:stepType:)`` for any intermediate step of the funnel,
/// and ``flowResult(productId:status:)`` for the final outcome.
///
/// Each factory method returns a builder that lets you attach optional details
/// before calling `build()` to obtain an `AppMetricaEvent` ready to be reported
/// via `AppMetrica.report(event:)`.
public enum ProductFlowEvents {

    /// Creates a builder for the "offer shown" event, reported when an offer is displayed to the user.
    /// - Parameters:
    ///   - productOfferId: Identifier of the specific offer variant that was shown.
    ///   - offerType: Type of the offer, e.g. `"financial_product"`, `"insurance"`, `"subscription"`.
    /// - Returns: A ``OfferShownEventBuilder`` for attaching optional details.
    public static func offerShown(productOfferId: NonEmptyString, offerType: NonEmptyString) -> OfferShownEventBuilder {
        OfferShownEventBuilder(productOfferId: productOfferId, offerType: offerType)
    }

    /// Creates a builder for the "flow start" event, reported when the user begins acquiring a product.
    ///
    /// This also serves as the offer-to-acquisition conversion signal.
    /// - Parameter productId: Identifier of the product type being acquired, e.g. `"personal_loan"`, `"deposit_6m"`.
    /// - Returns: A ``FlowStartEventBuilder`` for attaching optional details.
    public static func flowStart(productId: NonEmptyString) -> FlowStartEventBuilder {
        FlowStartEventBuilder(productId: productId)
    }

    /// Creates a builder for a funnel step event, identified by product type.
    /// - Parameters:
    ///   - productId: Identifier of the product type this step belongs to.
    ///   - stepType: Type of the step, e.g. `"parameters"`, `"documents"`, `"scoring"`, `"payment"`.
    /// - Returns: A ``FlowStepEventBuilder`` for attaching optional details.
    public static func flowStep(productId: NonEmptyString, stepType: NonEmptyString) -> FlowStepEventBuilder {
        FlowStepEventBuilder(productId: productId, stepType: stepType)
    }

    /// Creates a builder for a funnel step event, identified by the specific offer variant.
    /// - Parameters:
    ///   - productOfferId: Identifier of the offer variant this step belongs to.
    ///   - stepType: Type of the step, e.g. `"parameters"`, `"documents"`, `"scoring"`, `"payment"`.
    /// - Returns: A ``FlowStepEventBuilder`` for attaching optional details.
    public static func flowStep(productOfferId: NonEmptyString, stepType: NonEmptyString) -> FlowStepEventBuilder {
        FlowStepEventBuilder(productOfferId: productOfferId, stepType: stepType)
    }

    /// Creates a builder for the final funnel result event, identified by product type.
    ///
    /// - Note: If `status` is ``ProductFlowStatus/pending``, a follow-up result event with
    ///   the final status is expected once the asynchronous decision is known.
    /// - Parameters:
    ///   - productId: Identifier of the product type this result belongs to.
    ///   - status: Outcome of the flow.
    /// - Returns: A ``FlowResultEventBuilder`` for attaching optional details.
    public static func flowResult(productId: NonEmptyString, status: ProductFlowStatus) -> FlowResultEventBuilder {
        FlowResultEventBuilder(status: status, productId: productId)
    }

    /// Creates a builder for the final funnel result event, identified by the specific offer variant.
    ///
    /// - Note: If `status` is ``ProductFlowStatus/pending``, a follow-up result event with
    ///   the final status is expected once the asynchronous decision is known.
    /// - Parameters:
    ///   - productOfferId: Identifier of the offer variant this result belongs to.
    ///   - status: Outcome of the flow.
    /// - Returns: A ``FlowResultEventBuilder`` for attaching optional details.
    public static func flowResult(productOfferId: NonEmptyString, status: ProductFlowStatus) -> FlowResultEventBuilder {
        FlowResultEventBuilder(status: status, productOfferId: productOfferId)
    }
}
