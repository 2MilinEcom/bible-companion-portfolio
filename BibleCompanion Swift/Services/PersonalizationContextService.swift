//
//  PersonalizationContextService.swift
//  BibleCompanion Swift
//
//  Created by Shopify on 10/2/26.
//

import Foundation

// =========================================================
// MARK: - Personalization Context Purpose
// =========================================================

enum PersonalizationContextPurpose:
  String,
  Codable
{

  case companion
  case checkpoint
  case journeyGeneration
  case perspectives
  case recommendation
  case journeyReview
  case dailyStudy

  var recentActivityLimit: Int {

    switch self {

    case .companion:
      return 10

    case .checkpoint:
      return 6

    case .journeyGeneration:
      return 10

    case .perspectives:
      return 5

    case .recommendation:
      return 10

    case .journeyReview:
      return 8

    case .dailyStudy:
      return 8
    }
  }

  var pastJourneyLimit: Int {

    switch self {

    case .companion:
      return 3

    case .checkpoint:
      return 2

    case .journeyGeneration:
      return 4

    case .perspectives:
      return 1

    case .recommendation:
      return 4

    case .journeyReview:
      return 2

    case .dailyStudy:
      return 2
    }
  }

  var recentConversationLimit: Int {

    switch self {

    case .companion:
      return 3

    case .checkpoint:
      return 2

    case .journeyGeneration:
      return 2

    case .perspectives:
      return 1

    case .recommendation:
      return 2

    case .journeyReview:
      return 2

    case .dailyStudy:
      return 1
    }
  }

  var recentConversationTurnLimit: Int {

    switch self {

    case .companion:
      return 6

    case .checkpoint:
      return 4

    case .journeyGeneration,
      .perspectives,
      .recommendation,
      .journeyReview,
      .dailyStudy:
      return 4
    }
  }

  var recentPassageReflectionLimit: Int {

    switch self {

    case .companion:
      return 4

    case .checkpoint:
      return 2

    case .journeyGeneration:
      return 4

    case .perspectives:
      return 1

    case .recommendation:
      return 3

    case .journeyReview:
      return 2

    case .dailyStudy:
      return 2
    }
  }
}

// =========================================================
// MARK: - Saved Profile Context
// =========================================================

/// Keeps user-provided profile information separate from
/// AI-derived interpretation.
///
/// This is important because the app should never treat
/// an AI-created label as though the user explicitly said it.
struct PersonalizationProfileContext:
  Codable
{

  // =====================================================
  // MARK: Explicit / User-Provided
  // =====================================================

  let name: String

  let spiritualPosition: String

  let bibleFamiliarity: String

  let primaryGoal: String

  let currentSeason: String

  let challengePreference: String

  let selectedStruggleCategory: String

  let customStruggleText: String

  let struggleTrigger: String

  let struggleGoal: String

  // =====================================================
  // MARK: Derived / AI-Assisted
  // =====================================================

  let analyzedStruggleCategory: String

  let struggleLabel: String

  let struggleSummary: String

  init(
    profile:
      SpiritualProfile
  ) {

    name =
      profile
      .preferredName

    spiritualPosition =
      profile
      .spiritualPosition

    bibleFamiliarity =
      profile
      .bibleFamiliarity

    primaryGoal =
      profile
      .primaryGoal

    currentSeason =
      profile
      .currentSeason

    challengePreference =
      profile
      .challengePreference

    selectedStruggleCategory =
      profile
      .struggleCategory

    customStruggleText =
      profile
      .customStruggleText

    struggleTrigger =
      profile
      .struggleTrigger

    struggleGoal =
      profile
      .struggleGoal

    analyzedStruggleCategory =
      profile
      .analyzedStruggleCategory

    struggleLabel =
      profile
      .struggleLabel

    struggleSummary =
      profile
      .struggleSummary
  }
}

// =========================================================
// MARK: - Active Journey Context
// =========================================================

