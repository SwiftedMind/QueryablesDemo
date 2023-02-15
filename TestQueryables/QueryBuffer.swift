import Foundation

final actor QueryBuffer<Result> {
    private let queryConflictPolicy: QueryConflictPolicy
    private var continuation: CheckedContinuation<Result, Swift.Error>?

    init(queryConflictPolicy: QueryConflictPolicy) {
        self.queryConflictPolicy = queryConflictPolicy
    }

    var hasContinuation: Bool {
        continuation != nil
    }

    @discardableResult
    func storeContinuation(_ continuation: CheckedContinuation<Result, Swift.Error>) -> Bool {
        if self.continuation != nil {
            switch queryConflictPolicy {
            case .cancelPreviousQuery:
                self.continuation?.resume(throwing: QueryCancellationError())
                self.continuation = nil
                return false
            case .cancelNewQuery:
                continuation.resume(throwing: QueryCancellationError())
                return false
            }
        }

        self.continuation = continuation
        return true
    }

    func resumeContinuation(returning result: Result) {
        continuation?.resume(returning: result)
        continuation = nil
    }

    func resumeContinuation(throwing error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
