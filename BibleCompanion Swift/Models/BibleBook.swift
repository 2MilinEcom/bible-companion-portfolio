import Foundation

enum Testament: String, Codable {
    case old = "Old Testament"
    case new = "New Testament"
}

struct BibleBook: Identifiable, Hashable {
    let name: String
    let testament: Testament
    let order: Int

    var id: String {
        name
    }
}
