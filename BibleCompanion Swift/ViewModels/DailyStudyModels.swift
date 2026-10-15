import Foundation

// =========================================================
// MARK: - Daily Study Day
// =========================================================

enum DailyStudyDay {

  static func key(for date: Date) -> String {
    let calendar = Calendar.autoupdatingCurrent
    let components = calendar.dateComponents([.year, .month, .day], from: date)
    let year = components.year ?? 0
    let month = components.month ?? 0
    let day = components.day ?? 0
    return String(format: "%04d-%02d-%02d", year, month, day)
  }

  static func startOfDay(for date: Date) -> Date {
    Calendar.autoupdatingCurrent.startOfDay(for: date)
  }
}

// =========================================================
// MARK: - Daily Study Plan
// =========================================================

/// The local, deterministic portion of a Daily Study.
///
/// The passage is selected locally and saved before any AI generation. This
/// keeps today's study stable throughout the day and means opening Home does
/// not spend an AI request.
struct DailyStudyPlan: Codable, Hashable, Identifiable, Sendable {

  let dateKey: String
  let date: Date
  let title: String
  let reference: String
  let focusLabel: String
  let reasonTitle: String
  let reason: String
  let category: String

  var id: String { dateKey }

  var location: BibleLibraryLocation? {
    BibleLibraryReference.parse(reference)
  }
}

// =========================================================
// MARK: - Generated Daily Guide
// =========================================================

enum DailyStudyContentSource: String, Codable, Equatable, Sendable {
  case ai
  case fallback
}

struct DailyStudyContent: Codable, Equatable, Sendable {

  let bigIdea: String
  let observations: [String]
  let reflectionQuestion: String
  let practice: String
  let prayerPrompt: String
  let generatedAt: Date
  let source: DailyStudyContentSource

  static func fallback(
    generatedAt: Date = Date()
  ) -> DailyStudyContent {

    DailyStudyContent(
      bigIdea:
        "Read the passage slowly and notice what it reveals about God, people, or faithful response.",
      observations: [
        "Notice repeated words, commands, promises, contrasts, or images in the passage.",
        "Pay attention to what the passage actually says before deciding what it means for you.",
      ],
      reflectionQuestion:
        "What is the clearest thing this passage is asking you to notice today?",
      practice:
        "Choose one sentence or idea from the passage to carry with you and return to later today.",
      prayerPrompt:
        "Respond to God honestly about what stood out, and ask for help to live faithfully in light of it.",
      generatedAt: generatedAt,
      source: .fallback
    )
  }
}

// =========================================================
// MARK: - Persisted Daily Record
// =========================================================

struct DailyStudyRecord: Codable, Identifiable, Sendable {

  let plan: DailyStudyPlan
  var content: DailyStudyContent?
  var reflection: String
  var completedAt: Date?
  let createdAt: Date
  var updatedAt: Date

  var id: String { plan.dateKey }

  var hasStarted: Bool {
    content != nil
      || !reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      || completedAt != nil
  }
}

struct DailyStudyState: Codable, Sendable {
  var schemaVersion = 1
  var records: [DailyStudyRecord] = []
}
