import Foundation
import SwiftUI

// =========================================================
// MARK: - Resume Activity
// =========================================================

/// Lightweight navigation memory for "Continue Where You Left Off."
///
/// This does not interpret the user's spirituality. It only remembers the
/// last concrete places they opened in the app so Home can return them there.
enum ResumeActivityKind:
  String,
  Codable
{

  case checkpoint
  case reading
  case companion
  case study
}

struct ResumeActivityRecord:
  Identifiable,
  Codable
{

  let id: UUID

  let kind: ResumeActivityKind

  let date: Date

  let journeyID: String?

  let checkpointID: String?

  let book: String?

  let chapter: Int?

  let verses: [Int]

  let passage: String

  let conversationKey: String?
  let studyReference: String?

  init(
    id: UUID = UUID(),
    kind: ResumeActivityKind,
    date: Date = Date(),
    journeyID: String? = nil,
    checkpointID: String? = nil,
    book: String? = nil,
    chapter: Int? = nil,
    verses: [Int] = [],
    passage: String = "",
    conversationKey: String? = nil,
    studyReference: String? = nil
  ) {

    self.id = id
    self.kind = kind
    self.date = date
    self.journeyID = journeyID
    self.checkpointID = checkpointID
    self.book = book
    self.chapter = chapter
    self.verses = verses
    self.passage = passage
    self.conversationKey = conversationKey
    self.studyReference = studyReference
  }
}

// =========================================================
// MARK: - Resume Activity Store
// =========================================================

final class ResumeActivityStore {

  static let shared =
    ResumeActivityStore()

  private let storageKey =
    "bibleCompanionResumeActivities"

  private let defaults =
    UserDefaults.standard

  private let maximumRecords =
    20

  private init() {}

  func recentActivities()
    -> [ResumeActivityRecord]
  {

    load()
      .sorted {
        $0.date > $1.date
      }
  }

  func recordCheckpoint(
    journey: JourneyPath,
    checkpoint: JourneyCheckpoint
  ) {

    saveNew(
      ResumeActivityRecord(
        kind: .checkpoint,
        journeyID: journey.id,
        checkpointID: checkpoint.id,
        passage: checkpoint.passage
      )
    )
  }

  func recordReading(
    book: String,
    chapter: Int,
    verses: [Int],
    reference: String
  ) {

    saveNew(
      ResumeActivityRecord(
        kind: .reading,
        book: book,
        chapter: chapter,
        verses: verses.sorted(),
        passage: reference
      )
    )
  }

  func recordCompanion(
    conversationKey: String,
    passage: String
  ) {

    saveNew(
      ResumeActivityRecord(
        kind: .companion,
        passage: passage,
        conversationKey: conversationKey
      )
    )
  }

  func recordStudy(reference: String, passage: String) {
    guard !reference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
    saveNew(ResumeActivityRecord(kind: .study, passage: passage, studyReference: reference))
  }

  private func saveNew(
    _ record: ResumeActivityRecord
  ) {

    var records =
      load()

    // Keep one fresh entry per destination instead of filling the list
    // with repeated opens of the exact same screen.
    records.removeAll {
      sameDestination(
        $0,
        record
      )
    }

    records.insert(
      record,
      at: 0
    )

    if records.count > maximumRecords {

      records =
        Array(
          records.prefix(
            maximumRecords
          )
        )
    }

    persist(
      records
    )
  }

  private func sameDestination(
    _ lhs: ResumeActivityRecord,
    _ rhs: ResumeActivityRecord
  ) -> Bool {

    guard lhs.kind == rhs.kind else {
      return false
    }

    switch lhs.kind {
    case .study:
      return lhs.studyReference == rhs.studyReference

    case .checkpoint:

      return
        lhs.journeyID == rhs.journeyID
        && lhs.checkpointID == rhs.checkpointID

    case .reading:

      return
        lhs.book == rhs.book
        && lhs.chapter == rhs.chapter
        && lhs.verses == rhs.verses

    case .companion:

      return
        lhs.conversationKey == rhs.conversationKey
    }
  }

  private func persist(
    _ records: [ResumeActivityRecord]
  ) {

    do {

      let data =
        try JSONEncoder()
        .encode(
          records
        )

      defaults.set(
        data,
        forKey:
          storageKey
      )

    } catch {

      print(
        "Resume activity save error:",
        error
      )
    }
  }

  private func load()
    -> [ResumeActivityRecord]
  {

    guard
      let data =
        defaults.data(
          forKey:
            storageKey
        )
    else {

      return []
    }

    do {

      return
        try JSONDecoder()
        .decode(
          [ResumeActivityRecord].self,
          from:
            data
        )

    } catch {

      print(
        "Resume activity load error:",
        error
      )

      return []
    }
  }
}

