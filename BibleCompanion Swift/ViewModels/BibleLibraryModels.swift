import Foundation

/// Exact, single-chapter location. An empty verse list means the whole chapter.
/// Lists are canonicalized so 1,2,3 and 1-3 use the same saved record.
nonisolated struct BibleLibraryLocation: Codable, Hashable, Identifiable, Sendable {
  let book: String
  let chapter: Int
  let verses: [Int]

  init(book: String, chapter: Int, verses: [Int] = []) {
    self.book =
      BibleLibraryReference.canonicalBook(book)
      ?? book.trimmingCharacters(in: .whitespacesAndNewlines)
    self.chapter = chapter
    self.verses = Array(Set(verses)).sorted()
  }

  var id: String {
    "\(book.lowercased())::\(chapter)::\(verses.map(String.init).joined(separator: ","))"
  }
  var chapterID: String { "\(book.lowercased())::\(chapter)" }
  var isValid: Bool {
    BibleLibraryReference.canonicalBook(book) != nil && chapter > 0 && chapter <= 150
      && verses.allSatisfy { $0 > 0 && $0 <= 200 }
  }
  var reference: String {
    let prefix = "\(book) \(chapter)"
    return verses.isEmpty ? prefix : prefix + ":" + BibleLibraryReference.compactVerses(verses)
  }
  func overlaps(_ other: Self) -> Bool {
    guard chapterID == other.chapterID else { return false }
    return verses.isEmpty || other.verses.isEmpty || !Set(verses).isDisjoint(with: other.verses)
  }

  enum CodingKeys: String, CodingKey { case book, chapter, verses }
  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      book: try values.decode(String.self, forKey: .book),
      chapter: try values.decode(Int.self, forKey: .chapter),
      verses: try values.decodeIfPresent([Int].self, forKey: .verses) ?? [])
    guard isValid else {
      throw DecodingError.dataCorrupted(
        .init(codingPath: decoder.codingPath, debugDescription: "Invalid Bible location"))
    }
  }
}

enum BibleHighlightColor: String, Codable, CaseIterable, Identifiable, Sendable {
  case gold, green, blue, rose
  var id: String { rawValue }
  var title: String { rawValue.capitalized }
}

struct BibleLibraryHighlight: Codable, Identifiable, Sendable {
  let location: BibleLibraryLocation
  var color: BibleHighlightColor
  var updatedAt: Date
  var id: String { location.id }
}

struct BibleLibraryBookmark: Codable, Identifiable, Sendable {
  let location: BibleLibraryLocation
  var createdAt: Date
  var id: String { location.id }
}

struct BibleLibraryNote: Codable, Identifiable, Sendable {
  let id: UUID
  let location: BibleLibraryLocation
  var text: String
  let createdAt: Date
  var updatedAt: Date
  /// Explicit opt-in. Notes remain local unless this is enabled for the note.
  var includeInCompanionMemory: Bool
}

struct BibleLibraryVisit: Codable, Identifiable, Sendable {
  let location: BibleLibraryLocation
  var visitedAt: Date
  var id: String { location.id }
}

struct BibleLibrarySearch: Codable, Identifiable, Sendable {
  let query: String
  var searchedAt: Date
  var id: String { BibleLibraryReference.normalizedText(query) }
}

struct BibleLibraryState: Codable, Sendable {
  var schemaVersion = 1
  var highlights: [BibleLibraryHighlight] = []
  var bookmarks: [BibleLibraryBookmark] = []
  var notes: [BibleLibraryNote] = []
  var visits: [BibleLibraryVisit] = []
  var searches: [BibleLibrarySearch] = []
  var dismissedSuggestionIDs: [String] = []
}

