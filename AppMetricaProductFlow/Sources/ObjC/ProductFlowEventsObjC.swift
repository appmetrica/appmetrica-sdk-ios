import Foundation

/// Objective-C entry point for building AppMetrica product flow events.
///
/// Mirrors ``ProductFlowEvents``: each factory method returns a builder for attaching
/// optional details before calling `build` to obtain an `AppMetricaEvent`. Methods return
/// `nil` when a required string identifier is empty.
@objc(AMAProductFlowEvents)
public final class ProductFlowEventsObjC: NSObject {
    private override init() {}

    /// Creates a builder for the "offer shown" event, reported when an offer is displayed to the user.
    /// - Parameters:
    ///   - productOfferId: Identifier of the specific offer variant that was shown. Must not be empty.
    ///   - offerType: Type of the offer, e.g. `"financial_product"`, `"insurance"`, `"subscription"`.
    ///     Must not be empty.
    /// - Returns: A ``OfferShownEventBuilderObjC``, or `nil` if `productOfferId` or `offerType` is empty.
    @objc(offerShownWithProductOfferId:offerType:)
    public class func offerShown(productOfferId: String, offerType: String) -> OfferShownEventBuilderObjC? {
        guard let productOfferId = NonEmptyString(productOfferId),
              let offerType = NonEmptyString(offerType) else { return nil }
        return OfferShownEventBuilderObjC(
            swiftBuilder: ProductFlowEvents.offerShown(productOfferId: productOfferId, offerType: offerType)
        )
    }

    /// Creates a builder for the "flow start" event, reported when the user begins acquiring a product.
    ///
    /// This also serves as the offer-to-acquisition conversion signal.
    /// - Parameter productId: Identifier of the product type being acquired, e.g. `"personal_loan"`,
    ///   `"deposit_6m"`. Must not be empty.
    /// - Returns: A ``FlowStartEventBuilderObjC``, or `nil` if `productId` is empty.
    @objc(flowStartWithProductId:)
    public class func flowStart(productId: String) -> FlowStartEventBuilderObjC? {
        guard let productId = NonEmptyString(productId) else { return nil }
        return FlowStartEventBuilderObjC(
            swiftBuilder: ProductFlowEvents.flowStart(productId: productId)
        )
    }

    /// Creates a builder for a funnel step event, identified by product type.
    /// - Parameters:
    ///   - productId: Identifier of the product type this step belongs to. Must not be empty.
    ///   - stepType: Type of the step, e.g. `"parameters"`, `"documents"`, `"scoring"`, `"payment"`.
    ///     Must not be empty.
    /// - Returns: A ``FlowStepEventBuilderObjC``, or `nil` if `productId` or `stepType` is empty.
    @objc(flowStepWithProductId:stepType:)
    public class func flowStep(productId: String, stepType: String) -> FlowStepEventBuilderObjC? {
        guard let productId = NonEmptyString(productId),
              let stepType = NonEmptyString(stepType) else { return nil }
        return FlowStepEventBuilderObjC(
            swiftBuilder: ProductFlowEvents.flowStep(productId: productId, stepType: stepType)
        )
    }

    /// Creates a builder for a funnel step event, identified by the specific offer variant.
    /// - Parameters:
    ///   - productOfferId: Identifier of the offer variant this step belongs to. Must not be empty.
    ///   - stepType: Type of the step, e.g. `"parameters"`, `"documents"`, `"scoring"`, `"payment"`.
    ///     Must not be empty.
    /// - Returns: A ``FlowStepEventBuilderObjC``, or `nil` if `productOfferId` or `stepType` is empty.
    @objc(flowStepWithProductOfferId:stepType:)
    public class func flowStep(productOfferId: String, stepType: String) -> FlowStepEventBuilderObjC? {
        guard let productOfferId = NonEmptyString(productOfferId),
              let stepType = NonEmptyString(stepType) else { return nil }
        return FlowStepEventBuilderObjC(
            swiftBuilder: ProductFlowEvents.flowStep(productOfferId: productOfferId, stepType: stepType)
        )
    }

    /// Creates a builder for the final funnel result event, identified by product type.
    ///
    /// - Note: If `status` is ``ProductFlowStatusObjC/pending``, a follow-up result event with
    ///   the final status is expected once the asynchronous decision is known.
    /// - Parameters:
    ///   - productId: Identifier of the product type this result belongs to. Must not be empty.
    ///   - status: Outcome of the flow.
    /// - Returns: A ``FlowResultEventBuilderObjC``, or `nil` if `productId` is empty.
    @objc(flowResultWithProductId:status:)
    public class func flowResult(productId: String, status: ProductFlowStatusObjC) -> FlowResultEventBuilderObjC? {
        guard let productId = NonEmptyString(productId) else { return nil }
        return FlowResultEventBuilderObjC(
            swiftBuilder: ProductFlowEvents.flowResult(productId: productId, status: status.swiftValue)
        )
    }

    /// Creates a builder for the final funnel result event, identified by the specific offer variant.
    ///
    /// - Note: If `status` is ``ProductFlowStatusObjC/pending``, a follow-up result event with
    ///   the final status is expected once the asynchronous decision is known.
    /// - Parameters:
    ///   - productOfferId: Identifier of the offer variant this result belongs to. Must not be empty.
    ///   - status: Outcome of the flow.
    /// - Returns: A ``FlowResultEventBuilderObjC``, or `nil` if `productOfferId` is empty.
    @objc(flowResultForOfferWithProductOfferId:status:)
    public class func flowResultForOffer(productOfferId: String, status: ProductFlowStatusObjC) -> FlowResultEventBuilderObjC? {
        guard let productOfferId = NonEmptyString(productOfferId) else { return nil }
        return FlowResultEventBuilderObjC(
            swiftBuilder: ProductFlowEvents.flowResult(productOfferId: productOfferId, status: status.swiftValue)
        )
    }
}