struct PersonalizationActiveJourneyContext:
  Codable
{

  let journeyID: String

  let title: String

  let subtitle: String

  let category: String

  let focus: JourneyFocus?

  let completedCheckpointCount: Int

  let totalCheckpointCount: Int

  let currentCheckpoint: JourneyCheckpoint?

  let completedCheckpoints: [JourneyCheckpoint]

  // =====================================================
  // MARK: User-Provided Active Reflection Memory
  // =====================================================

  /// Reflections from the journey the user is actively working through.
  /// These are the user's own words and should be treated as such.
  let checkpointReflections: [PersonalizationCheckpointReflection]

  let finalReflection: String

  let remainingQuestions: String

  // =====================================================
  // MARK: AI-Generated Active Journey Memory
  // =====================================================

  /// Cached AI summary of the active journey, when one exists.
  /// This is interpretation, not something the user explicitly said.
  let aiSummary: PersonalizationAISummaryContext?

  // =====================================================
  // MARK: Reflection Recency
  // =====================================================

  let lastReflectionUpdatedAt: Date?
}

// =========================================================
// MARK: - Checkpoint Reflection Context
// =========================================================

struct PersonalizationCheckpointReflection:
  Codable
{

  let checkpointID: String

  let checkpointOrder: Int

  let checkpointTitle: String

  let passage: String

  /// This is the user's own saved writing.
  let reflection: String

  /// Helps the Companion distinguish a recent reflection from
  /// something the user wrote much earlier.
  let updatedAt: Date?
}

// =========================================================
// MARK: - AI Journey Summary Context
// =========================================================

/// This section is intentionally marked as AI-generated.
///
/// It can help future AI calls understand prior themes,
/// but must never be presented as something the user
/// explicitly said.
struct PersonalizationAISummaryContext:
  Codable
{

  let overview: String

  let themes: [String]

  let development: String

  let remainingQuestions: [String]

  let encouragement: String

  init(
    summary:
      JourneySummaryResponse
  ) {

    overview =
      summary
      .cleanedOverview

    themes =
      summary
      .cleanedThemes

    development =
      summary
      .cleanedDevelopment

    remainingQuestions =
      summary
      .cleanedRemainingQuestions

    encouragement =
      summary
      .cleanedEncouragement
  }
}

// =========================================================
// MARK: - Journey Memory
// =========================================================

struct PersonalizationJourneyMemory:
  Codable
{

  let journeyID: String

  let title: String

  let subtitle: String

  let category: String

  let focus: JourneyFocus?

  let status: String

  let completedCheckpointCount: Int

  let totalCheckpointCount: Int

  // =====================================================
  // MARK: User-Provided Reflection Memory
  // =====================================================

  let checkpointReflections: [PersonalizationCheckpointReflection]

  let finalReflection: String

  let remainingQuestions: String

  // =====================================================
  // MARK: AI-Generated Memory
  // =====================================================

  let aiSummary: PersonalizationAISummaryContext?

  // =====================================================
  // MARK: Lifecycle
  // =====================================================

  let startedAt: Date?

  let lastUpdatedAt: Date?

  let endedAt: Date?
}

// =========================================================
// MARK: - Recent Companion Conversation Memory
// =========================================================

/// A role-labeled excerpt from a previously saved Companion thread.
///
/// Keeping the role explicit prevents the model from treating something the
/// Companion previously said as though it were the user's own statement.
struct PersonalizationConversationTurn:
  Codable
{

  let role: String

  let text: String
}

struct PersonalizationConversationMemory:
  Codable
{

  let conversationKey: String

  let updatedAt: Date

  let recentTurns: [PersonalizationConversationTurn]
}

// =========================================================
// MARK: - Direct Passage Reflection Memory
// =========================================================

/// User-written reflections created while studying Scripture directly,
/// outside of a Journey checkpoint. These are explicit user-provided notes.
struct PersonalizationPassageReflection:
  Codable
{

  let reference: String

  let reflection: String

  let updatedAt: Date
}

// =========================================================
// MARK: - Personalization Context
// =========================================================

struct PersonalizationSavedBibleNote: Codable {
  let reference: String
  let text: String
  let updatedAt: Date
  let source: String
}

