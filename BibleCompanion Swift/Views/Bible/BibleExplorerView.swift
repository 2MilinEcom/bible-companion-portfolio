import Combine
import SwiftUI

nonisolated struct BibleExplorerHit: Identifiable, Sendable {
  let location: BibleLibraryLocation
  let text: String
  let searchableText: String
  var id: String { location.id }
}

@MainActor
final class BibleExplorerViewModel: ObservableObject {
  @Published private(set) var results: [BibleExplorerHit] = []
  @Published private(set) var availableBooks: [String] = []
  @Published private(set) var directLocation: BibleLibraryLocation?
  @Published private(set) var searchMessage: String?
  @Published private(set) var loadError: String?
  private var searchRevision = 0
  private var all: [BibleExplorerHit] = []
  private var byChapter: [String: [BibleExplorerHit]] = [:]
  private var bookChapters: [String: [Int]] = [:]

  @Published private(set) var isLoading = true

  init() { Task { await load() } }

  private func load() async {
    defer { isLoading = false }
    do {
      let verses = try await BibleService.shared.preload()
      all = await Task.detached(priority: .userInitiated) {
      var seen: Set<String> = []
      return verses.compactMap { verse in
        let location = BibleLibraryLocation(
          book: verse.book, chapter: verse.chapter, verses: [verse.verse])
        guard location.isValid, seen.insert(location.id).inserted else { return nil }
        return BibleExplorerHit(
          location: location, text: verse.text,
          searchableText: BibleLibraryReference.normalizedText(verse.text))
      }
      }.value
      let names = Set(all.map { $0.location.book })
      availableBooks = BibleLibraryReference.books.filter { names.contains($0) }
      byChapter = Dictionary(grouping: all, by: { $0.location.chapterID })
      bookChapters = Dictionary(grouping: all, by: { $0.location.book }).mapValues {
        Array(Set($0.map { $0.location.chapter })).sorted()
      }
    } catch { loadError = error.localizedDescription }
  }
  func chapters(for book: String) -> [Int] {
    bookChapters[book] ?? []
  }
  func suggestions(for query: String) -> [String] {
    BibleLibraryReference.suggestedBooks(for: query).filter { availableBooks.contains($0) }
  }
  func search(_ query: String) async {
    searchRevision += 1
    let revision = searchRevision
    while isLoading {
      do { try await Task.sleep(for: .milliseconds(30)) } catch { return }
    }
    guard !Task.isCancelled, revision == searchRevision else { return }
    results = []
    directLocation = nil
    searchMessage = nil
    let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !clean.isEmpty else { return }
    guard clean.count <= 240 else {
      searchMessage = "Try a shorter reference or a few words from a verse."
      return
    }
    if let location = BibleLibraryReference.parse(clean) {
      guard let chapter = byChapter[location.chapterID] else {
        searchMessage = "That chapter is not available. Choose a chapter from Browse Books below."
        return
      }
      let valid = Set(chapter.flatMap { $0.location.verses })
      guard Set(location.verses).isSubset(of: valid) else {
        searchMessage = "One or more verse numbers are outside this chapter."
        return
      }
      directLocation = location
      results = chapter.filter {
        location.verses.isEmpty || location.verses.contains($0.location.verses[0])
      }
      .sorted { $0.location.verses[0] < $1.location.verses[0] }
      return
    }
    if BibleLibraryReference.canonicalBook(clean) != nil { return }
    let terms = BibleLibraryReference.normalizedText(clean).split(separator: " ").map(String.init)
    guard !terms.isEmpty else { return }
    let index = all
    let matches = await Task.detached(priority: .userInitiated) {
      index.filter { hit in terms.allSatisfy { hit.searchableText.contains($0) } }
    }.value
    guard !Task.isCancelled, revision == searchRevision else { return }
    results = matches
    if results.isEmpty {
      searchMessage =
        "No matching verses. Try a book, a reference such as John 15:1-8, or words from a verse. Select one chapter at a time for references."
    }
  }
}

/// Shared Bible browsing and search destination.
@MainActor
struct BibleExplorerView: View {
  @StateObject private var model = BibleExplorerViewModel()
  @ObservedObject private var library = BibleLibraryStore.shared
  @State private var query = ""
  @State private var resultLimit = 40
  @State private var reading: BibleLibraryLocation?

