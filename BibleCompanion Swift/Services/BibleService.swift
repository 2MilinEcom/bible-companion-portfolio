import Foundation

final class BibleService {

    static let shared = BibleService()

    private init() {}


    // MARK: - Canonical Book Order

    private let oldTestamentNames = [
        "Genesis",
        "Exodus",
        "Leviticus",
        "Numbers",
        "Deuteronomy",
        "Joshua",
        "Judges",
        "Ruth",
        "1 Samuel",
        "2 Samuel",
        "1 Kings",
        "2 Kings",
        "1 Chronicles",
        "2 Chronicles",
        "Ezra",
        "Nehemiah",
        "Esther",
        "Job",
        "Psalms",
        "Proverbs",
        "Ecclesiastes",
        "Song of Solomon",
        "Isaiah",
        "Jeremiah",
        "Lamentations",
        "Ezekiel",
        "Daniel",
        "Hosea",
        "Joel",
        "Amos",
        "Obadiah",
        "Jonah",
        "Micah",
        "Nahum",
        "Habakkuk",
        "Zephaniah",
        "Haggai",
        "Zechariah",
        "Malachi"
    ]


    private let newTestamentNames = [
        "Matthew",
        "Mark",
        "Luke",
        "John",
        "Acts",
        "Romans",
        "1 Corinthians",
        "2 Corinthians",
        "Galatians",
        "Ephesians",
        "Philippians",
        "Colossians",
        "1 Thessalonians",
        "2 Thessalonians",
        "1 Timothy",
        "2 Timothy",
        "Titus",
        "Philemon",
        "Hebrews",
        "James",
        "1 Peter",
        "2 Peter",
        "1 John",
        "2 John",
        "3 John",
        "Jude",
        "Revelation"
    ]


    private var allBookNames: [String] {
        oldTestamentNames
        +
        newTestamentNames
    }


    // MARK: - Load Bible

    private var cachedVerses: [BibleVerse]?
    private var loadingTask: Task<[BibleVerse], Error>?

    /// Coalesces concurrent loads and decodes once, away from keyboard/UI work.
    func preload() async throws -> [BibleVerse] {
        if let cachedVerses { return cachedVerses }
        let task: Task<[BibleVerse], Error>
        if let loadingTask {
            task = loadingTask
        } else {
            let url = try bibleURL()
            task = Task.detached(priority: .userInitiated) {
                try Self.decodeBible(at: url)
            }
            loadingTask = task
        }
        do {
            let verses = try await task.value
            cachedVerses = verses
            loadingTask = nil
            return verses
        } catch {
            loadingTask = nil
            throw error
        }
    }

    func loadBible() throws -> [BibleVerse] {
        if let cachedVerses { return cachedVerses }
        let verses = try Self.decodeBible(at: bibleURL())
        cachedVerses = verses
        return verses
    }

