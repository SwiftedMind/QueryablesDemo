import SwiftUI

public extension View {
    func queryableSheet<Result, Content: View>(
        controlledBy queryable: Queryable<Result>.Trigger,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (_ query: QueryResolver<Result>) -> Content
    ) -> some View {
        self
            .sheet(isPresented: queryable.isActive, onDismiss: onDismiss) {
                content(queryable.resolver)
                    .onDisappear {
                        queryable.resolver.cancelQueryIfNeeded()
                    }
            }
    }
}

public extension View {
    func queryableOverlay<Result, Content: View>(
        controlledBy queryable: Queryable<Result>.Trigger,
        animation: Animation? = nil,
        @ViewBuilder content: @escaping (_ query: QueryResolver<Result>) -> Content
    ) -> some View {
        self
            .overlay {
                ZStack {
                    if queryable.isActive.wrappedValue {
                        content(queryable.resolver)
                            .onDisappear {
                                queryable.resolver.cancelQueryIfNeeded()
                            }
                    }
                }
                .animation(animation, value: queryable.isActive.wrappedValue)
            }
    }
}