struct PersonalizationContext:
  Codable
{

  let purpose: PersonalizationContextPurpose

  // =====================================================
  // MARK: Saved Profile
  // =====================================================

  let profile: PersonalizationProfileContext

  // =====================================================
  // MARK: Current Context
  // =====================================================

  let activeJourney: PersonalizationActiveJourneyContext?

  let currentPassage: String

  let currentMessage: String

  // =====================================================
  // MARK: Observed Learning History
  // =====================================================

  /// These are actual recorded study activities.
  /// They are observations, not conclusions about the person.
  let recentActivity: [StudyActivity]

  // =====================================================
  // MARK: Recent Companion Conversation Memory
  // =====================================================

  /// Recent saved Companion threads, excluding the conversation currently
  /// being continued. Turns remain role-labeled and are intentionally
  /// limited to short excerpts.
  let recentConversations: [PersonalizationConversationMemory]

  // =====================================================
  // MARK: Direct Passage Reflection Memory
  // =====================================================

  /// These are the user's own words from direct Scripture study.
  /// They stay separate from AI-generated study-guide content.
  let recentPassageReflections: [PersonalizationPassageReflection]

  // =====================================================
  // MARK: Journey Memory
  // =====================================================

  /// User-written reflections remain separate from
  /// AI-generated journey summaries inside each memory.
  let journeyMemories: [PersonalizationJourneyMemory]

  // =====================================================
  // MARK: Metadata
  // =====================================================

  let generatedAt: Date

  /// User-written notes explicitly enabled for Companion memory.
  var savedBibleNotes: [PersonalizationSavedBibleNote]? = nil

  // =====================================================
  // MARK: Encoding Helpers
  // =====================================================

  func jsonData(
    prettyPrinted:
      Bool = false
  ) throws -> Data {

    let encoder =
      JSONEncoder()

    encoder.dateEncodingStrategy =
      .iso8601

    if prettyPrinted {

      encoder.outputFormatting = [
        .prettyPrinted,
        .sortedKeys,
      ]
    }

    return
      try encoder
      .encode(
        self
      )
  }

  func jsonString(
    prettyPrinted:
      Bool = false
  ) throws -> String {

    let data =
      try jsonData(
        prettyPrinted:
          prettyPrinted
      )

    guard
      let string =
        String(
          data:
            data,
          encoding:
            .utf8
        )
    else {

      throw PersonalizationContextError
        .encodingFailed
    }

    return string
  }
}

// =========================================================
// MARK: - Errors
// =========================================================

enum PersonalizationContextError:
  LocalizedError
{

  case encodingFailed

  var errorDescription: String? {

    switch self {

    case .encodingFailed:

      return
        "The personalization context could not be encoded."
    }
  }
}

// =========================================================
// MARK: - Personalization Context Service
// =========================================================

@MainActor
final class PersonalizationContextService {

  // =====================================================
  // MARK: Singleton
  // =====================================================

  static let shared =
    PersonalizationContextService()

  // =====================================================
  // MARK: Dependencies
  // =====================================================

  private let studyHistoryService: StudyHistoryService

  private let noteService: StudyNoteService

  private let progressStore: JourneyProgressStore

  private let journeyReflectionStore: JourneyReflectionStore

  private let journeySummaryStore: JourneySummaryStore

  private let conversationStore: CompanionConversationStore

  private let passageReflectionStore: PassageReflectionStore

  // =====================================================
  // MARK: Init
  // =====================================================

  init(
    studyHistoryService:
      StudyHistoryService? = nil,
    noteService:
      StudyNoteService? = nil,
    progressStore:
      JourneyProgressStore? = nil,
    journeyReflectionStore:
      JourneyReflectionStore? = nil,
    journeySummaryStore:
      JourneySummaryStore? = nil,
    conversationStore:
      CompanionConversationStore? = nil,
    passageReflectionStore:
      PassageReflectionStore? = nil
  ) {

    self.studyHistoryService =
      studyHistoryService ?? .shared

    self.noteService =
      noteService ?? .shared

    self.progressStore =
      progressStore ?? .shared

    self.journeyReflectionStore =
      journeyReflectionStore ?? .shared

    self.journeySummaryStore =
      journeySummaryStore ?? .shared

    self.conversationStore =
      conversationStore ?? .shared

    self.passageReflectionStore =
      passageReflectionStore ?? .shared
  }

