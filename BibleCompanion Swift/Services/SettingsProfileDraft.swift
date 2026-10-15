import Foundation

/// Only the editable onboarding answers. Journey/struggle fields remain in the
/// original SpiritualProfile and are never recreated from this smaller draft.
struct SettingsProfileDraft: Equatable {
  var name = ""
  var spiritualPosition = ""
  var bibleFamiliarity = ""
  var primaryGoal = ""
  var currentSeason = ""
  var challengePreference = ""

  init() {}

  init(profile: SpiritualProfile) {
    name = profile.name
    spiritualPosition = profile.spiritualPosition
    bibleFamiliarity = profile.bibleFamiliarity
    primaryGoal = profile.primaryGoal
    currentSeason = profile.currentSeason
    challengePreference = profile.challengePreference
  }

  /// Merge only edited answers into the current profile, not an old snapshot.
  /// This preserves newer path context and any other profile properties.
  func applyingChanges(since original: Self, to profile: SpiritualProfile) -> SpiritualProfile {
    var result = profile
    if name != original.name {
      result.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    if spiritualPosition != original.spiritualPosition {
      result.spiritualPosition = spiritualPosition
    }
    if bibleFamiliarity != original.bibleFamiliarity { result.bibleFamiliarity = bibleFamiliarity }
    if primaryGoal != original.primaryGoal { result.primaryGoal = primaryGoal }
    if currentSeason != original.currentSeason { result.currentSeason = currentSeason }
    if challengePreference != original.challengePreference {
      result.challengePreference = challengePreference
    }
    return result
  }

  static func options(_ options: [String], including current: String) -> [String] {
    var seen = Set<String>()
    return (options + [current]).filter { !$0.isEmpty && seen.insert($0).inserted }
  }
}
