import SwiftUI

@MainActor
struct BibleLibraryView: View {
  @ObservedObject private var library = BibleLibraryStore.shared
  @ObservedObject private var reflections = PassageReflectionStore.shared
  @State private var filter: Filter = .all
  @State private var query = ""
  @State private var reading: BibleLibraryLocation?
  @State private var editing: BibleLibraryLocation?
  @State private var reflectionToView: ReflectionSelection?
  @State private var pendingDelete: Entry?
  @State private var confirmingDelete = false
  @State private var confirmingClearSearches = false
  @State private var confirmingClearVisits = false

  private enum Filter: String, CaseIterable, Identifiable {
    case all = "All"
    case bookmarks = "Bookmarks"
    case highlights = "Highlights"
    case notes = "Notes"
    case reflections = "Reflections"
    case recent = "Recent"
    var id: String { rawValue }
  }
  private struct ReflectionSelection: Identifiable {
    let id: UUID
    let reference: String
  }
  private struct Entry: Identifiable {
    let id: String
    let kind: Filter
    let location: BibleLibraryLocation?
    let reference: String
    let text: String
    let date: Date
    var noteID: UUID? = nil
    var color: BibleHighlightColor? = nil
    var icon: String {
      switch kind {
      case .bookmarks: return "bookmark.fill"
      case .highlights: return "highlighter"
      case .notes: return "note.text"
      case .reflections: return "text.bubble"
      default: return "clock"
      }
    }
  }
  private var entries: [Entry] {
    var result: [Entry] = library.bookmarks.map {
      Entry(
        id: "bookmark::" + $0.id, kind: .bookmarks, location: $0.location,
        reference: $0.location.reference,
        text: "Saved passage", date: $0.createdAt)
    }
    result += library.highlights.map {
      Entry(
        id: "highlight::" + $0.id, kind: .highlights, location: $0.location,
        reference: $0.location.reference,
        text: $0.color.title + " highlight", date: $0.updatedAt, color: $0.color)
    }
    result += library.notes.map {
      Entry(
        id: "note::" + $0.id.uuidString, kind: .notes, location: $0.location,
        reference: $0.location.reference,
        text: $0.text, date: $0.updatedAt, noteID: $0.id)
    }
    result += reflections.recent(limit: Int.max).map {
      Entry(
        id: "reflection::" + $0.id.uuidString, kind: .reflections,
        location: BibleLibraryReference.parse($0.reference),
        reference: $0.reference, text: $0.text, date: $0.updatedAt, noteID: $0.id)
    }
    result += library.visits.map {
      Entry(
        id: "visit::" + $0.id, kind: .recent, location: $0.location,
        reference: $0.location.reference,
        text: "Recently opened", date: $0.visitedAt)
    }
    let needle = BibleLibraryReference.normalizedText(query)
    return result.filter {
      (filter == .all || $0.kind == filter)
        && (needle.isEmpty
          || BibleLibraryReference.normalizedText($0.reference + " " + $0.text).contains(needle))
    }.sorted { $0.date == $1.date ? $0.id < $1.id : $0.date > $1.date }
  }

