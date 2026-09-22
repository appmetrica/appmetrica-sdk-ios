import Foundation
import XCTest
@testable import AppMetricaSynchronization

final class FileLockExecutorTests: XCTestCase {

    private var lockPath: String!

    override func setUp() {
        super.setUp()
        lockPath = NSTemporaryDirectory() + "file-lock-executor-\(UUID().uuidString).lock"
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: lockPath)
        super.tearDown()
    }

    func testPerformReturnsFalseWhenOpenFails() {
        let parentFile = NSTemporaryDirectory() + "file-lock-parent-\(UUID().uuidString)"
        FileManager.default.createFile(atPath: parentFile, contents: Data(), attributes: nil)
        defer { try? FileManager.default.removeItem(atPath: parentFile) }

        let badPath = (parentFile as NSString).appendingPathComponent("configuration.lock")
        let executor = FileLockExecutor(filePath: badPath)

        let bodyCalled = LockedBool()
        let locked = executor.perform(withExclusiveLock: {
            bodyCalled.value = true
        })

        XCTAssertFalse(locked)
        XCTAssertFalse(bodyCalled.value)
    }

    func testWaitingCallerContinuesAfterUnlock() {
        let first = FileLockExecutor(filePath: lockPath)
        let second = FileLockExecutor(filePath: lockPath)

        let enteredFirst = DispatchSemaphore(value: 0)
        let resumeFirst = DispatchSemaphore(value: 0)
        let secondDone = DispatchSemaphore(value: 0)

        let secondLocked = LockedBool()
        let secondBodyCalled = LockedBool()

        DispatchQueue.global(qos: .userInitiated).async {
            let locked = first.perform(withExclusiveLock: {
                enteredFirst.signal()
                resumeFirst.wait()
            })
            XCTAssertTrue(locked)
        }

        XCTAssertEqual(enteredFirst.wait(timeout: .now() + 5), .success)

        DispatchQueue.global(qos: .userInitiated).async {
            secondLocked.value = second.perform(withExclusiveLock: {
                secondBodyCalled.value = true
            })
            secondDone.signal()
        }

        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))
        XCTAssertEqual(secondDone.wait(timeout: .now()), .timedOut)

        resumeFirst.signal()
        XCTAssertEqual(secondDone.wait(timeout: .now() + 5), .success)
        XCTAssertTrue(secondLocked.value)
        XCTAssertTrue(secondBodyCalled.value)
    }
}

private final class LockedBool: @unchecked Sendable {
    private let lock = NSLock()
    private var _value = false

    var value: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _value = newValue
        }
    }
}
