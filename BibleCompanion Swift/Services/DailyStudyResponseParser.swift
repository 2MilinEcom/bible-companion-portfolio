import Foundation

// =========================================================
// MARK: - Daily Study Response Parser
// =========================================================

enum DailyStudyResponseParser {

  private static let labels = [
    "BIG_IDEA",
    "NOTICE_1",
    "NOTICE_2",
    "NOTICE_3",
    "REFLECT",
    "PRACTICE",
    "PRAYER",
  ]

  static func parse(
    _ raw: String,
    generatedAt: Date = Date()
  ) -> DailyStudyContent? {

    let cleanedRaw = raw
      .replacingOccurrences(of: "**", with: "")
      .replacingOccurrences(of: "###", with: "")
      .replacingOccurrences(of: "\r\n", with: "\n")

    var buckets: [String: [String]] = [:]
    var currentLabel: String?

    for rawLine in cleanedRaw.split(separator: "\n", omittingEmptySubsequences: false) {
      let line = String(rawLine)
      let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
      let upper = trimmed.uppercased()

      var matched = false

      for label in labels {
        let marker = label + ":"
        if upper.hasPrefix(marker) {
          currentLabel = label
          let start = trimmed.index(trimmed.startIndex, offsetBy: marker.count)
          let remainder = String(trimmed[start...])
          buckets[label, default: []].append(remainder)
          matched = true
          break
        }
      }

      if !matched, let currentLabel {
        buckets[currentLabel, default: []].append(line)
      }
    }

    let bigIdea = value("BIG_IDEA", in: buckets)
    guard !bigIdea.isEmpty else { return nil }

    let observations = [
      value("NOTICE_1", in: buckets),
      value("NOTICE_2", in: buckets),
      value("NOTICE_3", in: buckets),
    ]
    .filter { !$0.isEmpty }

    let fallback = DailyStudyContent.fallback(generatedAt: generatedAt)

    return DailyStudyContent(
      bigIdea: bigIdea,
      observations: observations.isEmpty ? fallback.observations : observations,
      reflectionQuestion: nonEmpty(value("REFLECT", in: buckets), fallback.reflectionQuestion),
      practice: nonEmpty(value("PRACTICE", in: buckets), fallback.practice),
      prayerPrompt: nonEmpty(value("PRAYER", in: buckets), fallback.prayerPrompt),
      generatedAt: generatedAt,
      source: .ai
    )
  }

  /// If the model ever ignores the labels entirely, keep its short answer as
  /// the main idea and provide neutral local prompts for the remaining cards.
  static func bestEffort(
    _ raw: String,
    generatedAt: Date = Date()
  ) -> DailyStudyContent {

    if let parsed = parse(raw, generatedAt: generatedAt) {
      return parsed
    }

    let fallback = DailyStudyContent.fallback(generatedAt: generatedAt)
    let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    let bigIdea = clean.isEmpty ? fallback.bigIdea : String(clean.prefix(900))

    return DailyStudyContent(
      bigIdea: bigIdea,
      observations: fallback.observations,
      reflectionQuestion: fallback.reflectionQuestion,
      practice: fallback.practice,
      prayerPrompt: fallback.prayerPrompt,
      generatedAt: generatedAt,
      source: .ai
    )
  }

  private static func value(
    _ label: String,
    in buckets: [String: [String]]
  ) -> String {

    let joined = (buckets[label] ?? [])
      .joined(separator: "\n")
      .trimmingCharacters(in: .whitespacesAndNewlines)

    return joined
      .replacingOccurrences(of: #"^[-•]\s*"#, with: "", options: .regularExpression)
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private static func nonEmpty(_ value: String, _ fallback: String) -> String {
    value.isEmpty ? fallback : value
  }
}
