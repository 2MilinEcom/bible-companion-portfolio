import Foundation

struct CompanionFollowUpSuggestion: Identifiable, Equatable, Sendable {
  let title: String
  let prompt: String
  let icon: String
  var id: String { title + "::" + prompt }
}

/// Contextual, local suggestions. No additional AI request, no inferred user
/// diagnosis or spiritual score, and nothing is sent until the user taps.
enum CompanionFollowUpSuggestions {
  static func make(answer: String, passage: String) -> [CompanionFollowUpSuggestion] {
    let clean = answer.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !clean.isEmpty, !clean.hasPrefix("I couldn't") else { return [] }
    let lower = clean.lowercased()
    var result: [CompanionFollowUpSuggestion] = []
    let topics: [(String, String)] = [
      ("poor in spirit", "Poor in spirit"), ("abiding", "Abiding"), ("abide", "Abiding"),
      ("forgiveness", "Forgiveness"), ("resurrection", "Resurrection"), ("baptism", "Baptism"),
      ("repentance", "Repentance"), ("grace", "Grace"), ("salvation", "Salvation"),
      ("faith", "Faith"), ("prayer", "Prayer"), ("fruit", "Fruit"), ("kingdom", "God's kingdom"),
    ]
    if let topic = topics.first(where: { wholePhrase($0.0, appearsIn: lower) }) {
      result.append(
        .init(
          title: "Explore \(topic.1.lowercased())",
          prompt:
            "In your last answer, what does \(topic.1.lowercased()) mean in the biblical context? Explain the key distinction briefly.",
          icon: "lightbulb"))
    } else if let phrase = emphasizedPhrase(in: clean) {
      result.append(
        .init(
          title: "Explore \(phrase)",
          prompt: "Could you briefly unpack what you meant by '\(phrase)' in your last answer?",
          icon: "lightbulb"))
    }
    if let reference = references(in: clean).first ?? references(in: passage).first {
      result.append(
        .init(
          title: "Context: \(reference)",
          prompt:
            "What is the surrounding context of \(reference), and how does it affect the point we were discussing? Keep it concise.",
          icon: "book.closed"))
    } else {
      result.append(
        .init(
          title: "What did it mean then?",
          prompt:
            "For the biblical teaching in your last answer, what would its original audience have understood? Distinguish the text from historical inference and keep it brief.",
          icon: "book.closed"))
    }
    if lower.contains("interpret") || lower.contains("christians disagree")
      || lower.contains("different views")
    {
      result.append(
        .init(
          title: "Compare interpretations",
          prompt:
            "What are the main Christian interpretations of the point we just discussed? Briefly explain the strongest textual reason for each, without choosing for me.",
          icon: "person.3"))
    } else {
      result.append(
        .init(
          title: "Help me reflect",
          prompt:
            "Ask me one thoughtful reflection question based on the passage or teaching we just discussed. Do not assume what I believe or how I feel.",
          icon: "text.bubble"))
    }
    var seen: Set<String> = []
    return Array(result.filter { seen.insert($0.title).inserted }.prefix(3))
  }

  private static func wholePhrase(_ phrase: String, appearsIn text: String) -> Bool {
    text.range(
      of: #"\b"# + NSRegularExpression.escapedPattern(for: phrase) + #"\b"#,
      options: .regularExpression) != nil
  }
  private static func emphasizedPhrase(in text: String) -> String? {
    guard let regex = try? NSRegularExpression(pattern: #"\*\*([^*\n]{3,32})\*\*"#) else {
      return nil
    }
    let ignored: Set<String> = [
      "why it matters", "context", "key point", "in short", "the main idea", "understand",
      "companion",
    ]
    return regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap {
      match -> String? in
      guard let range = Range(match.range(at: 1), in: text) else { return nil }
      let phrase = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
      guard phrase.split(separator: " ").count <= 4, !ignored.contains(phrase.lowercased()),
        phrase.rangeOfCharacter(from: .decimalDigits) == nil, !phrase.contains(":")
      else { return nil }
      return phrase
    }.first
  }
  static func references(in text: String) -> [String] {
    let names = (BibleLibraryReference.books + Array(BibleLibraryReference.aliases.keys))
      .sorted { $0.count > $1.count }.map(NSRegularExpression.escapedPattern(for:)).joined(
        separator: "|")
    let pattern =
      "(?i)(?<![A-Za-z0-9])(?:" + names
      + #")\.?\s+\d{1,3}(?::\d{1,3}(?:[-\u2013\u2014]\d{1,3})?)?(?!\d)"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
    var seen: Set<String> = []
    return regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap {
      match -> String? in
      guard let range = Range(match.range, in: text),
        let location = BibleLibraryReference.parse(String(text[range])),
        seen.insert(location.reference).inserted
      else { return nil }
      return location.reference
    }
  }
}