  // =====================================================
  // MARK: - Build Current Context
  // =====================================================

  /// Central entry point for future AI features.
  ///
  /// The caller provides the user's current saved profile
  /// and current/past personalized journeys.
  ///
  /// This service then gathers:
  ///
  /// - recent study history
  /// - active journey progress
  /// - checkpoint reflections
  /// - final journey reflections
  /// - unresolved questions
  /// - cached AI journey summaries
  ///
  /// before producing one structured context object.
  func buildContext(
    profile:
      SpiritualProfile,
    activeJourney:
      JourneyPath?,
    pastJourneys:
      [PersonalizedJourneyRecord] = [],
    purpose:
      PersonalizationContextPurpose,
    currentPassage:
      String = "",
    currentMessage:
      String = "",
    currentConversationKey:
      String = ""
  ) -> PersonalizationContext {

    let allActivity =
      studyHistoryService
      .loadActivities()

    let recentActivity =
      Array(
        allActivity
          .prefix(
            purpose
              .recentActivityLimit
          )
      )

    let activeContext =
      activeJourney
      .map {

        buildActiveJourneyContext(
          journey:
            $0
        )
      }

    let memories =
      relevantJourneyMemories(
        from:
          pastJourneys,
        purpose:
          purpose,
        currentPassage:
          currentPassage,
        currentMessage:
          currentMessage
      )

    let recentConversations =
      buildRecentConversationMemories(
        purpose:
          purpose,
        excludingKey:
          cleaned(
            currentConversationKey
          )
      )

    let recentPassageReflections =
      buildRecentPassageReflections(
        purpose:
          purpose
      )

    return
      PersonalizationContext(

        purpose:
          purpose,

        profile:
          PersonalizationProfileContext(
            profile:
              profile
          ),

        activeJourney:
          activeContext,

        currentPassage:
          cleaned(
            currentPassage
          ),

        currentMessage:
          cleaned(
            currentMessage
          ),

        recentActivity:
          recentActivity,

        recentConversations:
          recentConversations,

        recentPassageReflections:
          recentPassageReflections,

        journeyMemories:
          memories,

        generatedAt: Date(),
        savedBibleNotes: BibleLibraryStore.shared.memoryNotes(limit: 4).map {
          PersonalizationSavedBibleNote(
            reference: $0.location.reference,
            text: String($0.text.prefix(1200)), updatedAt: $0.updatedAt,
            source: "user_written_note_opted_in")
        }
      )
  }

  // =====================================================
  // MARK: - Build Context With Explicit Activity
  // =====================================================

  /// Useful for tests or screens that already have
  /// their own recent-activity snapshot.
  func buildContext(
    profile:
      SpiritualProfile,
    activeJourney:
      JourneyPath?,
    pastJourneys:
      [PersonalizedJourneyRecord] = [],
    recentActivity:
      [StudyActivity],
    purpose:
      PersonalizationContextPurpose,
    currentPassage:
      String = "",
    currentMessage:
      String = "",
    currentConversationKey:
      String = ""
  ) -> PersonalizationContext {

    let limitedActivity =
      Array(
        recentActivity
          .prefix(
            purpose
              .recentActivityLimit
          )
      )

    let activeContext =
      activeJourney
      .map {

        buildActiveJourneyContext(
          journey:
            $0
        )
      }

    let memories =
      relevantJourneyMemories(
        from:
          pastJourneys,
        purpose:
          purpose,
        currentPassage:
          currentPassage,
        currentMessage:
          currentMessage
      )

    let recentConversations =
      buildRecentConversationMemories(
        purpose:
          purpose,
        excludingKey:
          cleaned(
            currentConversationKey
          )
      )

    let recentPassageReflections =
      buildRecentPassageReflections(
        purpose:
          purpose
      )

    return
      PersonalizationContext(

        purpose:
          purpose,

        profile:
          PersonalizationProfileContext(
            profile:
              profile
          ),

        activeJourney:
          activeContext,

        currentPassage:
          cleaned(
            currentPassage
          ),

        currentMessage:
          cleaned(
            currentMessage
          ),

        recentActivity:
          limitedActivity,

        recentConversations:
          recentConversations,

        recentPassageReflections:
          recentPassageReflections,

        journeyMemories:
          memories,

        generatedAt: Date(),
        savedBibleNotes: BibleLibraryStore.shared.memoryNotes(limit: 4).map {
          PersonalizationSavedBibleNote(
            reference: $0.location.reference,
            text: String($0.text.prefix(1200)), updatedAt: $0.updatedAt,
            source: "user_written_note_opted_in")
        }
      )
  }