  var body: some View {
    List {
      Section {
        VStack(alignment: .leading, spacing: 8) {
          Text("Your Bible, in your own words.").font(.title3.weight(.semibold))
          Text("Saved passages, notes and reflections stay here when you leave.").font(.subheadline)
            .foregroundStyle(AppTheme.textSecondary)
        }.padding(.vertical, 6)
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(Filter.allCases) { item in
              Button {
                filter = item
              } label: {
                Text(item.rawValue).font(.subheadline.weight(.semibold))
                  .padding(.horizontal, 13).padding(.vertical, 10)
                  .background(
                    Capsule().fill(
                      filter == item
                        ? AppTheme.accent.opacity(0.14) : AppTheme.textSecondary.opacity(0.08)))
              }
              .buttonStyle(.plain)
              .accessibilityAddTraits(filter == item ? .isSelected : [])
            }
          }
        }
      }
      if let error = library.storageError {
        Section { Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
      }
      Section {
        if entries.isEmpty {
          VStack(alignment: .leading, spacing: 9) {
            Image(systemName: "books.vertical").font(.largeTitle).foregroundStyle(AppTheme.textSecondary)
            Text(query.isEmpty ? "Nothing here yet" : "No matching saved items").font(.headline)
            Text(
              query.isEmpty
                ? "Open Scripture, select a verse, then highlight it, add a note, or save a bookmark."
                : "Try a reference or a word from your notes."
            )
            .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
          }.padding(.vertical, 20)
        } else {
          ForEach(entries) { entry in
            Button {
              open(entry)
            } label: {
              BibleLibraryPassageRow(
                title: entry.reference, subtitle: entry.text, icon: entry.icon,
                detail: entry.kind.rawValue + " \u{2022} "
                  + entry.date.formatted(date: .abbreviated, time: .omitted))
            }
            .buttonStyle(.plain)
            .contextMenu {
              if let location = entry.location {
                Button("Open Passage") { reading = location }
              }
              if entry.kind == .notes {
                Button("Edit Note") { editing = entry.location }
              }
              if entry.kind != .recent {
                Button("Remove", role: .destructive) {
                  pendingDelete = entry
                  confirmingDelete = true
                }
              }
            }
          }
        }
      } header: {
        Text("\(entries.count) \(entries.count == 1 ? "item" : "items")")
      }
    }
    .scrollContentBackground(.hidden)
    .cloudScreen()
    .navigationTitle("Your Bible")
    .searchable(text: $query, prompt: "Search saved passages and notes")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          Button("Clear Recent Searches", role: .destructive) { confirmingClearSearches = true }
          Button("Clear Recent Passages", role: .destructive) { confirmingClearVisits = true }
          Button("Show Hidden Home Suggestions") { library.resetSuggestions() }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
        .accessibilityLabel("Library options")
      }
    }
    .navigationDestination(item: $reading) { location in
      BibleReaderView(
        book: location.book, chapter: location.chapter, initialVerses: location.verses)
    }
    .sheet(item: $editing) { location in
      NavigationStack { BibleLibraryNoteEditor(location: location) }
    }
    .sheet(item: $reflectionToView) { selected in
      NavigationStack { BibleLibraryReflectionViewer(reference: selected.reference) }
    }
    .confirmationDialog(
      "Remove this saved item?", isPresented: $confirmingDelete, titleVisibility: .visible
    ) {
      Button("Remove", role: .destructive) { removePending() }
      Button("Cancel", role: .cancel) { pendingDelete = nil }
    } message: {
      Text("This removes only this item, not the Bible passage or your journey progress.")
    }
    .confirmationDialog(
      "Clear recent searches?", isPresented: $confirmingClearSearches, titleVisibility: .visible
    ) {
      Button("Clear Searches", role: .destructive) { library.clearSearches() }
    }
    .confirmationDialog(
      "Clear this Library's recent passages?", isPresented: $confirmingClearVisits,
      titleVisibility: .visible
    ) {
      Button("Clear Recent Passages", role: .destructive) { library.clearRecentPassages() }
    } message: {
      Text("Bookmarks, notes, highlights and the app's existing study history will stay saved.")
    }
  }
  private func open(_ entry: Entry) {
    if entry.kind == .notes {
      editing = entry.location
    } else if entry.kind == .reflections {
      reflectionToView = .init(id: entry.noteID ?? UUID(), reference: entry.reference)
    } else {
      reading = entry.location
    }
  }
  private func removePending() {
    guard let entry = pendingDelete else { return }
    switch entry.kind {
    case .bookmarks: if let location = entry.location { library.removeBookmark(location) }
    case .highlights: if let location = entry.location { library.setHighlight(nil, at: location) }
    case .notes: if let id = entry.noteID { library.deleteNote(id: id) }
    case .reflections: reflections.remove(reference: entry.reference)
    default: break
    }
    pendingDelete = nil
  }
}

@MainActor
private struct BibleLibraryReflectionViewer: View {
  let reference: String
  @Environment(\.dismiss) private var dismiss
  @ObservedObject private var store = PassageReflectionStore.shared
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text(reference).font(.title2.weight(.bold))
        Text(store.text(for: reference)).lineSpacing(6).textSelection(.enabled)
        Text("To edit, open this passage in Study with Companion.").font(.caption).foregroundStyle(AppTheme.textSecondary)
      }.frame(maxWidth: .infinity, alignment: .leading).padding()
    }
    .navigationTitle("Your Reflection")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
  }
}
