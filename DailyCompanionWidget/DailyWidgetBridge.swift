import Foundation
import WidgetKit

// =========================================================
// MARK: - Daily Widget Bridge
// =========================================================

/// Main-app-only bridge that publishes a rolling Daily Study schedule to the
/// Widget Extension through the shared App Group.
///
/// WidgetKit never calls OpenAI and never needs access to the user's profile.
/// The app writes only the small display snapshot the widget needs.
@MainActor
final class DailyWidgetBridge {

  static let shared = DailyWidgetBridge()

  private var cachedBible: [BibleVerse]?

  private init() {}

  // =====================================================
  // MARK: - Publish Rolling Schedule
  // =====================================================

  func publishSchedule(
    todayRecord: DailyStudyRecord,
    focusText: String,
    goalText: String,
    recentReferences: [String],
    previousPlans: [DailyStudyPlan],
    days: Int = 8
  ) {

    let dayCount = max(1, min(days, 14))
    let calendar = Calendar.autoupdatingCurrent
    let today = DailyStudyDay.startOfDay(for: Date())

    var planningHistory = previousPlans
    var snapshots: [DailyWidgetSnapshot] = []

    for offset in 0..<dayCount {
      guard let date = calendar.date(byAdding: .day, value: offset, to: today) else {
        continue
      }

      let dateKey = DailyStudyDay.key(for: date)
      let plan: DailyStudyPlan

      if dateKey == todayRecord.plan.dateKey {
        plan = todayRecord.plan
      } else if let existing = DailyStudyStore.shared.record(dateKey: dateKey) {
        plan = existing.plan
      } else {
        plan = DailyStudyPlanner.makePlan(
          for: date,
          focusText: focusText,
          goalText: goalText,
          recentReferences: recentReferences,
          previousPlans: planningHistory
        )
      }

      let completed = DailyStudyStore.shared.record(dateKey: dateKey)?.completedAt != nil
      let snapshot = DailyWidgetSnapshot(
        dateKey: dateKey,
        date: DailyStudyDay.startOfDay(for: date),
        title: plan.title,
        reference: plan.reference,
        verseText: verseText(for: plan.reference),
        isCompleted: completed
      )

      snapshots.append(snapshot)
      planningHistory.insert(plan, at: 0)
    }

    let payload = DailyWidgetPayload(
      generatedAt: Date(),
      snapshots: snapshots
    )

    guard DailyWidgetShared.savePayload(payload) else { return }

    WidgetCenter.shared.reloadTimelines(ofKind: DailyWidgetShared.widgetKind)
  }

  // =====================================================
  // MARK: - Completion Sync
  // =====================================================

  func updateCompletion(
    dateKey: String,
    isCompleted: Bool
  ) {
    guard var payload = DailyWidgetShared.loadPayload() else { return }
    guard let index = payload.snapshots.firstIndex(where: { $0.dateKey == dateKey }) else {
      return
    }

    payload.snapshots[index].isCompleted = isCompleted
    payload.generatedAt = Date()

    guard DailyWidgetShared.savePayload(payload) else { return }
    WidgetCenter.shared.reloadTimelines(ofKind: DailyWidgetShared.widgetKind)
  }

  // =====================================================
  // MARK: - Scripture Excerpt
  // =====================================================

  private func verseText(for reference: String) -> String {
    let bible: [BibleVerse]

    if let cachedBible {
      bible = cachedBible
    } else {
      do {
        let loaded = try BibleService.shared.loadBible()
        cachedBible = loaded
        bible = loaded
      } catch {
        return "Open Bible Companion to read today's passage."
      }
    }

    let matching = BibleService.shared.search(query: reference, verses: bible)

    let text = matching
      .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: " ")
      .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
      .trimmingCharacters(in: .whitespacesAndNewlines)

    guard !text.isEmpty else {
      return "Open Bible Companion to read today's passage."
    }

    // Keep the shared payload intentionally small. Widget views apply their
    // own line limits on top of this.
    if text.count > 420 {
      return String(text.prefix(419)).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }

    return text
  }
}