  var body: some View {
    List {
      if model.isLoading { ProgressView("Opening your Bible…") }
      if let error = model.loadError {
        Section {
          Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(AppTheme.textSecondary)
        }
      }
      if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        recentSections
      } else {
        if let location = model.directLocation {
          Section("Open reference") {
            Button {
              open(location)
            } label: {
              BibleLibraryPassageRow(
                title: location.reference, subtitle: "Read this passage with your saved markings",
                icon: "book.fill")
            }.buttonStyle(.plain)
          }
        }
        if !model.suggestions(for: query).isEmpty {
          Section("Suggested books") {
            ForEach(model.suggestions(for: query), id: \.self) { book in
              NavigationLink {
                BibleExplorerChaptersView(book: book, chapters: model.chapters(for: book))
              } label: {
                Label(book, systemImage: "book.closed")
              }
              .simultaneousGesture(TapGesture().onEnded { library.recordSearch(query) })
            }
          }
        }
        if let message = model.searchMessage {
          Section { Text(message).font(.subheadline).foregroundStyle(AppTheme.textSecondary) }
        }
        if !model.results.isEmpty {
          Section("\(model.results.count) matching verses") {
            ForEach(Array(model.results.prefix(resultLimit))) { hit in
              Button {
                open(hit.location)
              } label: {
                BibleLibraryPassageRow(
                  title: hit.location.reference, subtitle: hit.text, icon: "text.alignleft")
              }.buttonStyle(.plain)
            }
            if model.results.count > resultLimit {
              Button("Show More Results") { resultLimit += 40 }
            }
          }
        }
      }
      Section("Browse Books") {
        ForEach(model.availableBooks, id: \.self) { book in
          NavigationLink {
            BibleExplorerChaptersView(book: book, chapters: model.chapters(for: book))
          } label: {
            Label(book, systemImage: "book.closed")
          }
        }
      }
    }
    .scrollContentBackground(.hidden)
    .cloudScreen()
    .navigationTitle("Read Scripture")
    .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Book, passage or words from a verse")
    .onSubmit(of: .search) {
      library.recordSearch(query)
      Task { await model.search(query) }
    }
    .task(id: query) {
      do { try await Task.sleep(nanoseconds: 220_000_000) } catch { return }
      guard !Task.isCancelled else { return }
      resultLimit = 40
      await model.search(query)
    }
    .navigationDestination(item: $reading) { location in
      BibleReaderView(
        book: location.book, chapter: location.chapter, initialVerses: location.verses)
    }
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        NavigationLink {
          BibleLibraryView()
        } label: {
          Image(systemName: "books.vertical")
        }
        .accessibilityLabel("Your saved Bible")
      }
    }
  }
  @ViewBuilder
  private var recentSections: some View {
    if !library.visits.isEmpty {
      Section("Recent Passages") {
        ForEach(Array(library.visits.prefix(5))) { visit in
          Button {
            reading = visit.location
          } label: {
            BibleLibraryPassageRow(
              title: visit.location.reference, subtitle: "Continue reading", icon: "clock")
          }.buttonStyle(.plain)
        }
      }
    }
    if !library.searches.isEmpty {
      Section("Recent Searches") {
        ForEach(Array(library.searches.prefix(6))) { item in
          Button {
            query = item.query
            library.recordSearch(item.query)
          } label: {
            Label(item.query, systemImage: "magnifyingglass")
          }
        }
      }
    }
  }
  private func open(_ location: BibleLibraryLocation) {
    library.recordSearch(query)
    reading = location
  }
}

@MainActor
private struct BibleExplorerChaptersView: View {
  let book: String
  let chapters: [Int]
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        Text("Choose a chapter").font(.headline).foregroundStyle(AppTheme.textSecondary)
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 58), spacing: 12)], spacing: 12) {
          ForEach(chapters, id: \.self) { chapter in
            NavigationLink {
              BibleReaderView(book: book, chapter: chapter)
            } label: {
              Text("\(chapter)").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 17)
                .background(
                  RoundedRectangle(cornerRadius: 14).fill(AppTheme.accent.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(book) chapter \(chapter)")
          }
        }
      }.padding()
    }
    .navigationTitle(book)
    .navigationBarTitleDisplayMode(.inline)
  }
}
