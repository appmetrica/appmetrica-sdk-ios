import Foundation

/// A `String` wrapper that is guaranteed to never be empty.
///
/// Used for product flow identifiers (product ID, offer ID, step type, ...) that must
/// always carry a value.
public struct NonEmptyString: Hashable, Sendable {
    /// The wrapped, guaranteed non-empty string.
    public let rawValue: String

    /// Creates a non-empty string.
    /// - Parameter rawValue: The string to wrap.
    /// - Returns: `nil` if `rawValue` is empty.
    public init?(_ rawValue: String) {
        guard !rawValue.isEmpty else { return nil }
        self.rawValue = rawValue
    }
}

extension NonEmptyString: ExpressibleByStringLiteral {
    /// Creates a non-empty string from a string literal.
    /// - Precondition: `value` must not be empty.
    public init(stringLiteral value: String) {
        precondition(!value.isEmpty, "NonEmptyString literal must not be empty")
        self.rawValue = value
    }
}

extension NonEmptyString: CustomStringConvertible {
    /// The wrapped string value.
    public var description: String { rawValue }
}