  // =====================================================
  // MARK: - Recent Direct Passage Reflections
  // =====================================================

  private func buildRecentPassageReflections(
    purpose:
      PersonalizationContextPurpose
  ) -> [PersonalizationPassageReflection] {

    passageReflectionStore
      .recent(
        limit:
          purpose
          .recentPassageReflectionLimit
      )
      .compactMap { item in

        let text =
          cleaned(
            item.text
          )

        guard
          !text.isEmpty
        else {
          return nil
        }

        return
          PersonalizationPassageReflection(
            reference:
              item.reference,
            reflection:
              limited(
                text,
                to:
                  1_200
              ),
            updatedAt:
              item.updatedAt
          )
      }
  }

  // =====================================================
  // MARK: - Recent Companion Conversations
  // =====================================================

  private func buildRecentConversationMemories(
    purpose:
      PersonalizationContextPurpose,
    excludingKey:
      String
  ) -> [PersonalizationConversationMemory] {

    let excludedKey =
      excludingKey.isEmpty
      ? nil
      : excludingKey

    return
      conversationStore
      .recentConversations(
        limit:
          purpose
          .recentConversationLimit,
        excludingKey:
          excludedKey
      )
      .compactMap { snapshot in

        let turns =
          snapshot
          .messages
          .suffix(
            purpose
              .recentConversationTurnLimit
          )
          .compactMap {
            message
              -> PersonalizationConversationTurn?
            in

            let text =
              cleaned(
                message.text
              )

            guard !text.isEmpty else {
              return nil
            }

            return
              PersonalizationConversationTurn(
                role:
                  message.isUser
                  ? "user"
                  : "companion",
                text:
                  limited(
                    text,
                    to:
                      message.isUser
                      ? 900
                      : 700
                  )
              )
          }

        guard !turns.isEmpty else {
          return nil
        }

        return
          PersonalizationConversationMemory(
            conversationKey:
              snapshot.key,
            updatedAt:
              snapshot.updatedAt,
            recentTurns:
              turns
          )
      }
  }

  // =====================================================
  // MARK: - Active Journey
  // =====================================================

  private func buildActiveJourneyContext(
    journey:
      JourneyPath
  ) -> PersonalizationActiveJourneyContext {

    let completed =
      progressStore
      .completedCheckpointList(
        in:
          journey
      )
      .sorted {

        $0.order < $1.order
      }

    let completedIDs =
      Set(
        completed
          .map(
            \.id
          )
      )

    let currentCheckpoint =
      journey
      .checkpoints
      .sorted {

        $0.order < $1.order
      }
      .first {

        !completedIDs
          .contains(
            $0.id
          )
      }

    let checkpointReflections =
      buildCheckpointReflections(
        for:
          journey,
        limit:
          8
      )

    let finalReflectionRecord =
      journeyReflectionStore
      .reflection(
        for:
          journey
      )

    let finalReflection =
      limited(
        cleaned(
          finalReflectionRecord?
            .overallReflection
            ?? ""
        ),
        to:
          2_000
      )

    let remainingQuestions =
      limited(
        cleaned(
          finalReflectionRecord?
            .remainingQuestions
            ?? ""
        ),
        to:
          1_500
      )

    let aiSummary =
      journeySummaryStore
      .summary(
        for:
          journey
      )
      .map {

        PersonalizationAISummaryContext(
          summary:
            $0
        )
      }

    let lastCheckpointReflectionUpdate =
      checkpointReflections
      .compactMap(\.updatedAt)
      .max()

    let lastReflectionUpdatedAt =
      [
        lastCheckpointReflectionUpdate,
        finalReflectionRecord?
          .updatedAt,
      ]
      .compactMap { $0 }
      .max()

    return
      PersonalizationActiveJourneyContext(

        journeyID:
          journey.id,

        title:
          journey.title,

        subtitle:
          journey.subtitle,

        category:
          journey
          .category
          .rawValue,

        focus:
          journey.focus,

        completedCheckpointCount:
          completed.count,

        totalCheckpointCount:
          journey
          .checkpoints
          .count,

        currentCheckpoint:
          currentCheckpoint,

        completedCheckpoints:
          completed,

        checkpointReflections:
          checkpointReflections,

        finalReflection:
          finalReflection,

        remainingQuestions:
          remainingQuestions,

        aiSummary:
          aiSummary,

        lastReflectionUpdatedAt:
          lastReflectionUpdatedAt
      )
  }

