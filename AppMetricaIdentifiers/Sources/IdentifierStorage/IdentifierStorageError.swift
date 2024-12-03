
enum IdentifierStorageError: Error {
    case deviceIDMismatch
    case locked
    case underlying(Error)
    case notImplemented
}
