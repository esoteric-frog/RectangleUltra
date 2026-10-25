@_exported import Foundation // XCTest re-exports Foundation; tests rely on it
import Testing

/// Minimal XCTest stand-in so upstream tests run on Swift Testing (no Xcode on this Mac).
/// Implements only what RectangleTests uses.
open class XCTestCase {
    public required init() {}
    open func setUp() {}
    open func setUpWithError() throws {}
    open func tearDown() {}
    open func tearDownWithError() throws {}

    /// Runs one test method with XCTest's setUp/tearDown order. XCTSkip becomes a Swift Testing cancel (skip).
    ///
    /// Like XCTest, the body runs on the main thread from a run-loop callout, not from inside a main-queue
    /// job (which is what @MainActor would give). That matters for `wait(for:)`: a nested run loop only
    /// drains `DispatchQueue.main` when the caller is not already a main-queue job. Failures are buffered
    /// there and recorded back here, where Swift Testing's task-local test context exists.
    public static func runTest<T: XCTestCase>(_ type: T.Type, _ body: @escaping (T) throws -> Void) async throws {
        let outcome: Outcome = await withCheckedContinuation { done in
            CFRunLoopPerformBlock(CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue) {
                pendingFailures = []
                let thrown = run(T(), body)
                done.resume(returning: Outcome(failures: pendingFailures ?? [], thrown: thrown))
                pendingFailures = nil
            }
            CFRunLoopWakeUp(CFRunLoopGetMain())
        }
        for f in outcome.failures { Issue.record(f.comment, sourceLocation: f.location) }
        if let error = outcome.thrown { try handle(error) }
    }

    /// Async test methods (2 in the suite). The generated wrapper is @MainActor; this runs on that actor.
    public static func runAsyncTest<T: XCTestCase>(_ type: T.Type, isolation: isolated (any Actor)? = #isolation,
                                                   _ body: (T) async throws -> Void) async throws {
        let test = T()
        var thrown: Error?
        do {
            try test.setUpWithError()
            test.setUp()
            try await body(test)
        } catch { thrown = error }
        if let error = test.finish(), thrown == nil { thrown = error }
        if let error = thrown { try handle(error) }
    }

    private static func run<T: XCTestCase>(_ test: T, _ body: (T) throws -> Void) -> Error? {
        var thrown: Error?
        do {
            try test.setUpWithError()
            test.setUp()
            try body(test)
        } catch { thrown = error }
        if let error = test.finish(), thrown == nil { thrown = error }
        return thrown
    }

    private func finish() -> Error? {
        tearDown()
        do { try tearDownWithError() } catch { return error }
        return nil
    }

    private static func handle(_ error: Error) throws {
        switch error {
        case let skip as XCTSkip: try Test.cancel(skip.message.map { Comment(rawValue: $0) })
        case is XCTUnwrapError: return // already recorded at the XCTUnwrap call site
        default: throw error
        }
    }

    // MARK: expectations

    public func expectation(description: String) -> XCTestExpectation {
        XCTestExpectation(description: description)
    }

    /// Spins the current run loop (main queue drains) until all are fulfilled or the timeout passes.
    public func wait(for expectations: [XCTestExpectation], timeout: TimeInterval,
                     file: StaticString = #filePath, line: UInt = #line) {
        let deadline = Date().addingTimeInterval(timeout)
        func done() -> Bool { expectations.allSatisfy { $0.isInverted || $0.isFulfilled } }
        while !done() && Date() < deadline {
            RunLoop.current.run(mode: .default, before: min(deadline, Date().addingTimeInterval(0.005)))
        }
        // Inverted expectations need the full timeout to prove nothing fulfilled them.
        if expectations.contains(where: \.isInverted) {
            while Date() < deadline { RunLoop.current.run(mode: .default, before: deadline) }
        }
        for e in expectations {
            if e.isInverted && e.isFulfilled {
                fail("Asynchronous wait failed: Fulfilled inverted expectation \"\(e.description)\"", "", file, line)
            } else if !e.isInverted && !e.isFulfilled {
                fail("Asynchronous wait failed: Exceeded timeout of \(timeout) seconds, with unfulfilled expectations: \"\(e.description)\"", "", file, line)
            }
        }
    }
}

public final class XCTestExpectation: @unchecked Sendable {
    public let description: String
    public var isInverted = false
    private let lock = NSLock()
    private var fulfilled = false
    init(description: String) { self.description = description }
    var isFulfilled: Bool { lock.withLock { fulfilled } }
    public func fulfill() { lock.withLock { fulfilled = true } }
}

public struct XCTSkip: Error {
    public let message: String?
    public init(_ message: String? = nil) { self.message = message }
}

struct XCTUnwrapError: Error {}

struct Failure { let comment: Comment; let location: SourceLocation }
struct Outcome: @unchecked Sendable { let failures: [Failure]; let thrown: Error? }

/// Non-nil while a sync test body runs on the main run loop (main thread only; tests run serially).
nonisolated(unsafe) var pendingFailures: [Failure]?

func fail(_ text: String, _ message: String, _ file: StaticString, _ line: UInt) {
    let path = "\(file)"
    let name = (path as NSString).lastPathComponent
    let comment = message.isEmpty ? text : "\(text) - \(message)"
    let failure = Failure(comment: Comment(rawValue: comment),
                          location: SourceLocation(fileID: "RectangleTests/\(name)", filePath: path,
                                                   line: Int(line), column: 1))
    if pendingFailures != nil { pendingFailures!.append(failure) }
    else { Issue.record(failure.comment, sourceLocation: failure.location) }
}

