import Combine
import Foundation

// =========================================================
// MARK: - Daily Study Store
// =========================================================

@MainActor
final class DailyStudyStore: ObservableObject {

  static let shared = DailyStudyStore()
  static let storageKey = "bibleCompanionDailyStudy.v1"

  @Published private(set) var state = DailyStudyState()
  @Published private(set) var storageError: String?

  private let defaults: UserDefaults
  private var canWrite = true

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults

    guard let data = defaults.data(forKey: Self.storageKey) else { return }

    do {
      let decoded = try JSONDecoder().decode(DailyStudyState.self, from: data)
      guard decoded.schemaVersion == 1 else {
        canWrite = false
        storageError = "Daily Study data was created by a newer version of the app. Nothing was changed."
        return
      }
      state = decoded
    } catch {
      canWrite = false
      storageError = "Your Daily Study history could not be loaded. The original data is preserved."
    }
  }

  var records: [DailyStudyRecord] {
    state.records.sorted { $0.plan.date > $1.plan.date }
  }

  var todayRecord: DailyStudyRecord? {
    record(dateKey: DailyStudyDay.key(for: Date()))
  }

  var isTodayComplete: Bool {
    todayRecord?.completedAt != nil
  }

  func record(dateKey: String) -> DailyStudyRecord? {
    state.records.first { $0.plan.dateKey == dateKey }
  }

  func recentRecords(limit: Int = 14) -> [DailyStudyRecord] {
    Array(records.prefix(max(0, limit)))
  }

  func recentStartedRecords(
    excluding dateKey: String,
    limit: Int = 5
  ) -> [DailyStudyRecord] {
    Array(
      records
        .filter { $0.plan.dateKey != dateKey && $0.hasStarted }
        .prefix(max(0, limit))
    )
  }

  /// A plan is immutable once it has been chosen for a calendar day. Profile
  /// or path changes later that same day affect tomorrow, not a study the user
  /// may already have started.
  @discardableResult
  func ensurePlan(
    _ plan: DailyStudyPlan,
    now: Date = Date()
  ) -> DailyStudyRecord {

    if let existing = record(dateKey: plan.dateKey) {
      return existing
    }

    let newRecord = DailyStudyRecord(
      plan: plan,
      content: nil,
      reflection: "",
      completedAt: nil,
      createdAt: now,
      updatedAt: now
    )

    _ = update { state in
      state.records.append(newRecord)
      state.records.sort { $0.plan.date > $1.plan.date }
      if state.records.count > 90 {
        state.records = Array(state.records.prefix(90))
      }
    }

    return record(dateKey: plan.dateKey) ?? newRecord
  }

  @discardableResult
  func saveContent(
    _ content: DailyStudyContent,
    dateKey: String,
    now: Date = Date()
  ) -> Bool {

    update { state in
      guard let index = state.records.firstIndex(where: { $0.plan.dateKey == dateKey }) else {
        return
      }
      state.records[index].content = content
      state.records[index].updatedAt = now
    }
  }

  @discardableResult
  func saveReflection(
    _ reflection: String,
    dateKey: String,
    now: Date = Date()
  ) -> Bool {

    update { state in
      guard let index = state.records.firstIndex(where: { $0.plan.dateKey == dateKey }) else {
        return
      }
      state.records[index].reflection = reflection
      state.records[index].updatedAt = now
    }
  }

  /// Returns true only when this call newly completed the day.
  @discardableResult
  func markCompleted(
    dateKey: String,
    now: Date = Date()
  ) -> Bool {

    guard
      let index = state.records.firstIndex(where: { $0.plan.dateKey == dateKey }),
      state.records[index].completedAt == nil
    else {
      return false
    }

    var didComplete = false

    let didSave = update { state in
      guard let index = state.records.firstIndex(where: { $0.plan.dateKey == dateKey }) else {
        return
      }
      guard state.records[index].completedAt == nil else { return }
      state.records[index].completedAt = now
      state.records[index].updatedAt = now
      didComplete = true
    }

    let completed = didSave && didComplete

    if completed {
      DailyWidgetBridge.shared.updateCompletion(
        dateKey: dateKey,
        isCompleted: true
      )
    }

    return completed
  }

  // =====================================================
  // MARK: - Persistence
  // =====================================================

  @discardableResult
  private func update(_ change: (inout DailyStudyState) -> Void) -> Bool {
    guard canWrite else { return false }

    var next = state
    change(&next)

    do {
      let data = try JSONEncoder().encode(next)
      defaults.set(data, forKey: Self.storageKey)
      state = next
      storageError = nil
      return true
    } catch {
      storageError = "Your Daily Study changes could not be saved. Please try again."
      return false
    }
  }
}
