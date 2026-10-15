import SwiftUI

@MainActor
struct BibleReaderView: View {
  let book: String
  let chapter: Int
  let initialVerses: [Int]
  let originJourneyID: String?
  let originCheckpointID: String?

  @Environment(\.dismiss) private var dismiss
  @StateObject private var viewModel = BibleViewModel()
  @ObservedObject private var library = BibleLibraryStore.shared
  @State private var selectedVerses: Set<Int> = []
  @State private var didInitialScroll = false
  @State private var didRecordReadingActivity = false
  @State private var journeyMatches: [BibleLibraryJourneyMatch] = []
  @State private var editingNote: BibleLibraryLocation?
  @State private var showingReadingSettings = false

  init(
    book: String, chapter: Int, initialVerses: [Int] = [],
    originJourneyID: String? = nil, originCheckpointID: String? = nil
  ) {
    self.book = book
    self.chapter = chapter
    self.initialVerses = initialVerses
    self.originJourneyID = originJourneyID
    self.originCheckpointID = originCheckpointID
  }

  var chapterVerses: [BibleVerse] { viewModel.chapter(book: book, chapter: chapter) }
  var selectedBibleVerses: [BibleVerse] {
    chapterVerses.filter { selectedVerses.contains($0.verse) }
  }
  private var chapterLocation: BibleLibraryLocation { .init(book: book, chapter: chapter) }
  private var selectedLocation: BibleLibraryLocation {
    .init(book: book, chapter: chapter, verses: selectedBibleVerses.map(\.verse))
  }
  var selectedPassage: String {
    selectedLocation.reference + "\n\n"
      + selectedBibleVerses.map { "\($0.verse) \($0.text)" }.joined(separator: "\n")
  }

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 5) {
          if let match = journeyMatches.first {
            BibleJourneyReaderBanner(match: match) { dismiss() }
              .padding(.bottom, 15)
          }
          if let error = viewModel.errorMessage {
            Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(AppTheme.textSecondary)
              .padding()
          } else if viewModel.isLoading {
            ProgressView("Opening Scripture…").padding()
          } else if chapterVerses.isEmpty {
            Text("This chapter is not available in the bundled Bible.").foregroundStyle(AppTheme.textSecondary)
              .padding()
          } else {
            Text("Tap verses to study, highlight or save them.")
              .font(.caption).foregroundStyle(AppTheme.textSecondary).padding(.bottom, 10)
            ForEach(chapterVerses) { verse in
              verseRow(verse).id(verse.verse)
            }
          }
        }
        .padding()
      }
      .safeAreaInset(edge: .bottom, spacing: 0) {
        if !selectedBibleVerses.isEmpty { selectionTools }
      }
      .onAppear {
        journeyMatches = BibleLibraryJourneyResolver.matches(
          location: chapterLocation,
          originJourneyID: originJourneyID, originCheckpointID: originCheckpointID)
        prepareInitialPassage(using: proxy)
        recordReadingActivityIfNeeded()
      }
      .onChange(of: chapterVerses.count) { _, count in
        if count > 0 {
          prepareInitialPassage(using: proxy)
          recordReadingActivityIfNeeded()
        }
      }
    }
    .cloudScreen()
    .navigationTitle(chapterLocation.reference)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          showingReadingSettings = true
        } label: {
          Image(systemName: "textformat.size")
        }
        .accessibilityLabel("Reading settings")
      }
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          Button(
            library.isBookmarked(chapterLocation) ? "Remove Chapter Bookmark" : "Bookmark Chapter"
          ) {
            library.toggleBookmark(chapterLocation)
          }
          Button("Chapter Note") { editingNote = chapterLocation }
          NavigationLink("Your Bible") { BibleLibraryView() }
        } label: {
          Image(systemName: "bookmark.circle")
        }
        .accessibilityLabel("Saved Bible and chapter options")
      }
    }
    .sheet(item: $editingNote) { location in
      NavigationStack { BibleLibraryNoteEditor(location: location) }
    }
    .sheet(isPresented: $showingReadingSettings) {
      NavigationStack {
        ReadingAppearanceSettingsView()
          .toolbar {
            ToolbarItem(placement: .confirmationAction) {
              Button("Done") { showingReadingSettings = false }
            }
          }
      }
    }
  }

  private func verseRow(_ verse: BibleVerse) -> some View {
    let location = BibleLibraryLocation(book: book, chapter: chapter, verses: [verse.verse])
    let highlight = library.highlight(at: location)
    let isSelected = selectedVerses.contains(verse.verse)
    let savedNote = library.hasNote(at: location)
    return Button {
      if isSelected {
        selectedVerses.remove(verse.verse)
      } else {
        selectedVerses.insert(verse.verse)
      }
      // Only deliberate selection changes update the remembered location.
      // Returning from a child study/chat screen does not overwrite its resume record.
      rememberLocation(selectedVerses.isEmpty ? chapterLocation : selectedLocation)
    } label: {
      HStack(alignment: .top, spacing: 12) {
        VStack(spacing: 6) {
          Text("\(verse.verse)").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.textSecondary)
          if savedNote {
            Image(systemName: "note.text").font(.caption2).foregroundStyle(AppTheme.accent)
          }
          if highlight != nil {
            Image(systemName: "highlighter").font(.system(size: 9)).foregroundStyle(AppTheme.textSecondary)
          }
        }.frame(width: 25)
        Text(verse.text).bibleReadingStyle().foregroundStyle(AppTheme.textPrimary)
          .frame(maxWidth: .infinity, alignment: .leading)
        // Keep the selection indicator in the layout even when invisible.
        // Inserting/removing it changes the text width and makes verses rewrap.
        Image(systemName: "checkmark.circle.fill")
          .font(.caption)
          .foregroundStyle(AppTheme.accent)
          .opacity(isSelected ? 1 : 0)
          .accessibilityHidden(true)
      }
      .padding(.vertical, 11).padding(.horizontal, 11)
      .background(
        RoundedRectangle(cornerRadius: 12).fill(
          highlight?.color.displayColor.opacity(0.19) ?? Color.clear)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 12)
          .stroke(isSelected ? AppTheme.accent : Color.clear, lineWidth: 1.5)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(
      "Verse \(verse.verse). \(verse.text)\(highlight.map { ". \($0.color.title) highlight" } ?? "")\(savedNote ? ". Has a saved note" : "")"
    )
    .accessibilityAddTraits(isSelected ? .isSelected : [])
    .contextMenu {
      Button("Add or Edit Note") { editingNote = location }
      Button(library.isBookmarked(location) ? "Remove Bookmark" : "Bookmark Verse") {
        library.toggleBookmark(location)
      }
      Menu("Highlight") {
        ForEach(BibleHighlightColor.allCases) { color in
          Button(color.title) { library.setHighlight(color, at: location) }
        }
        Button("Remove", role: .destructive) { library.setHighlight(nil, at: location) }
      }
      ForEach(library.notes(overlapping: location)) { note in
        Button("Edit note on \(note.location.reference)") { editingNote = note.location }
      }
    }
  }

  private var selectionTools: some View {
    VStack(spacing: 9) {
      HStack {
        Text(selectedLocation.reference).font(.caption.weight(.semibold)).lineLimit(1)
        Spacer()
        Button("Clear") { selectedVerses.removeAll() }.font(.caption)
      }
      NavigationLink {
        BibleStudyView(
          reference: BibleLibraryReference.legacyStudyReference(selectedLocation),
          passage: selectedPassage)
      } label: {
        HStack(spacing: 10) {
          CompanionAvatar(size: 28, behavior: .still)
          Text("Study with Companion").fontWeight(.semibold)
          Spacer()
          Image(systemName: "arrow.right")
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.accent.opacity(0.1)))
      }.buttonStyle(.plain)
      ScrollView(.horizontal, showsIndicators: false) {
        BibleLibraryActions(location: selectedLocation)
      }
      HStack(spacing: 10) {
        NavigationLink {
          CompanionView(passage: selectedPassage, mode: .explain)
        } label: {
          StudyButton(title: "Explain", icon: "sparkles")
        }
        NavigationLink {
          PerspectivesView(passage: selectedPassage)
        } label: {
          StudyButton(title: "Views", icon: "person.3.fill")
        }
        NavigationLink {
          CompanionView(passage: selectedPassage, mode: .challenge)
        } label: {
          StudyButton(title: "Challenge", icon: "brain.head.profile")
        }
      }
      if let error = library.storageError {
        Text(error).font(.caption).foregroundStyle(.red)
      }
    }
    .padding(.horizontal, 16).padding(.vertical, 10)
    .background(.ultraThinMaterial)
  }

  private func prepareInitialPassage(using proxy: ScrollViewProxy) {
    guard !didInitialScroll, !chapterVerses.isEmpty else { return }
    let valid = Set(chapterVerses.map(\.verse)).intersection(initialVerses)
    selectedVerses = valid
    didInitialScroll = true
    guard let target = valid.min() else { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      proxy.scrollTo(target, anchor: .center)
    }
  }
  private func rememberLocation(_ location: BibleLibraryLocation) {
    library.recordVisit(location)
    ResumeActivityStore.shared.recordReading(
      book: location.book, chapter: location.chapter,
      verses: location.verses, reference: location.reference)
  }
  private func recordReadingActivityIfNeeded() {
    guard !didRecordReadingActivity, !chapterVerses.isEmpty else { return }
    didRecordReadingActivity = true
    let valid = Set(chapterVerses.map(\.verse)).intersection(initialVerses)
    let location = BibleLibraryLocation(book: book, chapter: chapter, verses: Array(valid))
    rememberLocation(location)
    let history = StudyHistoryService.shared
    if let latest = history.loadActivities().first, latest.type == .reading,
      latest.passage == location.reference, Date().timeIntervalSince(latest.date) < 600
    {
      return
    }
    history.record(StudyActivity.bibleReading(reference: location.reference))
  }
}

// Retains the public component used by the original reader.
struct StudyButton: View {
  let title: String
  let icon: String
  var body: some View {
    Label(title, systemImage: icon).font(.caption.weight(.semibold))
      .frame(maxWidth: .infinity).padding(.vertical, 10)
      .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.surface))
  }
}