    private func bibleURL() throws -> URL {
        guard let url = Bundle.main.url(forResource: "bible", withExtension: "json") else {
            throw NSError(domain: "BibleService", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "The bundled Bible could not be found."])
        }
        return url
    }

    nonisolated private static func decodeBible(at url: URL) throws -> [BibleVerse] {
        try JSONDecoder().decode([BibleVerse].self, from: Data(contentsOf: url))
    }


    // MARK: - Books

    func books(
        verses: [BibleVerse]
    ) -> [BibleBook] {

        let availableBooks = Set(
            verses.map {
                $0.book
            }
        )


        var result: [BibleBook] = []


        for (
            index,
            name
        ) in oldTestamentNames.enumerated() {

            if availableBooks.contains(
                name
            ) {

                result.append(
                    BibleBook(
                        name: name,
                        testament: .old,
                        order: index
                    )
                )
            }
        }


        let offset =
            oldTestamentNames.count


        for (
            index,
            name
        ) in newTestamentNames.enumerated() {

            if availableBooks.contains(
                name
            ) {

                result.append(
                    BibleBook(
                        name: name,
                        testament: .new,
                        order:
                            offset
                            +
                            index
                    )
                )
            }
        }


        return result.sorted {
            $0.order < $1.order
        }
    }


    // MARK: - Chapters

    func chapters(
        book: String,
        verses: [BibleVerse]
    ) -> [Int] {

        let canonicalBook =
            canonicalBookName(
                book
            )
            ??
            book


        let chapters = Set(

            verses

                .filter {

                    $0.book
                        .caseInsensitiveCompare(
                            canonicalBook
                        )
                    ==
                    .orderedSame
                }

                .map {
                    $0.chapter
                }
        )


        return chapters.sorted()
    }


    // MARK: - Chapter Verses

    func chapter(
        book: String,
        chapter: Int,
        verses: [BibleVerse]
    ) -> [BibleVerse] {

        let canonicalBook =
            canonicalBookName(
                book
            )
            ??
            book


        return verses

            .filter {

                $0.book
                    .caseInsensitiveCompare(
                        canonicalBook
                    )
                ==
                .orderedSame

                &&

                $0.chapter
                ==
                chapter
            }

            .sorted {
                $0.verse < $1.verse
            }
    }


    // MARK: - Search

    func search(
        query: String,
        verses: [BibleVerse]
    ) -> [BibleVerse] {

        let cleaned =
            query.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )


        guard !cleaned.isEmpty else {
            return []
        }


        // First try treating the search
        // as a Bible reference.
        //
        // Examples:
        //
        // John 3
        // John 3:16
        // John 3:16-18
        // 1 Peter 3:21
        // Psalm 23

        if let reference =
            parsePassageRange(
                cleaned
            ) {

            return verses

                .filter { verse in

                    let sameBook =

                        verse.book
                            .caseInsensitiveCompare(
                                reference.book
                            )
                        ==
                        .orderedSame


                    let sameChapter =

                        verse.chapter
                        ==
                        reference.chapter


                    guard
                        sameBook,
                        sameChapter
                    else {

                        return false
                    }


                    // Chapter-only search:
                    //
                    // John 3
                    //
                    // Return every verse
                    // in the chapter.

                    guard let start =
                        reference.startVerse
                    else {

                        return true
                    }


                    let end =
                        reference.endVerse
                        ??
                        start


                    return verse.verse >= start
                        &&
                        verse.verse <= end
                }

                .sorted {
                    $0.verse < $1.verse
                }
        }


        // Otherwise search verse text.

        return verses.filter {

            $0.text
                .localizedCaseInsensitiveContains(
                    cleaned
                )
        }
    }


    // MARK: - Canonical Book Name

    private func canonicalBookName(
        _ rawBook: String
    ) -> String? {

        let cleaned =

            rawBook

                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

                .split(
                    whereSeparator: {
                        $0.isWhitespace
                    }
                )

                .joined(
                    separator: " "
                )


        guard !cleaned.isEmpty else {
            return nil
        }


        // First check the exact
        // canonical book list.

        if let exactMatch =
            allBookNames.first(
                where: {

                    $0.caseInsensitiveCompare(
                        cleaned
                    )
                    ==
                    .orderedSame
                }
            ) {

            return exactMatch
        }


        let lowercase =
            cleaned.lowercased()


        // Common alternative names
        // and abbreviations the AI,
        // users, or other Bible sources
        // may produce.

        let aliases: [String: String] = [

            // Genesis
            "gen":
                "Genesis",
            "gen.":
                "Genesis",

            // Exodus
            "ex":
                "Exodus",
            "exod":
                "Exodus",
            "exod.":
                "Exodus",

            // Leviticus
            "lev":
                "Leviticus",
            "lev.":
                "Leviticus",

            // Numbers
            "num":
                "Numbers",
            "num.":
                "Numbers",
            "nums":
                "Numbers",

            // Deuteronomy
            "deut":
                "Deuteronomy",
            "deut.":
                "Deuteronomy",

            // Psalms
            "psalm":
                "Psalms",
            "psalms":
                "Psalms",
            "ps":
                "Psalms",
            "ps.":
                "Psalms",

            // Proverbs
            "prov":
                "Proverbs",
            "prov.":
                "Proverbs",

            // Ecclesiastes
            "eccl":
                "Ecclesiastes",
            "eccl.":
                "Ecclesiastes",
            "ecc":
                "Ecclesiastes",

            // Song of Solomon
            "song of songs":
                "Song of Solomon",
            "song of solomon":
                "Song of Solomon",
            "canticles":
                "Song of Solomon",

            // Isaiah
            "isa":
                "Isaiah",
            "isa.":
                "Isaiah",

            // Jeremiah
            "jer":
                "Jeremiah",
            "jer.":
                "Jeremiah",

            // Ezekiel
            "ezek":
                "Ezekiel",
            "ezek.":
                "Ezekiel",

            // Daniel
            "dan":
                "Daniel",
            "dan.":
                "Daniel",

            // Matthew
            "matt":
                "Matthew",
            "matt.":
                "Matthew",
            "gospel of matthew":
                "Matthew",

            // Mark
            "mk":
                "Mark",
            "mk.":
                "Mark",
            "gospel of mark":
                "Mark",

            // Luke
            "lk":
                "Luke",
            "lk.":
                "Luke",
            "gospel of luke":
                "Luke",

            // John
            "jn":
                "John",
            "jn.":
                "John",
            "gospel of john":
                "John",

            // Acts
            "acts of the apostles":
                "Acts",

            // Romans
            "rom":
                "Romans",
            "rom.":
                "Romans",

            // Corinthians
            "1 cor":
                "1 Corinthians",
            "1 cor.":
                "1 Corinthians",
            "i corinthians":
                "1 Corinthians",

            "2 cor":
                "2 Corinthians",
            "2 cor.":
                "2 Corinthians",
            "ii corinthians":
                "2 Corinthians",

            // Galatians
            "gal":
                "Galatians",
            "gal.":
                "Galatians",

            // Ephesians
            "eph":
                "Ephesians",
            "eph.":
                "Ephesians",

            // Philippians
            "phil":
                "Philippians",
            "phil.":
                "Philippians",

            // Colossians
            "col":
                "Colossians",
            "col.":
                "Colossians",

            // Thessalonians
            "1 thess":
                "1 Thessalonians",
            "1 thess.":
                "1 Thessalonians",
            "i thessalonians":
                "1 Thessalonians",

            "2 thess":
                "2 Thessalonians",
            "2 thess.":
                "2 Thessalonians",
            "ii thessalonians":
                "2 Thessalonians",

            // Timothy
            "1 tim":
                "1 Timothy",
            "1 tim.":
                "1 Timothy",
            "i timothy":
                "1 Timothy",

            "2 tim":
                "2 Timothy",
            "2 tim.":
                "2 Timothy",
            "ii timothy":
                "2 Timothy",

            // Hebrews
            "heb":
                "Hebrews",
            "heb.":
                "Hebrews",

            // James
            "jas":
                "James",
            "jas.":
                "James",

            // Peter
            "1 pet":
                "1 Peter",
            "1 pet.":
                "1 Peter",
            "i peter":
                "1 Peter",

            "2 pet":
                "2 Peter",
            "2 pet.":
                "2 Peter",
            "ii peter":
                "2 Peter",

            // John letters
            "1 jn":
                "1 John",
            "1 jn.":
                "1 John",
            "i john":
                "1 John",

            "2 jn":
                "2 John",
            "2 jn.":
                "2 John",
            "ii john":
                "2 John",

            "3 jn":
                "3 John",
            "3 jn.":
                "3 John",
            "iii john":
                "3 John",

            // Revelation
            "rev":
                "Revelation",
            "rev.":
                "Revelation",
            "revelations":
                "Revelation",
            "revelation of john":
                "Revelation",
            "apocalypse":
                "Revelation"
        ]


        if let alias =
            aliases[lowercase] {

            return alias
        }


        return nil
    }


    // MARK: - Reference Parser

    private func parseReference(
        _ query: String
    ) -> (
        book: String,
        chapter: Int,
        verse: Int?
    )? {

        guard let parsed =
            parsePassageRange(
                query
            )
        else {

            return nil
        }


        return (
            book:
                parsed.book,

            chapter:
                parsed.chapter,

            verse:
                parsed.startVerse
        )
    }


    func parsePassageRange(
        _ reference: String
    ) -> BiblePassageReference? {

        var cleaned =

            reference

                .replacingOccurrences(
                    of: "–",
                    with: "-"
                )

                .replacingOccurrences(
                    of: "—",
                    with: "-"
                )

                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        guard !cleaned.isEmpty else {
            return nil
        }


        // Remove a simple leading
        // instruction if the AI ever
        // returns something such as:
        //
        // "Read John 3:16"

        if cleaned.lowercased()
            .hasPrefix(
                "read "
            ) {

            cleaned =
                String(
                    cleaned.dropFirst(
                        5
                    )
                )
        }


        // Normalize spaces around
        // colons and hyphens.
        //
        // John 3 : 16
        // becomes
        // John 3:16

        cleaned =
            cleaned.replacingOccurrences(
                of:
                    #"\s*:\s*"#,
                with:
                    ":",
                options:
                    .regularExpression
            )


        cleaned =
            cleaned.replacingOccurrences(
                of:
                    #"\s*-\s*"#,
                with:
                    "-",
                options:
                    .regularExpression
            )


        // Remove trailing translation labels
        // such as:
        //
        // John 3:16 (NIV)

        cleaned =
            cleaned.replacingOccurrences(
                of:
                    #"\s*\([^)]*\)\s*$"#,
                with:
                    "",
                options:
                    .regularExpression
            )


        let components =
            cleaned.split(
                whereSeparator: {
                    $0.isWhitespace
                }
            )


        guard components.count >= 2 else {
            return nil
        }


        let finalPart =
            String(
                components.last!
            )


        let rawBook =
            components
                .dropLast()
                .joined(
                    separator: " "
                )


        guard let book =
            canonicalBookName(
                rawBook
            )
        else {

            return nil
        }


        // MARK: Chapter Only

        // Examples:
        //
        // John 3
        // Psalm 23
        // Romans 8

        if !finalPart.contains(
            ":"
        ) {

            let chapterText =
                finalPart
                    .trimmingCharacters(
                        in:
                            CharacterSet(
                                charactersIn:
                                    ".,;()[]{}"
                            )
                    )


            guard let chapter =
                Int(
                    chapterText
                )
            else {

                return nil
            }


            return BiblePassageReference(
                book:
                    book,
                chapter:
                    chapter,
                startVerse:
                    nil,
                endVerse:
                    nil
            )
        }


        // MARK: Chapter + Verse

        // Examples:
        //
        // John 3:16
        // John 3:16-18
        // 1 Peter 3:21

        let chapterVerseParts =
            finalPart.split(
                separator:
                    ":",
                maxSplits:
                    1
            )


        guard
            chapterVerseParts.count
                ==
                2,

            let chapter =
                Int(
                    chapterVerseParts[0]
                )

        else {

            return nil
        }


        let versePart =

            String(
                chapterVerseParts[1]
            )

            .trimmingCharacters(
                in:
                    CharacterSet(
                        charactersIn:
                            ".,;()[]{}"
                    )
            )


        guard !versePart.isEmpty else {
            return nil
        }


        // MARK: Verse Range

        // John 3:16-18

        if versePart.contains(
            "-"
        ) {

            let range =
                versePart.split(
                    separator:
                        "-",
                    maxSplits:
                        1
                )


            guard
                range.count == 2,

                let start =
                    Int(
                        range[0]
                    ),

                let end =
                    Int(
                        range[1]
                    ),

                start > 0,

                end >= start

            else {

                return nil
            }


            return BiblePassageReference(
                book:
                    book,
                chapter:
                    chapter,
                startVerse:
                    start,
                endVerse:
                    end
            )
        }


        // MARK: Single Verse

        // John 3:16

        guard
            let verse =
                Int(
                    versePart
                ),

            verse > 0

        else {

            return nil
        }


        return BiblePassageReference(
            book:
                book,
            chapter:
                chapter,
            startVerse:
                verse,
            endVerse:
                verse
        )
    }
}
