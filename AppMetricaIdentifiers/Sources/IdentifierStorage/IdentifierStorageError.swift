
enum IdentifierStorageError: Error {
    case deviceIDMismatch
    case locked
    case corrupted(Error)
    case underlying(Error)
    case notImplemented
}