private func check(_ name: String, _ message: () -> String, _ file: StaticString, _ line: UInt,
                   _ body: () throws -> String?) {
    do { if let text = try body() { fail("\(name) failed: \(text)", message(), file, line) } }
    catch { fail("\(name) threw error \"\(error)\"", message(), file, line) }
}

public func XCTAssertEqual<T: Equatable>(_ a: @autoclosure () throws -> T, _ b: @autoclosure () throws -> T,
                                         _ message: @autoclosure () -> String = "",
                                         file: StaticString = #filePath, line: UInt = #line) {
    check("XCTAssertEqual", message, file, line) {
        let (x, y) = (try a(), try b())
        return x == y ? nil : "(\"\(x)\") is not equal to (\"\(y)\")"
    }
}

public func XCTAssertEqual<T: FloatingPoint>(_ a: @autoclosure () throws -> T, _ b: @autoclosure () throws -> T,
                                             accuracy: T, _ message: @autoclosure () -> String = "",
                                             file: StaticString = #filePath, line: UInt = #line) {
    check("XCTAssertEqual", message, file, line) {
        let (x, y) = (try a(), try b())
        return abs(x - y) <= accuracy ? nil : "(\"\(x)\") is not equal to (\"\(y)\") +/- (\"\(accuracy)\")"
    }
}

public func XCTAssertNotEqual<T: Equatable>(_ a: @autoclosure () throws -> T, _ b: @autoclosure () throws -> T,
                                            _ message: @autoclosure () -> String = "",
                                            file: StaticString = #filePath, line: UInt = #line) {
    check("XCTAssertNotEqual", message, file, line) {
        let (x, y) = (try a(), try b())
        return x != y ? nil : "(\"\(x)\") is equal to (\"\(y)\")"
    }
}

private func compare<T: Comparable>(_ name: String, _ op: String, _ ok: (T, T) -> Bool,
                                    _ a: () throws -> T, _ b: () throws -> T,
                                    _ message: () -> String, _ file: StaticString, _ line: UInt) {
    check(name, message, file, line) {
        let (x, y) = (try a(), try b())
        return ok(x, y) ? nil : "(\"\(x)\") is not \(op) (\"\(y)\")"
    }
}

public func XCTAssertGreaterThan<T: Comparable>(_ a: @autoclosure () throws -> T, _ b: @autoclosure () throws -> T,
                                                _ message: @autoclosure () -> String = "",
                                                file: StaticString = #filePath, line: UInt = #line) {
    compare("XCTAssertGreaterThan", "greater than", (>), a, b, message, file, line)
}

public func XCTAssertGreaterThanOrEqual<T: Comparable>(_ a: @autoclosure () throws -> T, _ b: @autoclosure () throws -> T,
                                                       _ message: @autoclosure () -> String = "",
                                                       file: StaticString = #filePath, line: UInt = #line) {
    compare("XCTAssertGreaterThanOrEqual", "greater than or equal to", (>=), a, b, message, file, line)
}

public func XCTAssertLessThan<T: Comparable>(_ a: @autoclosure () throws -> T, _ b: @autoclosure () throws -> T,
                                             _ message: @autoclosure () -> String = "",
                                             file: StaticString = #filePath, line: UInt = #line) {
    compare("XCTAssertLessThan", "less than", (<), a, b, message, file, line)
}

public func XCTAssertLessThanOrEqual<T: Comparable>(_ a: @autoclosure () throws -> T, _ b: @autoclosure () throws -> T,
                                                    _ message: @autoclosure () -> String = "",
                                                    file: StaticString = #filePath, line: UInt = #line) {
    compare("XCTAssertLessThanOrEqual", "less than or equal to", (<=), a, b, message, file, line)
}

public func XCTAssertTrue(_ e: @autoclosure () throws -> Bool, _ message: @autoclosure () -> String = "",
                          file: StaticString = #filePath, line: UInt = #line) {
    check("XCTAssertTrue", message, file, line) { try e() ? nil : "" }
}

public func XCTAssertFalse(_ e: @autoclosure () throws -> Bool, _ message: @autoclosure () -> String = "",
                           file: StaticString = #filePath, line: UInt = #line) {
    check("XCTAssertFalse", message, file, line) { try e() ? "" : nil }
}

public func XCTAssertNil(_ e: @autoclosure () throws -> Any?, _ message: @autoclosure () -> String = "",
                         file: StaticString = #filePath, line: UInt = #line) {
    check("XCTAssertNil", message, file, line) { try e().map { "\"\($0)\"" } }
}

public func XCTAssertNotNil(_ e: @autoclosure () throws -> Any?, _ message: @autoclosure () -> String = "",
                            file: StaticString = #filePath, line: UInt = #line) {
    check("XCTAssertNotNil", message, file, line) { try e() == nil ? "" : nil }
}

public func XCTUnwrap<T>(_ e: @autoclosure () throws -> T?, _ message: @autoclosure () -> String = "",
                         file: StaticString = #filePath, line: UInt = #line) throws -> T {
    guard let v = try e() else {
        fail("XCTUnwrap failed: expected non-nil value of type \"\(T.self)\"", message(), file, line)
        throw XCTUnwrapError()
    }
    return v
}

public func XCTFail(_ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    fail("failed", message, file, line)
}

public func XCTSkipUnless(_ e: @autoclosure () throws -> Bool, _ message: @autoclosure () -> String? = nil,
                          file: StaticString = #filePath, line: UInt = #line) throws {
    if try !e() { throw XCTSkip(message()) }
}
