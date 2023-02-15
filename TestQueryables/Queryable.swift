import SwiftUI

public struct QueryCancellationError: Swift.Error {}

public enum QueryError: Swift.Error {
    case unknown
}

public enum QueryConflictPolicy {
    case cancelPreviousQuery
    case cancelNewQuery
}

@propertyWrapper
public struct Queryable<Result>: DynamicProperty {
    @State var isActive: Bool = false

    public var wrappedValue: Trigger {
        .init(isActive: $isActive, resolver: resolver, buffer: buffer)
    }

    private var buffer: QueryBuffer<Result>

    var resolver: QueryResolver<Result> {
        .init(answerHandler: resumeContinuation(returning:), errorHandler: resumeContinuation(throwing:))
    }

    public init(queryConflictPolicy: QueryConflictPolicy = .cancelNewQuery) {
        buffer = QueryBuffer(queryConflictPolicy: queryConflictPolicy)
    }

    private func resumeContinuation(returning result: Result) {
        Task {
            await buffer.resumeContinuation(returning: result)
            isActive = false
        }
    }

    private func resumeContinuation(throwing error: Error) {
        Task {
            // Catch an unanswered query and cancel it to prevent the stored continuation from leaking.
            if case QueryInternalError.queryAutoCancel = error,
               await buffer.hasContinuation {
                await buffer.resumeContinuation(throwing: QueryCancellationError())
                isActive = false
                return
            }

            await buffer.resumeContinuation(throwing: error)
            isActive = false
        }
    }
}

extension Queryable {
    // This is passed around to control the queries in the views
    public struct Trigger {

        var isActive: Binding<Bool>
        var resolver: QueryResolver<Result>
        private var buffer: QueryBuffer<Result>

        fileprivate init(
            isActive: Binding<Bool>,
            resolver: QueryResolver<Result>,
            buffer: QueryBuffer<Result>
        ) {
            self.isActive = isActive
            self.resolver = resolver
            self.buffer = buffer
        }

        public func query() async throws -> Result {
            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    Task {
                        let couldStore = await buffer.storeContinuation(continuation)
                        if couldStore {
                            isActive.wrappedValue = true
                        }
                    }
                }
            } onCancel: {
                isActive.wrappedValue = false
                Task { await buffer.resumeContinuation(throwing: QueryCancellationError()) }
            }
        }

        public func cancel() {
            isActive.wrappedValue = false
            Task {
                await buffer.resumeContinuation(throwing: QueryCancellationError())
            }
        }

        public var isQuerying: Bool {
            isActive.wrappedValue
        }
    }
}
