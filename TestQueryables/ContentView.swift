import SwiftUI

struct ContentView: View {
    @Queryable<Bool> var queryable
    @State var isShowingInnerView: Bool = false

    var body: some View {
        NavigationStack {
            VStack {
                Button("Query") {
                    query()
                }
                NavigationLink {
                    InnerView(queryable: queryable)
                } label: {
                    Text("Show Inner View")
                }
            }
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

struct InnerView: View {
    var queryable: Queryable<Bool>.Trigger

    var body: some View {
        Button("Query from here") {
            query()
        }
    }

    func query() {
        Task {
            do {
                let result = try await queryable.query()
                print("Inner result: \(result)")
            } catch {
                print("Inner error: \(error)")
            }
        }
    }
}


struct SheetView: View {
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
