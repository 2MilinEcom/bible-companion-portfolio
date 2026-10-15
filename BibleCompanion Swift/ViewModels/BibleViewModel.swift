import Foundation
import Combine

@MainActor
final class BibleViewModel: ObservableObject {

    @Published private(set) var isLoading = true
    @Published var verses: [BibleVerse] = []
    @Published var searchText = ""
    @Published var errorMessage: String?

    private let bibleService: BibleService


    init(
        bibleService: BibleService? = nil
    ) {

        self.bibleService =
            bibleService ?? BibleService.shared

        Task { await loadBible() }
    }


    // MARK: - Books

    var books: [BibleBook] {

        bibleService.books(
            verses: verses
        )
    }


    var oldTestamentBooks: [BibleBook] {

        books.filter {
            $0.testament == .old
        }
    }


    var newTestamentBooks: [BibleBook] {

        books.filter {
            $0.testament == .new
        }
    }


    // MARK: - Search

    var searchResults: [BibleVerse] {

        bibleService.search(
            query: searchText,
            verses: verses
        )
    }


    // MARK: - Chapters

    func chapters(
        for book: String
    ) -> [Int] {

        bibleService.chapters(
            book: book,
            verses: verses
        )
    }


    func chapter(
        book: String,
        chapter: Int
    ) -> [BibleVerse] {

        bibleService.chapter(
            book: book,
            chapter: chapter,
            verses: verses
        )
    }


    // MARK: - Load Bible

    private func loadBible() async {
        defer { isLoading = false }

        do {

            verses =
                try await bibleService.preload()

        } catch {

            errorMessage =
                error.localizedDescription
        }
    }
}