// =========================================================
// MARK: - Home Continue Item
// =========================================================

enum HomeContinueDestination {
  case study(reference: String, passage: String)

  case checkpoint(
    journey: JourneyPath,
    checkpoint: JourneyCheckpoint,
    isPersonalized: Bool
  )

  case reading(
    book: String,
    chapter: Int,
    verses: [Int]
  )

  case companion(
    conversationKey: String,
    passage: String
  )
}

struct HomeContinueItem:
  Identifiable
{

  let id: String

  let eyebrow: String

  let title: String

  let subtitle: String

  let icon: String

  let date: Date

  let destination: HomeContinueDestination
}

// =========================================================
// MARK: - Home Continue Service
// =========================================================

@MainActor
final class HomeContinueService {

  static let shared =
    HomeContinueService()

  private let resumeStore =
    ResumeActivityStore.shared

  private let storageService =
    StorageService.shared

  private let historyService =
    StudyHistoryService.shared

  private let conversationStore =
    CompanionConversationStore.shared

  private init() {}

  func mostRecentItem(
    foundationJourney: JourneyPath,
    progressStore: JourneyProgressStore
  ) -> HomeContinueItem? {

    var candidates: [HomeContinueItem] = []

    // -------------------------------------------------
    // Exact app-location memory (preferred)
    // -------------------------------------------------

    for record
      in resumeStore
      .recentActivities()
    {

      if let item =
        item(
          from:
            record,
          foundationJourney:
            foundationJourney,
          progressStore:
            progressStore
        )
      {

        candidates.append(
          item
        )
      }
    }

    // -------------------------------------------------
    // Migration/fallback from data that already existed
    // before ResumeActivityStore was introduced.
    // -------------------------------------------------

    if let reading =
      fallbackReadingItem()
    {

      candidates.append(
        reading
      )
    }

    if let conversation =
      fallbackConversationItem()
    {

      candidates.append(
        conversation
      )
    }

    if let personalized =
      fallbackPersonalizedJourneyItem(
        progressStore:
          progressStore
      )
    {

      candidates.append(
        personalized
      )
    }

    if let foundation =
      fallbackFoundationJourneyItem(
        journey:
          foundationJourney,
        progressStore:
          progressStore
      )
    {

      candidates.append(
        foundation
      )
    }

    return
      candidates
      .max {
        $0.date < $1.date
      }
  }

  private func item(
    from record: ResumeActivityRecord,
    foundationJourney: JourneyPath,
    progressStore: JourneyProgressStore
  ) -> HomeContinueItem? {

    switch record.kind {
    case .study:
      guard let reference = record.studyReference, !record.passage.isEmpty else { return nil }
      return HomeContinueItem(
        id: "study::" + reference, eyebrow: "BIBLE STUDY", title: reference,
        subtitle: "Continue studying and reflecting on this passage.", icon: "book.closed.fill",
        date: record.date,
        destination: .study(reference: reference, passage: record.passage))

    case .checkpoint:

      guard
        let journeyID =
          record.journeyID
      else {
        return nil
      }

      if journeyID == foundationJourney.id {

        guard
          let current =
            progressStore
            .currentCheckpoint(
              in:
                foundationJourney
            )
        else {
          return nil
        }

        return checkpointItem(
          journey:
            foundationJourney,
          checkpoint:
            current,
          isPersonalized:
            false,
          date:
            record.date
        )
      }

      guard
        let personalizedRecord =
          storageService
          .loadPersonalizedJourney(
            journeyID:
              journeyID
          ),
        personalizedRecord.status == .active,
        let current =
          progressStore
          .currentCheckpoint(
            in:
              personalizedRecord.journey
          )
      else {

        return nil
      }

      return checkpointItem(
        journey:
          personalizedRecord.journey,
        checkpoint:
          current,
        isPersonalized:
          true,
        date:
          record.date
      )

    case .reading:

      guard
        let book =
          record.book,
        let chapter =
          record.chapter
      else {

        return nil
      }

      return readingItem(
        book:
          book,
        chapter:
          chapter,
        verses:
          record.verses,
        reference:
          record.passage.isEmpty
          ? "\(book) \(chapter)"
          : record.passage,
        date:
          record.date
      )

    case .companion:

      guard
        let key =
          record.conversationKey,
        let conversation =
          conversationStore
          .conversation(
            for:
              key
          ),
        !conversation.messages.isEmpty
      else {

        return nil
      }

      return companionItem(
        key:
          key,
        passage:
          record.passage,
        messages:
          conversation.messages,
        date:
          record.date
      )
    }
  }

