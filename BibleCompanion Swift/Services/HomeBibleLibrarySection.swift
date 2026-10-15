import SwiftUI

@MainActor
struct HomeBibleLibrarySection: View {
  var excludedTitle: String? = nil
  @ObservedObject private var library = BibleLibraryStore.shared
  @State private var recentStudy: BibleLibraryLocation?
  @State private var activePath: JourneyPath?

  private struct Suggestion: Identifiable {
    let location: BibleLibraryLocation
    let reason: String
    let icon: String
    let sourceID: String
    var id: String { sourceID + "::" + location.id }
  }
  private var suggestions: [Suggestion] {
    var candidates: [Suggestion] = []
    for note in library.notes.prefix(4) {
      candidates.append(
        .init(
          location: note.location,
          reason: reason(for: note.location, fallback: "You saved a note on this passage."),
          icon: "note.text", sourceID: "note::" + note.id.uuidString))
    }
    for bookmark in library.bookmarks.prefix(4) {
      candidates.append(
        .init(
          location: bookmark.location,
          reason: reason(for: bookmark.location, fallback: "A passage you chose to keep."),
          icon: "bookmark.fill", sourceID: "bookmark"))
    }
    if let recentStudy {
      candidates.append(
        .init(
          location: recentStudy, reason: "Revisit a passage from your recent study.", icon: "book",
          sourceID: "study"))
    }
    var seen: Set<String> = []
    return Array(
      candidates.filter {
        $0.location.reference != excludedTitle
          && !library.state.dismissedSuggestionIDs.contains($0.id)
          && seen.insert($0.location.id).inserted
      }.prefix(2))
  }
  private func reason(for location: BibleLibraryLocation, fallback: String) -> String {
    if let activePath,
      activePath.checkpoints.contains(where: {
        BibleLibraryReference.parse($0.passage).map { $0.overlaps(location) } ?? false
      })
    {
      return "This saved passage also appears in your current path: \(activePath.title)."
    }
    return fallback
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 17) {
      NavigationLink {
        BibleLibraryView()
      } label: {
        HStack(spacing: 14) {
          Image(systemName: "books.vertical.fill").font(.title2).foregroundStyle(AppTheme.accent)
          VStack(alignment: .leading, spacing: 5) {
            Text("Your Bible").font(.headline).foregroundStyle(AppTheme.textPrimary)
            Text(
              "\(library.bookmarks.count) saved \u{2022} \(library.notes.count) notes \u{2022} \(library.highlights.count) highlights"
            )
            .font(.caption).foregroundStyle(AppTheme.textSecondary)
          }
          Spacer()
          Image(systemName: "chevron.right").font(.caption).foregroundStyle(AppTheme.textSecondary)
        }
        .padding(18)
        .background(
          RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(AppTheme.surfaceStrong)
            .shadow(color: AppTheme.shadow, radius: 10, y: 4)
        )
        .overlay(
          RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
      }.buttonStyle(.plain)
      if !suggestions.isEmpty {
        Text("FROM YOUR BIBLE").font(.caption.weight(.bold)).foregroundStyle(AppTheme.textSecondary)
        ForEach(suggestions) { suggestion in
          HStack(alignment: .top, spacing: 6) {
            NavigationLink {
              BibleReaderView(
                book: suggestion.location.book, chapter: suggestion.location.chapter,
                initialVerses: suggestion.location.verses)
            } label: {
              BibleLibraryPassageRow(
                title: suggestion.location.reference, subtitle: suggestion.reason,
                icon: suggestion.icon)
            }.buttonStyle(.plain)
            Button {
              library.dismissSuggestion(id: suggestion.id)
            } label: {
              Image(systemName: "xmark").font(.caption).foregroundStyle(AppTheme.textSecondary).frame(
                width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Hide suggestion for \(suggestion.location.reference)")
          }
        }
      }
    }
    .onAppear {
      activePath = StorageService.shared.loadActivePersonalizedPath()
      recentStudy = StudyHistoryService.shared.loadActivities()
        .first(where: { $0.type == .passageStudy || $0.type == .reading })
        .flatMap { BibleLibraryReference.parse($0.passage) }
    }
  }
}
