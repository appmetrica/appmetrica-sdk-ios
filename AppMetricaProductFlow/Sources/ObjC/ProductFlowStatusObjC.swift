import Foundation

/// Objective-C representation of the final outcome of a product flow.
///
/// Mirrors ``ProductFlowStatus``.
@objc(AMAProductFlowStatus) public enum ProductFlowStatusObjC: Int {
    /// The offer was fulfilled or the product was acquired.
    case success = 0

    /// The flow was rejected by a third party (e.g. a bank or insurer).
    case declined = 1

    /// The flow was accepted and is awaiting an asynchronous decision.
    ///
    /// A follow-up result event with the final status is expected once the decision is known.
    case pending = 2

    /// The user cancelled the flow before completion.
    case cancelled = 3

    /// The offer or session expired.
    case expired = 4

    /// The flow failed due to a technical error.
    case fail = 5
}

extension ProductFlowStatusObjC {
    init(from swift: ProductFlowStatus) {
        switch swift {
        case .success: self = .success
        case .declined: self = .declined
        case .pending: self = .pending
        case .cancelled: self = .cancelled
        case .expired: self = .expired
        case .fail: self = .fail
        }
    }

    var swiftValue: ProductFlowStatus {
        switch self {
        case .success: return .success
        case .declined: return .declined
        case .pending: return .pending
        case .cancelled: return .cancelled
        case .expired: return .expired
        case .fail: return .fail
        @unknown default: return .fail
        }
    }
}
