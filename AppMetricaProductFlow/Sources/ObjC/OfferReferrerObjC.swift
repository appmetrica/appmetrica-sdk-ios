import Foundation

/// Objective-C representation of the source that caused an offer to be shown to the user.
///
/// Mirrors ``OfferReferrer``.
@objc(AMAOfferReferrer)
public final class OfferReferrerObjC: NSObject {
    /// The kind of source, e.g. `"banner"`, `"button"`, `"notification"`.
    @objc public var type: String?

    /// The identifier of the specific UI element that triggered the offer.
    @objc public var identifier: String?

    /// The name of the screen the offer was shown from.
    @objc public var screen: String?

    /// Creates a referrer.
    /// - Parameters:
    ///   - type: The kind of source, e.g. `"banner"`, `"button"`, `"notification"`.
    ///   - identifier: The identifier of the specific UI element that triggered the offer.
    ///   - screen: The name of the screen the offer was shown from.
    @objc public init(type: String?, identifier: String?, screen: String?) {
        self.type = type
        self.identifier = identifier
        self.screen = screen
    }

    init(from swift: OfferReferrer) {
        self.type = swift.type
        self.identifier = swift.identifier
        self.screen = swift.screen
    }

    var swiftValue: OfferReferrer {
        OfferReferrer(type: type, identifier: identifier, screen: screen)
    }
}