  // =====================================================
  // MARK: - Checkpoint Reflection Memory
  // =====================================================

  private func buildCheckpointReflections(
    for journey:
      JourneyPath,
    limit:
      Int
  ) -> [PersonalizationCheckpointReflection] {

    let reflections =
      journey
      .checkpoints
      .sorted {

        $0.order < $1.order
      }
      .compactMap {
        checkpoint
          -> PersonalizationCheckpointReflection?
        in

        guard
          let note =
            noteService
            .reflection(
              for:
                checkpoint,
              in:
                journey
            )
        else {

          return nil
        }

        let text =
          cleaned(
            note.text
          )

        guard
          !text.isEmpty
        else {

          return nil
        }

        return
          PersonalizationCheckpointReflection(

            checkpointID:
              checkpoint.id,

            checkpointOrder:
              checkpoint.order,

            checkpointTitle:
              checkpoint.title,

            passage:
              checkpoint.passage,

            reflection:
              limited(
                text,
                to:
                  1_200
              ),

            updatedAt:
              note.updatedAt
          )
      }

    guard
      limit > 0,
      reflections.count > limit
    else {

      return reflections
    }

    return
      Array(
        reflections
          .suffix(
            limit
          )
      )
  }

  // =====================================================
  // MARK: - Relevant Past Journeys
  // =====================================================

  private func relevantJourneyMemories(
    from records:
      [PersonalizedJourneyRecord],
    purpose:
      PersonalizationContextPurpose,
    currentPassage:
      String,
    currentMessage:
      String
  ) -> [PersonalizationJourneyMemory] {

    guard
      !records.isEmpty
    else {

      return []
    }

    let query =
      [
        currentPassage,
        currentMessage,
      ]
      .joined(
        separator:
          " "
      )

    let ranked =
      records
      .map {
        record in

        (
          record:
            record,

          relevance:
            relevanceScore(
              for:
                record,
              query:
                query
            )
        )
      }
      .sorted {
        left,
        right in

        if left.relevance
          != right.relevance
        {

          return
            left.relevance
            > right.relevance
        }

        return
          left
          .record
          .lastUpdatedAt
          > right
          .record
          .lastUpdatedAt
      }

    return
      Array(
        ranked
          .prefix(
            purpose
              .pastJourneyLimit
          )
      )
      .map {

        buildJourneyMemory(
          record:
            $0.record
        )
      }
  }

  // =====================================================
  // MARK: - Journey Memory
  // =====================================================

