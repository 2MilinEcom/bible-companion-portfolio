import Combine
import Foundation

@MainActor
final class CompanionViewModel: ObservableObject {

  // =====================================================
  // MARK: - Published State
  // =====================================================

  @Published
  var messages: [Message] = []

  var inputText = ""

  @Published
  var isLoading = false

  @Published private(set) var errorMessage: String?
  private var failedQuestion: String?

  // =====================================================
  // MARK: - Conversation State
  // =====================================================

  private var previousResponseID: String?

  private var activeConversationKey: String?

  private var loadedConversationKey: String?

  private var hasStartedGuidedSession = false

  // =====================================================
  // MARK: - Dependencies
  // =====================================================

  private let conversationStore =
    CompanionConversationStore.shared

  private let personalizationContextService =
    PersonalizationContextService.shared

  /// HomeViewModel already knows how to load the app's
  /// active and past personalized journeys.
  ///
  /// We use it here only as a journey-state reader so the
  /// Companion can receive the same journey context that
  /// the Home screen already uses.
  private let journeyStateViewModel =
    HomeViewModel()

  // =====================================================
  // MARK: - Configure Conversation
  // =====================================================

  func configureConversation(
    key: String?
  ) {

    if loadedConversationKey == key {
      return
    }

    loadedConversationKey = key
    activeConversationKey = key

    errorMessage = nil
    failedQuestion = nil
    messages.removeAll()
    inputText = ""
    previousResponseID = nil
    hasStartedGuidedSession = false

    guard let key else {
      return
    }

    guard
      let stored =
        conversationStore
        .conversation(
          for: key
        )
    else {
      return
    }

    messages =
      stored.messages.map {

        Message(
          text: $0.text,
          isUser: $0.isUser
        )
      }

    previousResponseID =
      stored.previousResponseID

    hasStartedGuidedSession =
      !messages.isEmpty
  }

  // =====================================================
  // MARK: - Normal User Message
  // =====================================================

  func sendMessage(
    passage: String = "",
    mode: StudyMode = .explain,
    lens: CompanionLens,
    profile: SpiritualProfile,
    retrying: Bool = false
  ) async {

    let question =
      inputText
      .trimmingCharacters(
        in: .whitespacesAndNewlines
      )

    guard !question.isEmpty else {
      return
    }

    guard !isLoading else {
      return
    }

    inputText = ""
    errorMessage = nil

    // -------------------------------------------------
    // Visible User Message
    // -------------------------------------------------
    //
    // The customer sees only what they actually typed.
    // Personalization context remains hidden.

    if !retrying {
    messages.append(
      Message(
        text: question,
        isUser: true
      )
    )

    }

    persistConversation()

    isLoading = true

    defer {
      isLoading = false
    }

    do {

      // -------------------------------------------------
      // Build structured personalization context
      // -------------------------------------------------

      let personalizationContext =
        buildPersonalizationContext(
          visibleUserMessage: question,
          passage: passage,
          profile: profile,
          purpose: .companion
        )

      // -------------------------------------------------
      // Build only the Companion/session instruction
      // -------------------------------------------------
      //
      // Journey history, reflections, study history, and
      // AI summaries are no longer embedded into this text.
      // They travel separately through
      // `personalization_context`.

      let apiQuestion =
        buildCompanionPrompt(
          visibleUserMessage: question,
          lens: lens,
          sessionInstruction:
            """
            Continue the existing conversation naturally.
            """
        )

      let response =
        try await AIService
        .shared
        .ask(
          question: apiQuestion,
          passage: passage,
          mode: mode,
          previousResponseID:
            previousResponseID,
          profile: profile,
          personalizationContext:
            personalizationContext
        )

      previousResponseID =
        response.responseID

      messages.append(
        Message(
          text: response.answer,
          isUser: false
        )
      )

      persistConversation()

      failedQuestion = nil
    } catch is CancellationError {
      failedQuestion = question
    } catch {
      failedQuestion = question
      errorMessage = error.localizedDescription
    }
  }

  func retryMessage(passage: String, mode: StudyMode, lens: CompanionLens,
                    profile: SpiritualProfile) async {
    guard let failedQuestion, !isLoading else { return }
    inputText = failedQuestion
    await sendMessage(passage: passage, mode: mode, lens: lens,
                      profile: profile, retrying: true)
  }

  // =====================================================
  // MARK: - Guided Session Start
  // =====================================================