  private func fallbackReadingItem()
    -> HomeContinueItem?
  {

    guard
      let activity =
        historyService
        .loadActivities()
        .first(
          where: {
            $0.type == .reading
          }
        ),
      let parsed =
        parseReadingReference(
          activity.passage
        )
    else {

      return nil
    }

    return readingItem(
      book:
        parsed.book,
      chapter:
        parsed.chapter,
      verses:
        parsed.verses,
      reference:
        activity.passage,
      date:
        activity.date
    )
  }

  private func fallbackConversationItem()
    -> HomeContinueItem?
  {

    guard
      let snapshot =
        conversationStore
        .recentConversations(
          limit:
            1
        )
        .first
    else {

      return nil
    }

    return companionItem(
      key:
        snapshot.key,
      passage:
        "",
      messages:
        snapshot.messages,
      date:
        snapshot.updatedAt
    )
  }

  private func fallbackPersonalizedJourneyItem(
    progressStore: JourneyProgressStore
  ) -> HomeContinueItem? {

    guard
      let record =
        storageService
        .loadActivePersonalizedJourney(),
      let checkpoint =
        progressStore
        .currentCheckpoint(
          in:
            record.journey
        )
    else {

      return nil
    }

    return checkpointItem(
      journey:
        record.journey,
      checkpoint:
        checkpoint,
      isPersonalized:
        true,
      date:
        record.lastUpdatedAt
    )
  }

  private func fallbackFoundationJourneyItem(
    journey: JourneyPath,
    progressStore: JourneyProgressStore
  ) -> HomeContinueItem? {

    guard
      let checkpoint =
        progressStore
        .currentCheckpoint(
          in:
            journey
        )
    else {

      return nil
    }

    let completed =
      progressStore
      .completedCheckpointList(
        in:
          journey
      )

    let completionDates =
      completed
      .compactMap { checkpoint in

        progressStore
          .completedAt(
            checkpoint,
            in:
              journey
          )
      }

    guard
      let latestDate =
        completionDates.max()
    else {

      // Do not show a "continue" card for a path the user has never
      // actually begun. The normal Meet Jesus card already handles it.
      return nil
    }

    return checkpointItem(
      journey:
        journey,
      checkpoint:
        checkpoint,
      isPersonalized:
        false,
      date:
        latestDate
    )
  }

  private func checkpointItem(
    journey: JourneyPath,
    checkpoint: JourneyCheckpoint,
    isPersonalized: Bool,
    date: Date
  ) -> HomeContinueItem {

    HomeContinueItem(
      id:
        "checkpoint::\(journey.id)::\(checkpoint.id)",
      eyebrow:
        isPersonalized
        ? "YOUR PATH"
        : "MEET JESUS",
      title:
        checkpoint.title,
      subtitle:
        "\(journey.title) · \(checkpoint.passage)",
      icon:
        "map.fill",
      date:
        date,
      destination:
        .checkpoint(
          journey:
            journey,
          checkpoint:
            checkpoint,
          isPersonalized:
            isPersonalized
        )
    )
  }

  private func readingItem(
    book: String,
    chapter: Int,
    verses: [Int],
    reference: String,
    date: Date
  ) -> HomeContinueItem {

    HomeContinueItem(
      id:
        "reading::\(book)::\(chapter)::\(verses.map(String.init).joined(separator: ","))",
      eyebrow:
        "SCRIPTURE",
      title:
        reference,
      subtitle:
        "Return to the passage you were reading.",
      icon:
        "book.fill",
      date:
        date,
      destination:
        .reading(
          book:
            book,
          chapter:
            chapter,
          verses:
            verses
        )
    )
  }

  private func companionItem(
    key: String,
    passage: String,
    messages: [StoredCompanionMessage],
    date: Date
  ) -> HomeContinueItem {

    let lastUserMessage =
      messages
      .last(
        where: {
          $0.isUser
        }
      )?
      .text
      .trimmingCharacters(
        in:
          .whitespacesAndNewlines
      )
      ?? ""

    let detail =
      lastUserMessage.isEmpty
      ? "Continue your conversation with Companion."
      : limited(
        lastUserMessage,
        to:
          105
      )

    return HomeContinueItem(
      id:
        "companion::\(key)",
      eyebrow:
        "COMPANION",
      title:
        "Continue your conversation",
      subtitle:
        detail,
      icon:
        "bubble.left.and.bubble.right.fill",
      date:
        date,
      destination:
        .companion(
          conversationKey:
            key,
          passage:
            passage
        )
    )
  }