  private func buildJourneyMemory(
    record:
      PersonalizedJourneyRecord
  ) -> PersonalizationJourneyMemory {

    let journey =
      record
      .journey

    let completed =
      progressStore
      .completedCheckpointList(
        in:
          journey
      )

    let checkpointReflections =
      buildCheckpointReflections(
        for:
          journey,
        limit:
          6
      )

    let finalReflectionRecord =
      journeyReflectionStore
      .reflection(
        for:
          journey
      )

    let finalReflection =
      limited(
        cleaned(
          finalReflectionRecord?
            .overallReflection
            ?? ""
        ),
        to:
          2_000
      )

    let remainingQuestions =
      limited(
        cleaned(
          finalReflectionRecord?
            .remainingQuestions
            ?? ""
        ),
        to:
          1_500
      )

    let aiSummary =
      journeySummaryStore
      .summary(
        for:
          journey
      )
      .map {

        PersonalizationAISummaryContext(
          summary:
            $0
        )
      }

    return
      PersonalizationJourneyMemory(

        journeyID:
          journey.id,

        title:
          journey.title,

        subtitle:
          journey.subtitle,

        category:
          journey
          .category
          .rawValue,

        focus:
          journey.focus,

        status:
          record
          .status
          .rawValue,

        completedCheckpointCount:
          completed.count,

        totalCheckpointCount:
          journey
          .checkpoints
          .count,

        checkpointReflections:
          checkpointReflections,

        finalReflection:
          finalReflection,

        remainingQuestions:
          remainingQuestions,

        aiSummary:
          aiSummary,

        startedAt:
          record.startedAt,

        lastUpdatedAt:
          record.lastUpdatedAt,

        endedAt:
          record.endedAt
      )
  }

  // =====================================================
  // MARK: - Relevance
  // =====================================================

  /// Lightweight local relevance ranking.
  ///
  /// This does NOT decide what the user believes or struggles with.
  /// It only checks whether words in the current request overlap
  /// with words in a past journey's title/focus/summary.
  private func relevanceScore(
    for record:
      PersonalizedJourneyRecord,
    query:
      String
  ) -> Int {

    let queryTokens =
      tokens(
        from:
          query
      )

    guard
      !queryTokens.isEmpty
    else {

      return 0
    }

    let journey =
      record
      .journey

    var searchableParts: [String] = [

      journey.title,
      journey.subtitle,
      journey
        .focus?
        .category
        ?? "",
      journey
        .focus?
        .label
        ?? "",
      journey
        .focus?
        .originalText
        ?? "",
      journey
        .focus?
        .trigger
        ?? "",
      journey
        .focus?
        .goal
        ?? "",
    ]

    if let summary =
      journeySummaryStore
      .summary(
        for:
          journey
      )
    {

      searchableParts.append(
        summary
          .cleanedOverview
      )

      searchableParts.append(
        contentsOf:
          summary
          .cleanedThemes
      )

      searchableParts.append(
        summary
          .cleanedDevelopment
      )

      searchableParts.append(
        contentsOf:
          summary
          .cleanedRemainingQuestions
      )
    }

    let searchableTokens =
      tokens(
        from:
          searchableParts
          .joined(
            separator:
              " "
          )
      )

    return
      queryTokens
      .intersection(
        searchableTokens
      )
      .count
  }

  // =====================================================
  // MARK: - Helpers
  // =====================================================

  private func cleaned(
    _ value:
      String
  ) -> String {

    value
      .trimmingCharacters(
        in:
          .whitespacesAndNewlines
      )
  }

  private func limited(
    _ value:
      String,
    to limit:
      Int
  ) -> String {

    guard
      value.count > limit
    else {

      return value
    }

    return
      String(
        value
          .prefix(
            limit
          )
      )
      + "…"
  }

  private func tokens(
    from value:
      String
  ) -> Set<String> {

    let stopWords: Set<String> = [

      "a",
      "an",
      "and",
      "are",
      "as",
      "at",
      "be",
      "but",
      "by",
      "for",
      "from",
      "how",
      "i",
      "in",
      "is",
      "it",
      "me",
      "my",
      "of",
      "on",
      "or",
      "that",
      "the",
      "this",
      "to",
      "was",
      "what",
      "when",
      "with",
      "you",
      "your",
    ]

    let pieces =
      value
      .lowercased()
      .components(
        separatedBy:
          CharacterSet
          .alphanumerics
          .inverted
      )
      .filter {

        $0.count >= 3
          && !stopWords
            .contains(
              $0
            )
      }

    return
      Set(
        pieces
      )
  }
}
 
