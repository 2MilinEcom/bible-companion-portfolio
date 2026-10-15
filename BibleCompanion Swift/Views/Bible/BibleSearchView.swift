import SwiftUI

struct BibleSearchView: View {
    var body: some View { BibleExplorerView() }
}

struct BibleBookRow: View {
    let book: BibleBook
    var body: some View {
        Label(book.name, systemImage: "book.closed")
            .padding(.vertical, 3)
    }
}
