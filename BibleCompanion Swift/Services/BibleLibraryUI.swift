import SwiftUI

extension BibleHighlightColor {
  var displayColor: Color {
    switch self {
    case .gold: return .yellow
    case .green: return .green
    case .blue: return .blue
    case .rose: return .pink
    }
  }
}

@MainActor
struct BibleLibraryActions: View {
  let location: BibleLibraryLocation
  @ObservedObject private var library = BibleLibraryStore.shared
  @State private var editingNote = false

  var body: some View {
    HStack(spacing: 10) {
      Menu {
        ForEach(BibleHighlightColor.allCases) { color in
          Button(color.title) { library.setHighlight(color, at: location) }
        }
        Divider()
        Button("Remove highlight", role: .destructive) { library.setHighlight(nil, at: location) }
      } label: {
        Label("Highlight", systemImage: "highlighter")
      }
      .disabled(location.verses.isEmpty)
      Button {
        editingNote = true
      } label: {
        Label(
          library.note(at: location) == nil ? "Note" : "Edit note", systemImage: "square.and.pencil"
        )
      }
      Button {
        library.toggleBookmark(location)
      } label: {
        Label(
          library.isBookmarked(location) ? "Saved" : "Save",
          systemImage: library.isBookmarked(location) ? "bookmark.fill" : "bookmark")
      }
      .accessibilityLabel(
        library.isBookmarked(location)
          ? "Remove bookmark for \(location.reference)" : "Bookmark \(location.reference)")
    }
    .font(.caption.weight(.semibold))
    .buttonStyle(.bordered)
    .controlSize(.regular)
    .sheet(isPresented: $editingNote) {
      NavigationStack { BibleLibraryNoteEditor(location: location) }
    }
  }
}

@MainActor
struct BibleLibraryNoteEditor: View {
  let location: BibleLibraryLocation
  @Environment(\.dismiss) private var dismiss
  @ObservedObject private var library = BibleLibraryStore.shared
  @State private var text = ""
  @State private var sharedWithCompanion = false
  @State private var originalText = ""
  @State private var originalSharing = false
  @State private var loaded = false
  @State private var confirmingDiscard = false
  @State private var confirmingDelete = false
  @State private var saveFailed = false

  private var isDirty: Bool {
    loaded && (text != originalText || sharedWithCompanion != originalSharing)
  }

  var body: some View {
    Form {
      Section {
        Text(location.reference).font(.headline)
        Text("What do you want to remember?").foregroundStyle(AppTheme.textSecondary)
        TextEditor(text: $text)
          .frame(minHeight: 220)
          .accessibilityLabel("Note for \(location.reference)")
      }
      Section {
        Toggle("Use this note in Companion memory", isOn: $sharedWithCompanion)
      } footer: {
        Text(
          "Off: this note is not added to Companion memory. On: its text may be sent to your existing AI backend with future Companion or study requests. You can turn this off later; it does not erase data already sent."
        )
      }
      if library.note(at: location) != nil {
        Section {
          Button("Delete Note", role: .destructive) { confirmingDelete = true }
        }
      }
      if saveFailed || library.storageError != nil {
        Section {
          Label(
            library.storageError ?? "The note could not be saved. Your text is still here.",
            systemImage: "exclamationmark.triangle"
          )
          .foregroundStyle(.red)
        }
      }
    }
    .scrollContentBackground(.hidden)
    .cloudScreen()
    .navigationTitle("Passage Note")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          if isDirty { confirmingDiscard = true } else { dismiss() }
        }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          if library.saveNote(
            location: location, text: text, includeInCompanionMemory: sharedWithCompanion)
          {
            dismiss()
          } else {
            saveFailed = true
          }
        }
        .fontWeight(.semibold)
        .disabled(!loaded || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
    }
    .onAppear {
      guard !loaded else { return }
      let existing = library.note(at: location)
      text = existing?.text ?? ""
      sharedWithCompanion = existing?.includeInCompanionMemory ?? false
      originalText = text
      originalSharing = sharedWithCompanion
      loaded = true
    }
    .interactiveDismissDisabled(isDirty)
    .confirmationDialog(
      "Discard unsaved changes?", isPresented: $confirmingDiscard, titleVisibility: .visible
    ) {
      Button("Discard Changes", role: .destructive) { dismiss() }
      Button("Keep Editing", role: .cancel) {}
    }
    .confirmationDialog(
      "Delete this note?", isPresented: $confirmingDelete, titleVisibility: .visible
    ) {
      Button("Delete Note", role: .destructive) {
        if let note = library.note(at: location), library.deleteNote(id: note.id) {
          dismiss()
        } else {
          saveFailed = true
        }
      }
      Button("Cancel", role: .cancel) {}
    }
  }
}

@MainActor
struct BibleLibraryPassageRow: View {
  let title: String
  let subtitle: String
  let icon: String
  var detail: String? = nil

  var body: some View {
    HStack(alignment: .top, spacing: 13) {
      Image(systemName: icon)
        .font(.title3)
        .foregroundStyle(AppTheme.accent)
        .frame(width: 30, height: 32)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 5) {
        Text(title).font(.headline).foregroundStyle(AppTheme.textPrimary)
        Text(subtitle).font(.subheadline).foregroundStyle(AppTheme.textSecondary).lineLimit(3)
        if let detail { Text(detail).font(.caption).foregroundStyle(AppTheme.textSecondary) }
      }
      Spacer(minLength: 4)
      Image(systemName: "chevron.right").font(.caption).foregroundStyle(AppTheme.textSecondary)
        .accessibilityHidden(true)
    }
    .padding(.vertical, 7)
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
  }
}
