import Foundation

// =========================================================
// MARK: - Daily Study Service
// =========================================================

@MainActor
final class DailyStudyService {

  static let shared = DailyStudyService()

  private let aiService: AIService
  private let personalizationContextService: PersonalizationContextService
  private let storageService: StorageService

  init(
    aiService: AIService? = nil,
    personalizationContextService: PersonalizationContextService? = nil,
    storageService: StorageService? = nil
  ) {
    self.aiService = aiService ?? .shared
    self.personalizationContextService = personalizationContextService ?? .shared
    self.storageService = storageService ?? .shared
  }

  func generate(
    plan: DailyStudyPlan,
    passage: String,
    profile: SpiritualProfile
  ) async throws -> DailyStudyContent {

    let activeJourney = storageService.loadActivePersonalizedPath()
    let pastJourneys = storageService.loadPastPersonalizedJourneys()

    let context = personalizationContextService.buildContext(
      profile: profile,
      activeJourney: activeJourney,
      pastJourneys: pastJourneys,
      purpose: .dailyStudy,
      currentPassage: plan.reference,
      currentMessage: "Prepare today's Daily Study."
    )

    let question = """
    Create a compact Daily Study for the supplied Bible passage.

    This is a brief daily devotional-study moment, not a sermon and not a full theological essay.
    Use the supplied passage as the primary biblical evidence. Do not invent details that are not in the text.
    If the personalization context is relevant, connect gently without exposing private stored details or labeling the user.
    Do not claim that God specifically chose this passage, told you something about the user, or is speaking through the app.
    Do not quote Scripture unless the exact words appear in the supplied passage; paraphrase when possible.

    The locally selected reason for today's passage is:
    \(plan.reason)

    Return EXACTLY these labels, in this order, with no markdown headings and no introductory or closing text:

    BIG_IDEA: one or two short sentences
    NOTICE_1: one concrete thing to notice in the passage
    NOTICE_2: a second concrete thing to notice in the passage
    REFLECT: one thoughtful question
    PRACTICE: one realistic action for today
    PRAYER: one short invitation for the user to pray; do not write as though you are God

    Keep the entire response concise and easy to scan.
    """

    let response = try await aiService.ask(
      question: question,
      passage: passage,
      mode: .explain,
      previousResponseID: nil,
      profile: profile,
      personalizationContext: context
    )

    return DailyStudyResponseParser.bestEffort(
      response.answer,
      generatedAt: Date()
    )
  }
}
