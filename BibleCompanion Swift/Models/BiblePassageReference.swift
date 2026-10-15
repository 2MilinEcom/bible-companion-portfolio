import Foundation

struct BiblePassageReference {

    let book: String
    let chapter: Int

    let startVerse: Int?
    let endVerse: Int?


    var verses: [Int] {

        guard let startVerse else {
            return []
        }

        let resolvedEndVerse =
            endVerse ?? startVerse

        guard resolvedEndVerse >= startVerse else {
            return []
        }

        return Array(
            startVerse...resolvedEndVerse
        )
    }
}
