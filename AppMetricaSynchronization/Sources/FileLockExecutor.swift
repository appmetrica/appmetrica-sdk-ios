import Foundation

@objc(AMAExclusiveLocking)
public protocol ExclusiveLocking: NSObjectProtocol {
    @objc(performWithExclusiveLock:)
    func perform(withExclusiveLock body: () -> Void) -> Bool
}

/// Blocking flock wrapper for ObjC callers.
/// Returns true only when body ran under a successfully acquired exclusive lock.
@objc(AMAFileLockExecutor)
public final class FileLockExecutor: NSObject, ExclusiveLocking {
    private let factory: FileLockFactory

    @objc(initWithFilePath:)
    public init(filePath: String) {
        let path = URL(fileURLWithPath: filePath).standardizedFileURL.path
        self.factory = FileLockFactory(filePath: path)
        super.init()
    }

    @objc(performWithExclusiveLock:)
    public func perform(withExclusiveLock body: () -> Void) -> Bool {
        let directory = (factory.filePath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(
            atPath: directory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        guard let fileLock = try? factory.open() else {
            return false
        }

        do {
            try fileLock.lockExclusiveOrThrow()
        } catch {
            return false
        }

        defer { fileLock.unlock() }
        body()
        return true
    }
}
