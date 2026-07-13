import Foundation

/// Objective-C representation of a monetary or in-game amount attached to a product flow event.
///
/// Mirrors ``OfferPrice``.
@objc(AMAOfferPrice)
public final class OfferPriceObjC: NSObject {
    /// The numeric amount.
    @objc @NSCopying public var amount: NSDecimalNumber

    /// The unit of the amount: an ISO 4217 currency code (e.g. `"USD"`, `"RUB"`) or an
    /// internal unit (e.g. `"gold"`, `"points"`).
    @objc public var unit: String

    /// Creates a price.
    /// - Parameters:
    ///   - amount: The numeric amount.
    ///   - unit: The unit of the amount: an ISO 4217 currency code or an internal unit.
    @objc public init(amount: NSDecimalNumber, unit: String) {
        self.amount = amount
        self.unit = unit
    }

    init(from swift: OfferPrice) {
        self.amount = NSDecimalNumber(decimal: swift.amount)
        self.unit = swift.unit
    }

    var swiftValue: OfferPrice {
        OfferPrice(amount: amount.decimalValue, unit: unit)
    }
}
