import Foundation

public struct QueryResolver<Result> {

    private let answerHandler: (Result) -> Void
    private let cancelHandler: (Error) -> Void

    init(
        answerHandler: @escaping (Result) -> Void,
        errorHandler: @escaping (Error) -> Void
    ) {
        self.answerHandler = answerHandler
        self.cancelHandler = errorHandler
    }

    public func answer(with result: Result) {
        answerHandler(result)
    }

    public func answer(withOptional optionalResult: Result?) {
        if let optionalResult {
            answerHandler(optionalResult)
        } else {
            cancelQuery()
        }
    }

    public func answer() where Result == Void {
        answerHandler(())
    }

    public func answer(throwing error: Error) {
        cancelHandler(error)
    }

    public func cancelQuery() {
        cancelHandler(QueryCancellationError())
    }

    func cancelQueryIfNeeded() {
        cancelHandler(QueryInternalError.queryAutoCancel)
    }
}

enum QueryInternalError: Swift.Error {
    case queryAutoCancel
}