  private func parseReadingReference(
    _ reference: String
  ) -> (
    book: String,
    chapter: Int,
    verses: [Int]
  )? {

    let cleaned =
      reference
      .trimmingCharacters(
        in:
          .whitespacesAndNewlines
      )

    guard
      let regex =
        try? NSRegularExpression(
          pattern:
            #"^(.+?)\s+(\d+)(?::(.+))?$"#
        ),
      let match =
        regex.firstMatch(
          in:
            cleaned,
          range:
            NSRange(
              cleaned.startIndex...,
              in:
                cleaned
            )
        ),
      let bookRange =
        Range(
          match.range(
            at:
              1
          ),
          in:
            cleaned
        ),
      let chapterRange =
        Range(
          match.range(
            at:
              2
          ),
          in:
            cleaned
        ),
      let chapter =
        Int(
          cleaned[
            chapterRange
          ]
        )
    else {

      return nil
    }

    let book =
      String(
        cleaned[
          bookRange
        ]
      )

    var verses: [Int] = []

    let verseRange =
      match.range(
        at:
          3
      )

    if verseRange.location != NSNotFound,
      let swiftVerseRange =
        Range(
          verseRange,
          in:
            cleaned
        )
    {

      let spec =
        String(
          cleaned[
            swiftVerseRange
          ]
        )
        .replacingOccurrences(
          of:
            " ",
          with:
            ""
        )

      for component in spec.split(
        separator:
          ","
      ) {

        let parts =
          component.split(
            separator:
              "-"
          )

        if parts.count == 1,
          let verse =
            Int(
              parts[0]
            )
        {

          verses.append(
            verse
          )

        } else if parts.count == 2,
          let first =
            Int(
              parts[0]
            ),
          let last =
            Int(
              parts[1]
            ),
          first <= last
        {

          verses.append(
            contentsOf:
              first...last
          )
        }
      }
    }

    return (
      book:
        book,
      chapter:
        chapter,
      verses:
        Array(
          Set(
            verses
          )
        )
        .sorted()
    )
  }

  private func limited(
    _ value: String,
    to limit: Int
  ) -> String {

    guard value.count > limit else {
      return value
    }

    return
      String(
        value.prefix(
          limit
        )
      )
      + "…"
  }
}

// =========================================================
// MARK: - Continue Home Card
// =========================================================

struct HomeContinueCard:
  View
{

  let item: HomeContinueItem

  var body: some View {

    VStack(
      alignment:
        .leading,
      spacing:
        12
    ) {

      HStack {

        Text(
          "CONTINUE WHERE YOU LEFT OFF"
        )
        .font(
          .caption
        )
        .fontWeight(
          .bold
        )
        .tracking(
          0.6
        )
        .foregroundStyle(AppTheme.textSecondary)

        Spacer()

        Text(
          item.date,
          style:
            .relative
        )
        .font(
          .caption2
        )
        .foregroundStyle(AppTheme.heatherGray)
      }

      HStack(
        alignment:
          .center,
        spacing:
          14
      ) {

        ZStack {

          RoundedRectangle(
            cornerRadius:
              14,
            style:
              .continuous
          )
          .fill(
            AppTheme.accent
              .opacity(
                0.10
              )
          )
          .frame(
            width:
              54,
            height:
              54
          )

          Image(
            systemName:
              item.icon
          )
          .font(
            .title3
          )
          .foregroundStyle(
            AppTheme.accent
          )
        }

        VStack(
          alignment:
            .leading,
          spacing:
            4
        ) {

          Text(
            item.eyebrow
          )
          .font(
            .caption2
          )
          .fontWeight(
            .bold
          )
          .foregroundStyle(
            AppTheme.accent
          )

          Text(
            item.title
          )
          .font(
            .headline
          )
          .foregroundStyle(AppTheme.textPrimary)

          Text(
            item.subtitle
          )
          .font(
            .subheadline
          )
          .foregroundStyle(AppTheme.textSecondary)
          .lineLimit(
            2
          )
        }

        Spacer(
          minLength:
            6
        )

        Image(
          systemName:
            "chevron.right"
        )
        .font(
          .subheadline
        )
        .foregroundStyle(AppTheme.textSecondary)
      }
    }
    .padding(
      18
    )
    .frame(
      maxWidth:
        .infinity,
      alignment:
        .leading
    )
    .background(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(AppTheme.cardGradient)
        .shadow(color: AppTheme.shadow, radius: 12, y: 5)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .stroke(Color.white.opacity(0.74), lineWidth: 1)
    )
  }
}
