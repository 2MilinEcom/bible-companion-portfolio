import Foundation

// =========================================================
// MARK: - Daily Companion Widget Shared Contract
// =========================================================

/// Shared, dependency-free models used by both the main Bible Companion app
/// and the DailyCompanionWidget extension.
///
/// Add this file to BOTH targets.
enum DailyWidgetShared {

  static let storageKey = "bibleCompanionDailyWidget.v1"
  static let widgetKind = "DailyCompanionWidget"

  static let deepLinkScheme = "biblecompanion"
  static let deepLinkHost = "daily"
  static let deepLinkPath = "/today"

  // This is the App Group you configured in Xcode for BOTH targets.
  // Using the explicit value removes any ambiguity from Xcode's extension
  // target naming (for example DailyCompanionWidgetExtension vs product name).
  static let appGroupID = "group.com.sampleguzman.BibleCompanion"

  static var todayDeepLinkURL: URL? {
    URL(string: "\(deepLinkScheme)://\(deepLinkHost)\(deepLinkPath)")
  }

  static func isTodayDeepLink(_ url: URL) -> Bool {
    url.scheme?.lowercased() == deepLinkScheme
      && url.host?.lowercased() == deepLinkHost
      && (url.path.isEmpty || url.path == deepLinkPath)
  }

  static func dateKey(for date: Date) -> String {
    let calendar = Calendar.autoupdatingCurrent
    let components = calendar.dateComponents([.year, .month, .day], from: date)
    return String(
      format: "%04d-%02d-%02d",
      components.year ?? 0,
      components.month ?? 0,
      components.day ?? 0
    )
  }

  static func sharedDefaults() -> UserDefaults? {
    UserDefaults(suiteName: appGroupID)
  }

  static func loadPayload() -> DailyWidgetPayload? {
    guard
      let defaults = sharedDefaults(),
      let data = defaults.data(forKey: storageKey)
    else {
      return nil
    }

    return try? JSONDecoder().decode(DailyWidgetPayload.self, from: data)
  }

  @discardableResult
  static func savePayload(_ payload: DailyWidgetPayload) -> Bool {
    guard
      let defaults = sharedDefaults(),
      let data = try? JSONEncoder().encode(payload)
    else {
      return false
    }

    defaults.set(data, forKey: storageKey)
    return true
  }
}

// =========================================================
// MARK: - Shared Widget Snapshot
// =========================================================

struct DailyWidgetSnapshot: Codable, Hashable, Identifiable, Sendable {
  let dateKey: String
  let date: Date
  let title: String
  let reference: String
  let verseText: String
  var isCompleted: Bool

  var id: String { dateKey }
}

struct DailyWidgetPayload: Codable, Sendable {
  var schemaVersion = 1
  var generatedAt: Date
  var snapshots: [DailyWidgetSnapshot]

  func snapshot(for date: Date = Date()) -> DailyWidgetSnapshot? {
    let key = DailyWidgetShared.dateKey(for: date)
    return snapshots.first { $0.dateKey == key }
  }
}