  func startGuidedSession(
    prompt: String,
    passage: String,
    mode: StudyMode,
    lens: CompanionLens,
    profile: SpiritualProfile
  ) async {

    guard !hasStartedGuidedSession else {
      return
    }

    guard messages.isEmpty else {

      hasStartedGuidedSession = true
      return
    }

    guard !isLoading else {
      return
    }

    let cleanedPrompt =
      prompt
      .trimmingCharacters(
        in: .whitespacesAndNewlines
      )

    guard !cleanedPrompt.isEmpty else {
      return
    }

    hasStartedGuidedSession = true
    isLoading = true

    defer {
      isLoading = false
    }

    do {

      // -------------------------------------------------
      // Build checkpoint-specific structured context
      // -------------------------------------------------

      let personalizationContext =
        buildPersonalizationContext(
          visibleUserMessage:
            cleanedPrompt,
          passage:
            passage,
          profile:
            profile,
          purpose:
            .checkpoint
        )

      // -------------------------------------------------
      // Keep only session instructions in the prompt
      // -------------------------------------------------

      let guidedPrompt =
        buildCompanionPrompt(
          visibleUserMessage:
            cleanedPrompt,
          lens:
            lens,
          sessionInstruction:
            """
            You are beginning a guided Journey discussion.

            Use relevant Journey and reflection context only
            when it genuinely helps teach this checkpoint.

            Do not summarize the user's entire history.
            Keep the discussion centered on the current
            passage and checkpoint.
            """
        )

      let response =
        try await AIService
        .shared
        .ask(
          question:
            guidedPrompt,
          passage:
            passage,
          mode:
            mode,
          previousResponseID:
            previousResponseID,
          profile:
            profile,
          personalizationContext:
            personalizationContext
        )

      previousResponseID =
        response.responseID

      // Hidden instructions and personalization data
      // never appear in the visible conversation.

      messages.append(
        Message(
          text: response.answer,
          isUser: false
        )
      )

      persistConversation()

    } catch {

      hasStartedGuidedSession = false

      messages.append(
        Message(
          text:
            "I couldn't begin this discussion right now. \(error.localizedDescription)",
          isUser: false
        )
      )

      persistConversation()
    }
  }

  // =====================================================
  // MARK: - Personalization
  // =====================================================

  /// Builds the structured personalization context sent with
  /// an AI request.
  ///
  /// Important distinctions:
  ///
  /// - Explicit profile fields are things the user supplied.
  /// - Study history is observed behavior.
  /// - Reflections are the user's own writing.
  /// - Journey summaries are AI-generated interpretation.
  ///
  /// The backend receives these as structured application
  /// context instead of having them embedded in the user's
  /// question.
  private func buildPersonalizationContext(
    visibleUserMessage: String,
    passage: String,
    profile: SpiritualProfile,
    purpose: PersonalizationContextPurpose
  ) -> PersonalizationContext {

    // -------------------------------------------------
    // Refresh Journey State
    // -------------------------------------------------

    journeyStateViewModel
      .loadPersonalizedJourneyState()

    journeyStateViewModel
      .refreshPastJourneys()

    // -------------------------------------------------
    // Build Relevant Context
    // -------------------------------------------------

    return
      personalizationContextService
      .buildContext(
        profile:
          profile,
        activeJourney:
          journeyStateViewModel
          .activePersonalizedJourney,
        pastJourneys:
          journeyStateViewModel
          .pastPersonalizedJourneys,
        purpose:
          purpose,
        currentPassage:
          passage,
        currentMessage:
          visibleUserMessage,
        currentConversationKey:
          activeConversationKey
          ?? ""
      )
  }

  // =====================================================
  // MARK: - Companion Prompt
  // =====================================================

  /// Builds the hidden Companion/session instruction while
  /// leaving personalization data in its dedicated request
  /// field.
  ///
  /// The current user message is included here because the
  /// backend's `/ask` endpoint still receives Companion lens
  /// instructions through the `question` field.
  private func buildCompanionPrompt(
    visibleUserMessage: String,
    lens: CompanionLens,
    sessionInstruction: String
  ) -> String {

    """
    \(lens.instruction)

    \(sessionInstruction)

    \(AppSettingsStore.shared.companionInstructions)

    CURRENT USER MESSAGE:

    \(visibleUserMessage)
    """
  }

  // =====================================================
  // MARK: - Reset
  // =====================================================

  func resetConversation() {

    messages.removeAll()
    inputText = ""
    previousResponseID = nil
    hasStartedGuidedSession = false

    if let activeConversationKey {

      conversationStore
        .deleteConversation(
          for: activeConversationKey
        )
    }
  }

  // =====================================================
  // MARK: - Persistence
  // =====================================================

  private func persistConversation() {

    guard let activeConversationKey else {

      // A conversation without a key is intentionally
      // not persisted.

      return
    }

    conversationStore
      .saveConversation(
        messages: messages,
        previousResponseID:
          previousResponseID,
        for:
          activeConversationKey
      )
  }
}
