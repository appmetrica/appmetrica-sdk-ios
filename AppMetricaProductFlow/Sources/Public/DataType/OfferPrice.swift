import Foundation

/// A monetary or in-game amount attached to a product flow event.
public struct OfferPrice {
    /// The numeric amount.
    public var amount: Decimal

    /// The unit of the amount: an ISO 4217 currency code (e.g. `"USD"`, `"RUB"`) or an
    /// internal unit (e.g. `"gold"`, `"points"`).
    public var unit: String

    /// Creates a price.
    /// - Parameters:
    ///   - amount: The numeric amount.
    ///   - unit: The unit of the amount: an ISO 4217 currency code or an internal unit.
    public init(amount: Decimal, unit: String) {
        self.amount = amount
        self.unit = unit
    }

}
