import Combine
import Foundation

/// Additive storage only. This does not modify any legacy chat, growth, journey,
/// reflection, or study-history keys. All mutations run on the main actor.
@MainActor
final class BibleLibraryStore: ObservableObject {
  static let shared = BibleLibraryStore()
  static let storageKey = "bibleCompanionPersonalBible.v1"
  @Published private(set) var state = BibleLibraryState()
  @Published private(set) var storageError: String?
  private let defaults: UserDefaults
  private var canWrite = true

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    guard let data = defaults.data(forKey: Self.storageKey) else { return }
    do {
      let decoded = try JSONDecoder().decode(BibleLibraryState.self, from: data)
      guard decoded.schemaVersion == 1 else {
        canWrite = false
        storageError = "Your saved Bible uses a newer format. No saved data has been changed."
        return
      }
      state = decoded
    } catch {
      // Do not replace unreadable data with an empty library.
      canWrite = false
      storageError = "Your saved Bible could not be loaded. The original data is preserved."
    }
  }

  var highlights: [BibleLibraryHighlight] {
    state.highlights.sorted { $0.updatedAt > $1.updatedAt }
  }
  var bookmarks: [BibleLibraryBookmark] { state.bookmarks.sorted { $0.createdAt > $1.createdAt } }
  var notes: [BibleLibraryNote] { state.notes.sorted { $0.updatedAt > $1.updatedAt } }
  var visits: [BibleLibraryVisit] { state.visits.sorted { $0.visitedAt > $1.visitedAt } }
  var searches: [BibleLibrarySearch] { state.searches.sorted { $0.searchedAt > $1.searchedAt } }

  func highlight(at location: BibleLibraryLocation) -> BibleLibraryHighlight? {
    state.highlights.first { $0.location == location }
  }
  func isBookmarked(_ location: BibleLibraryLocation) -> Bool {
    state.bookmarks.contains { $0.location == location }
  }
  func note(at location: BibleLibraryLocation) -> BibleLibraryNote? {
    state.notes.first { $0.location == location }
  }
  func notes(overlapping location: BibleLibraryLocation) -> [BibleLibraryNote] {
    notes.filter { $0.location.overlaps(location) }
  }
  func hasNote(at location: BibleLibraryLocation) -> Bool {
    state.notes.contains { $0.location.overlaps(location) }
  }

  @discardableResult
  func setHighlight(
    _ color: BibleHighlightColor?, at location: BibleLibraryLocation, now: Date = Date()
  ) -> Bool {
    guard location.isValid, !location.verses.isEmpty else { return false }
    return update { state in
      let ids = Set(
        location.verses.map {
          BibleLibraryLocation(book: location.book, chapter: location.chapter, verses: [$0]).id
        })
      state.highlights.removeAll { ids.contains($0.id) }
      if let color {
        state.highlights.append(
          contentsOf: location.verses.map {
            BibleLibraryHighlight(
              location: .init(book: location.book, chapter: location.chapter, verses: [$0]),
              color: color, updatedAt: now)
          })
      }
    }
  }
  @discardableResult
  func toggleBookmark(_ location: BibleLibraryLocation, now: Date = Date()) -> Bool {
    guard location.isValid else { return false }
    return update { state in
      if state.bookmarks.contains(where: { $0.location == location }) {
        state.bookmarks.removeAll { $0.location == location }
      } else {
        state.bookmarks.append(.init(location: location, createdAt: now))
      }
    }
  }
  @discardableResult
  func saveNote(
    location: BibleLibraryLocation, text: String, includeInCompanionMemory: Bool, now: Date = Date()
  ) -> Bool {
    guard location.isValid, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return false
    }
    return update { state in
      if let index = state.notes.firstIndex(where: { $0.location == location }) {
        state.notes[index].text = text
        state.notes[index].updatedAt = now
        state.notes[index].includeInCompanionMemory = includeInCompanionMemory
      } else {
        state.notes.append(
          .init(
            id: UUID(), location: location, text: text, createdAt: now,
            updatedAt: now, includeInCompanionMemory: includeInCompanionMemory))
      }
    }
  }
  @discardableResult
  func deleteNote(id: UUID) -> Bool { update { $0.notes.removeAll { $0.id == id } } }
  @discardableResult
  func removeBookmark(_ location: BibleLibraryLocation) -> Bool {
    update { $0.bookmarks.removeAll { $0.location == location } }
  }

  func recordVisit(_ location: BibleLibraryLocation, now: Date = Date()) {
    guard location.isValid else { return }
    _ = update {
      $0.visits.removeAll { $0.location == location }
      $0.visits.insert(.init(location: location, visitedAt: now), at: 0)
      $0.visits = Array($0.visits.prefix(50))
    }
  }
  func recordSearch(_ query: String, now: Date = Date()) {
    let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !clean.isEmpty, clean.count <= 240 else { return }
    _ = update {
      $0.searches.removeAll {
        BibleLibraryReference.normalizedText($0.query)
          == BibleLibraryReference.normalizedText(clean)
      }
      $0.searches.insert(.init(query: clean, searchedAt: now), at: 0)
      $0.searches = Array($0.searches.prefix(20))
    }
  }
  func clearSearches() { _ = update { $0.searches.removeAll() } }
  func clearRecentPassages() { _ = update { $0.visits.removeAll() } }
  func dismissSuggestion(id: String) {
    _ = update {
      $0.dismissedSuggestionIDs.removeAll { $0 == id }
      $0.dismissedSuggestionIDs.insert(id, at: 0)
      $0.dismissedSuggestionIDs = Array($0.dismissedSuggestionIDs.prefix(200))
    }
  }
  func resetSuggestions() { _ = update { $0.dismissedSuggestionIDs.removeAll() } }
  func memoryNotes(limit: Int = 4) -> [BibleLibraryNote] {
    Array(notes.filter { $0.includeInCompanionMemory }.prefix(max(0, limit)))
  }

  @discardableResult
  private func update(_ change: (inout BibleLibraryState) -> Void) -> Bool {
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
      storageError = "Your changes could not be saved. Please try again."
      return false
    }
  }
}
