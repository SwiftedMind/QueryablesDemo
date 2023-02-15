import SwiftUI

struct ContentView: View {
    @Queryable<Bool> var queryable

    var body: some View {
        Button("Query") {
            query()
        }
        .queryableSheet(controlledBy: queryable) { query in
            SheetView {
                query.answer(with: true)
            }
        }
    }

    func query() {
        Task {
            do {
                let result = try await queryable.query()
                print(result)
            } catch {
                print("\(error)")
            }
        }
    }
}

struct SheetView: View {

    @Queryable<Bool> var otherQueryable
    let completion: () -> Void

    var body: some View {
        Button("Answer") {
            completion()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
