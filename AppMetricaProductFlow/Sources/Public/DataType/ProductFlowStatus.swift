import Foundation

/// The final outcome of a product flow, reported with ``FlowResultEventBuilder``.
public enum ProductFlowStatus {
    /// The offer was fulfilled or the product was acquired.
    case success

    /// The flow was rejected by a third party (e.g. a bank or insurer).
    case declined

    /// The flow was accepted and is awaiting an asynchronous decision.
    ///
    /// A follow-up result event with the final status is expected once the decision is known.
    case pending

    /// The user cancelled the flow before completion.
    case cancelled

    /// The offer or session expired.
    case expired

    /// The flow failed due to a technical error.
    case fail
}
