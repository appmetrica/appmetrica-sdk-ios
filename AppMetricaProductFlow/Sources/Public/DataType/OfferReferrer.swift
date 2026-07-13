import Foundation

/// Describes the source that caused an offer to be shown to the user.
public struct OfferReferrer {
    /// The kind of source, e.g. `"banner"`, `"button"`, `"notification"`.
    public var type: String?

    /// The identifier of the specific UI element that triggered the offer.
    public var identifier: String?

    /// The name of the screen the offer was shown from.
    public var screen: String?

    /// Creates a referrer.
    /// - Parameters:
    ///   - type: The kind of source, e.g. `"banner"`, `"button"`, `"notification"`.
    ///   - identifier: The identifier of the specific UI element that triggered the offer.
    ///   - screen: The name of the screen the offer was shown from.
    public init(type: String? = nil, identifier: String? = nil, screen: String? = nil) {
        self.type = type
        self.identifier = identifier
        self.screen = screen
    }
}
