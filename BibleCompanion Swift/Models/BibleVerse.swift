import Foundation

nonisolated struct BibleVerse: Codable, Identifiable, Hashable, Sendable {

    let book: String
    let chapter: Int
    let verse: Int
    let text: String

    var id: String {
        "\(book)-\(chapter)-\(verse)"
    }

    var reference: String {
        "\(book) \(chapter):\(verse)"
    }
}