/// Shared parser for search, annotations, saved items and journey links.
/// It never silently converts a non-contiguous selection into a continuous range.
nonisolated enum BibleLibraryReference {
  static let books = [
    "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy", "Joshua", "Judges", "Ruth",
    "1 Samuel", "2 Samuel", "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra",
    "Nehemiah", "Esther", "Job", "Psalms", "Proverbs", "Ecclesiastes", "Song of Solomon",
    "Isaiah", "Jeremiah", "Lamentations", "Ezekiel", "Daniel", "Hosea", "Joel", "Amos", "Obadiah",
    "Jonah", "Micah", "Nahum", "Habakkuk", "Zephaniah", "Haggai", "Zechariah", "Malachi",
    "Matthew", "Mark", "Luke", "John", "Acts", "Romans", "1 Corinthians", "2 Corinthians",
    "Galatians", "Ephesians", "Philippians", "Colossians", "1 Thessalonians", "2 Thessalonians",
    "1 Timothy", "2 Timothy", "Titus", "Philemon", "Hebrews", "James", "1 Peter", "2 Peter",
    "1 John", "2 John", "3 John", "Jude", "Revelation",
  ]
  static let aliases: [String: String] = [
    "gen": "Genesis", "ex": "Exodus", "exod": "Exodus", "lev": "Leviticus", "num": "Numbers",
    "nums": "Numbers", "deut": "Deuteronomy", "josh": "Joshua", "judg": "Judges",
    "ps": "Psalms", "psalm": "Psalms", "prov": "Proverbs", "eccl": "Ecclesiastes",
    "ecc": "Ecclesiastes",
    "song of songs": "Song of Solomon", "canticles": "Song of Solomon", "isa": "Isaiah",
    "jer": "Jeremiah", "lam": "Lamentations", "ezek": "Ezekiel", "dan": "Daniel",
    "hab": "Habakkuk", "matt": "Matthew", "mt": "Matthew", "mk": "Mark", "lk": "Luke",
    "jn": "John", "rom": "Romans", "1 cor": "1 Corinthians", "2 cor": "2 Corinthians",
    "gal": "Galatians", "eph": "Ephesians", "phil": "Philippians", "col": "Colossians",
    "1 thess": "1 Thessalonians", "2 thess": "2 Thessalonians", "1 tim": "1 Timothy",
    "2 tim": "2 Timothy", "heb": "Hebrews", "jas": "James", "1 pet": "1 Peter", "2 pet": "2 Peter",
    "1 jn": "1 John", "2 jn": "2 John", "3 jn": "3 John", "rev": "Revelation",
    "revelations": "Revelation",
  ]

  private static let canonicalNames = Dictionary(uniqueKeysWithValues: books.map { ($0.lowercased(), $0) })
  private static let normalizationLocale = Locale(identifier: "en_US_POSIX")

  static func normalizedText(_ text: String) -> String {
    text.folding(
      options: [.caseInsensitive, .diacriticInsensitive], locale: normalizationLocale
    )
    .split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
  }
  static func canonicalBook(_ raw: String) -> String? {
    var key = normalizedText(raw).replacingOccurrences(of: ".", with: "")
    if key.hasPrefix("gospel of ") { key = String(key.dropFirst(10)) }
    if key.hasPrefix("iii ") {
      key = "3 " + key.dropFirst(4)
    } else if key.hasPrefix("ii ") {
      key = "2 " + key.dropFirst(3)
    } else if key.hasPrefix("i ") {
      key = "1 " + key.dropFirst(2)
    }
    if let exact = canonicalNames[key] { return exact }
    return aliases[key]
  }
  static func parse(_ raw: String) -> BibleLibraryLocation? {
    var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if text.lowercased().hasPrefix("read ") { text = String(text.dropFirst(5)) }
    text = text.replacingOccurrences(of: "\u{2013}", with: "-").replacingOccurrences(
      of: "\u{2014}", with: "-")
    text = text.replacingOccurrences(
      of: #"\s*\([^)]*\)\s*$"#, with: "", options: .regularExpression)
    text = text.trimmingCharacters(in: CharacterSet(charactersIn: " .;"))
    guard
      let regex = try? NSRegularExpression(pattern: #"^(.+?)\s*(\d+)\s*(?::\s*([\d\s,\-]+))?$"#),
      let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
      let bookRange = Range(match.range(at: 1), in: text),
      let chapterRange = Range(match.range(at: 2), in: text),
      let book = canonicalBook(String(text[bookRange])), let chapter = Int(text[chapterRange]),
      chapter > 0, chapter <= 150
    else { return nil }
    var verses: [Int] = []
    if let verseRange = Range(match.range(at: 3), in: text) {
      let parts = text[verseRange].split(separator: ",", omittingEmptySubsequences: false)
      guard !parts.isEmpty, parts.count <= 200 else { return nil }
      for part in parts {
        let bounds = part.split(separator: "-", omittingEmptySubsequences: false)
          .map { $0.trimmingCharacters(in: .whitespaces) }
        guard (1...2).contains(bounds.count), let first = Int(bounds[0]), first > 0, first <= 200
        else { return nil }
        if bounds.count == 2 {
          guard let last = Int(bounds[1]), last >= first, last <= 200 else { return nil }
          verses.append(contentsOf: first...last)
        } else {
          verses.append(first)
        }
      }
    }
    return BibleLibraryLocation(book: book, chapter: chapter, verses: verses)
  }
  static func compactVerses(_ numbers: [Int]) -> String {
    let values = Array(Set(numbers)).sorted()
    guard var first = values.first else { return "" }
    var last = first
    var pieces: [String] = []
    func segment(_ a: Int, _ b: Int) -> String { a == b ? "\(a)" : "\(a)-\(b)" }
    for value in values.dropFirst() {
      if value == last + 1 {
        last = value
      } else {
        pieces.append(segment(first, last))
        first = value
        last = value
      }
    }
    pieces.append(segment(first, last))
    return pieces.joined(separator: ",")
  }
  /// Keep the Study Mode V1 reference spelling so existing reflection and
  /// conversation keys remain reachable, including non-contiguous selections.
  static func legacyStudyReference(_ location: BibleLibraryLocation) -> String {
    let prefix = "\(location.book) \(location.chapter)"
    guard let first = location.verses.first, let last = location.verses.last else { return prefix }
    if location.verses.count == 1 { return prefix + ":\(first)" }
    if location.verses == Array(first...last) { return prefix + ":\(first)-\(last)" }
    return prefix + ":" + location.verses.map(String.init).joined(separator: ",")
  }

  static func suggestedBooks(for query: String) -> [String] {
    let key = normalizedText(query)
    guard !key.isEmpty else { return [] }
    if let book = canonicalBook(query) { return [book] }
    return Array(books.filter { $0.lowercased().hasPrefix(key) }.prefix(8))
  }
}
