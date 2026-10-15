import SwiftUI

struct JourneyCheckpointView: View {

  let journey: JourneyPath
  let checkpoint: JourneyCheckpoint
  let onComplete: () -> Void

  @Environment(\.dismiss)
  private var dismiss

  @StateObject
  private var bibleViewModel =
    BibleViewModel()

  @StateObject
  private var noteService =
    StudyNoteService.shared

  @StateObject
  private var sessionStore =
    JourneySessionStore.shared

  private var preferredName: String {

    StorageService.shared
      .loadSpiritualProfile()?
      .preferredName
      ?? ""
  }

  @State
  private var reflection = ""

  @State
  private var hasLoadedReflection = false

  @State
  private var isCompleting = false

  // MARK: - Session

  private var stage: JourneySessionStage {

    sessionStore.stage(
      journey: journey,
      checkpoint: checkpoint
    )
  }

  // MARK: - Passage Parsing

  private var parsedPassage: BiblePassageReference? {

    BibleService.shared
      .parsePassageRange(
        checkpoint.passage
      )
  }

  // MARK: - Conversation Key

  private var discussionConversationKey: String {

    "\(journey.id)::\(checkpoint.id)::discussion"
  }

  // MARK: - Full Passage Text

  private var passageText: String {

    guard let parsedPassage else {
      return checkpoint.passage
    }

    let verses =
      bibleViewModel.chapter(
        book:
          parsedPassage.book,
        chapter:
          parsedPassage.chapter
      )
      .filter {

        parsedPassage
          .verses
          .contains(
            $0.verse
          )
      }

    guard !verses.isEmpty else {
      return checkpoint.passage
    }

    let text =
      verses
      .map {
        "\($0.verse) \($0.text)"
      }
      .joined(
        separator: "\n"
      )

    return """
      \(checkpoint.passage)

      \(text)
      """
  }

  // MARK: - Progress

  private var checkpointNumber: Int {

    checkpoint.order
  }

  private var totalCheckpoints: Int {

    journey.checkpoints.count
  }

  // MARK: - Body

  var body: some View {

    ScrollView {

      VStack(
        alignment: .leading,
        spacing: 26
      ) {

        journeyHeader

        sessionProgress

        Divider()

        switch stage {

        case .introduction:

          introductionStage

        case .reading:

          readingStage

        case .discussion:

          discussionStage

        case .reflection:

          reflectionStage

        case .completed:

          completedStage
        }

        Spacer(
          minLength: 40
        )
      }
      .padding()
    }
    .cloudScreen()
    .navigationTitle(
      "Checkpoint \(checkpointNumber)"
    )
    .navigationBarTitleDisplayMode(
      .inline
    )
    .onAppear {

      ResumeActivityStore.shared
        .recordCheckpoint(
          journey:
            journey,
          checkpoint:
            checkpoint
        )

      loadReflection()
    }
    .onChange(
      of: reflection
    ) { _, newValue in

      guard hasLoadedReflection else {
        return
      }

      noteService.saveReflection(
        journey: journey,
        checkpoint: checkpoint,
        text: newValue
      )
    }
  }

  // MARK: - Header

  private var journeyHeader: some View {

    VStack(alignment: .leading, spacing: 12) {
      JourneyCloudHero(
        title: checkpoint.title,
        subtitle: checkpoint.passage,
        progress: Double(max(0, checkpointNumber - 1)) / Double(max(1, totalCheckpoints)),
        companion: true
      )

      HStack(spacing: 8) {
        Image(systemName: "map.fill")
          .foregroundStyle(AppTheme.accent)

        Text("\(journey.title.uppercased()) · CHECKPOINT \(checkpointNumber) OF \(totalCheckpoints)")
          .font(.caption.weight(.bold))
          .tracking(0.5)
          .foregroundStyle(AppTheme.textSecondary)
      }
    }
  }

  // MARK: - Session Progress

  private var sessionProgress: some View {

    VStack(
      alignment: .leading,
      spacing: 10
    ) {

      HStack(
        spacing: 6
      ) {

        sessionStep(
          title: "Intro",
          step:
            .introduction
        )

        sessionLine(
          after:
            .introduction
        )

        sessionStep(
          title: "Read",
          step:
            .reading
        )

        sessionLine(
          after:
            .reading
        )

        sessionStep(
          title: "Discuss",
          step:
            .discussion
        )

        sessionLine(
          after:
            .discussion
        )

        sessionStep(
          title: "Reflect",
          step:
            .reflection
        )
      }
    }
  }

  private func sessionStep(
    title: String,
    step: JourneySessionStage
  ) -> some View {

    let reached =
      stage.order >= step.order

    let current =
      stage == step

    return VStack(
      spacing: 5
    ) {

      ZStack {

        Circle()
          .fill(
            reached
              ? AppTheme.accent
              : AppTheme.surface
          )
          .frame(
            width: 26,
            height: 26
          )

        if stage.order > step.order {

          Image(
            systemName:
              "checkmark"
          )
          .font(
            .caption2
          )
          .fontWeight(
            .bold
          )
          .foregroundStyle(
            .white
          )

        } else {

          Circle()
            .fill(
              current
                ? Color.white
                : AppTheme.textSecondary
                  .opacity(0.5)
            )
            .frame(
              width: 7,
              height: 7
            )
        }
      }

      Text(title)
        .font(
          .caption2
        )
        .fontWeight(
          current
            ? .bold
            : .regular
        )
        .foregroundStyle(
          reached
            ? AppTheme.textPrimary
            : AppTheme.textSecondary
        )
    }
  }

  private func sessionLine(
    after step:
      JourneySessionStage
  ) -> some View {

    Rectangle()
      .fill(
        stage.order > step.order
          ? AppTheme.accent
          : AppTheme.textSecondary
            .opacity(0.20)
      )
      .frame(
        height: 2
      )
      .frame(
        maxWidth: .infinity
      )
      .padding(
        .bottom,
        20
      )
  }

  // MARK: - Introduction

  private var introductionStage: some View {

    VStack(
      alignment: .leading,
      spacing: 24
    ) {

      companionMessage(
        """
        \(preferredName.isEmpty ? checkpoint.subtitle : "\(preferredName), \(checkpoint.subtitle)")

        Before we begin, don't worry about understanding everything at once. Today we're going to focus on one question:

        \(checkpoint.focusQuestion)
        """
      )

      focusCard

      Button {

        sessionStore.setStage(
          .reading,
          journey: journey,
          checkpoint: checkpoint
        )

      } label: {

        primaryActionLabel(
          title:
            "Begin Reading",
          icon:
            "book.fill"
        )
      }
      .buttonStyle(
        .borderedProminent
      )
    }
  }

  // MARK: - Reading

  private var readingStage: some View {

    VStack(
      alignment: .leading,
      spacing: 22
    ) {

      companionMessage(
        """
        Now read \(checkpoint.passage).

        Keep today's focus question in mind, but first notice what the passage itself emphasizes.
        """
      )

      focusCard

      readPassageButton

      Button {

        sessionStore.setStage(
          .discussion,
          journey: journey,
          checkpoint: checkpoint
        )

      } label: {

        primaryActionLabel(
          title:
            "I've Read It",
          icon:
            "checkmark.circle.fill"
        )
      }
      .buttonStyle(
        .borderedProminent
      )
    }
  }

  // MARK: - Discussion

  private var discussionStage: some View {

    VStack(
      alignment: .leading,
      spacing: 22
    ) {

      companionMessage(
        """
        Before looking at an explanation, think about what you noticed.

        \(checkpoint.focusQuestion)
        """
      )

      VStack(
        alignment: .leading,
        spacing: 8
      ) {

        Text(
          "Talk It Through"
        )
        .font(.title2)
        .bold()

        Text(
          "Use the Companion to discuss your observations or questions."
        )
        .font(.subheadline)
        .foregroundStyle(AppTheme.textSecondary)
      }

      // MARK: Discuss with Companion

      NavigationLink {

        CompanionView(
          passage:
            passageText,
          mode:
            .explain,
          autoStartPrompt:
            """
            You are guiding the user through a Bible study checkpoint.

            Journey:
            \(journey.title)

            Current checkpoint:
            \(checkpoint.title)

            Passage:
            \(checkpoint.passage)

            Focus question:
            \(checkpoint.focusQuestion)

            Begin the discussion yourself.

            Do NOT give a full explanation yet.

            Start by asking the user one clear, thoughtful question about what they noticed in the passage.

            Base the question directly on the passage and the checkpoint focus.

            After they answer, use their response to guide the discussion deeper into the text.

            Teach Socratically:
            - ask one focused question at a time
            - respond specifically to what the user says
            - acknowledge good observations
            - gently correct misunderstandings when necessary
            - point them back to specific verses
            - avoid overwhelming them with a lecture
            - gradually help them reach the main idea themselves

            Your first response should be brief and should end with one question for the user.
            """,
          conversationKey:
            discussionConversationKey
        )

      } label: {

        JourneyToolRow(
          title:
            "Discuss with Companion",
          subtitle:
            "Talk through what you noticed.",
          icon:
            "bubble.left.and.bubble.right.fill"
        )
      }
      .buttonStyle(.plain)

      // MARK: Optional Tools

      Text(
        "Optional study tools"
      )
      .font(.caption)
      .fontWeight(.bold)
      .foregroundStyle(AppTheme.textSecondary)

      // MARK: Explain

      NavigationLink {

        CompanionView(
          passage:
            passageText,
          mode:
            .explain,
          initialPrompt:
            """
            Explain \(checkpoint.passage) clearly in context.

            The checkpoint focus question is:

            \(checkpoint.focusQuestion)
            """
        )

      } label: {

        JourneyToolRow(
          title:
            "Explain",
          subtitle:
            "Walk through the passage.",
          icon:
            "sparkles"
        )
      }
      .buttonStyle(.plain)

      // MARK: Perspectives

      NavigationLink {

        PerspectivesView(
          passage:
            passageText
        )

      } label: {

        JourneyToolRow(
          title:
            "Perspectives",
          subtitle:
            "Compare major interpretations.",
          icon:
            "person.3.fill"
        )
      }
      .buttonStyle(.plain)

      // MARK: Challenge

      NavigationLink {

        CompanionView(
          passage:
            passageText,
          mode:
            .challenge,
          initialPrompt:
            """
            I'm studying \(checkpoint.passage).

            Focus question:

            \(checkpoint.focusQuestion)

            Challenge my reasoning carefully. Ask questions, identify assumptions, and use the biblical text to test my interpretation.
            """
        )

      } label: {

        JourneyToolRow(
          title:
            "Challenge My Thinking",
          subtitle:
            "Test your interpretation.",
          icon:
            "brain.head.profile"
        )
      }
      .buttonStyle(.plain)

      // MARK: Continue

      Button {

        sessionStore.setStage(
          .reflection,
          journey: journey,
          checkpoint: checkpoint
        )

      } label: {

        primaryActionLabel(
          title:
            "Continue to Reflection",
          icon:
            "arrow.right"
        )
      }
      .buttonStyle(
        .borderedProminent
      )
    }
  }

  // MARK: - Reflection

  private var reflectionStage: some View {

    VStack(
      alignment: .leading,
      spacing: 22
    ) {

      companionMessage(
        """
        \(preferredName.isEmpty ? "Take a moment to put what you learned into your own words." : "Take a moment, \(preferredName), to put what you learned into your own words.")

        Your reflection will be saved so you can return to it later.
        """
      )

      reflectionSection

      Button {

        completeCheckpoint()

      } label: {

        primaryActionLabel(
          title:
            "Complete Checkpoint",
          icon:
            "checkmark.circle.fill"
        )
      }
      .buttonStyle(
        .borderedProminent
      )
      .disabled(
        isCompleting
      )
    }
  }

  // MARK: - Completed

  private var completedStage: some View {

    VStack(
      alignment: .center,
      spacing: 20
    ) {

      Image(
        systemName:
          "checkmark.seal.fill"
      )
      .font(
        .system(
          size: 54
        )
      )
      .foregroundStyle(
        AppTheme.accent
      )

      Text(
        "Checkpoint Complete"
      )
      .font(.title2)
      .bold()

      Text(
        preferredName.isEmpty
          ? "You've completed \(checkpoint.title). Your reflection has been saved."
          : "\(preferredName), you've completed \(checkpoint.title). Your reflection has been saved."
      )
      .multilineTextAlignment(
        .center
      )
      .foregroundStyle(AppTheme.textSecondary)

      if !reflection
        .trimmingCharacters(
          in:
            .whitespacesAndNewlines
        )
        .isEmpty
      {

        VStack(
          alignment: .leading,
          spacing: 8
        ) {

          Text(
            "YOUR REFLECTION"
          )
          .font(.caption)
          .fontWeight(.bold)
          .foregroundStyle(AppTheme.textSecondary)

          Text(
            reflection
          )
        }
        .padding(18)
        .frame(
          maxWidth:
            .infinity,
          alignment:
            .leading
        )
        .background(
          RoundedRectangle(
            cornerRadius: 18
          )
          .fill(
            AppTheme.surface
          )
        )
      }

      Button {

        sessionStore.setStage(
          .introduction,
          journey: journey,
          checkpoint: checkpoint
        )

      } label: {

        Text(
          "Review This Checkpoint Again"
        )
        .frame(
          maxWidth:
            .infinity
        )
      }
      .buttonStyle(
        .bordered
      )
    }
    .frame(
      maxWidth: .infinity
    )
    .padding(
      .vertical,
      20
    )
  }

  // MARK: - Companion Message

  private func companionMessage(
    _ text: String
  ) -> some View {

    VStack(
      alignment: .leading,
      spacing: 16
    ) {

      HStack(
        spacing: 12
      ) {

        ZStack {

          Circle()
            .fill(
              AppTheme.accent
                .opacity(0.12)
            )
            .frame(
              width: 48,
              height: 48
            )

          Image(
            systemName:
              "sparkles"
          )
          .font(.title3)
          .foregroundStyle(
            AppTheme.accent
          )
        }

        VStack(
          alignment: .leading,
          spacing: 2
        ) {

          Text(
            "Companion"
          )
          .font(.headline)

          Text(
            "Guide · Foundation Journey"
          )
          .font(.caption)
          .foregroundStyle(AppTheme.textSecondary)
        }
      }

      Text(text)
        .lineSpacing(4)
    }
    .padding(18)
    .frame(
      maxWidth: .infinity,
      alignment: .leading
    )
    .background(
      RoundedRectangle(
        cornerRadius: 20
      )
      .fill(
        AppTheme.surface
      )
    )
  }

  // MARK: - Focus

  private var focusCard: some View {

    VStack(
      alignment: .leading,
      spacing: 10
    ) {

      Text(
        "TODAY'S FOCUS"
      )
      .font(.caption)
      .fontWeight(.bold)
      .foregroundStyle(AppTheme.textSecondary)

      Text(
        checkpoint.focusQuestion
      )
      .font(.title3)
      .fontWeight(
        .semibold
      )
    }
    .padding(18)
    .frame(
      maxWidth: .infinity,
      alignment: .leading
    )
    .background(
      RoundedRectangle(
        cornerRadius: 18
      )
      .fill(
        AppTheme.accent
          .opacity(0.08)
      )
    )
  }

  // MARK: - Read Passage

  @ViewBuilder
  private var readPassageButton: some View {

    if let parsedPassage {

      NavigationLink {

        BibleReaderView(
          book:
            parsedPassage.book,
          chapter:
            parsedPassage.chapter,
          initialVerses:
            parsedPassage.verses,
          originJourneyID: journey.id,
          originCheckpointID: checkpoint.id
        )

      } label: {

        JourneyToolRow(
          title:
            "Read \(checkpoint.passage)",
          subtitle:
            "Read, highlight and save notes, then return to this checkpoint.",
          icon:
            "book.fill"
        )
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: - Reflection

  private var reflectionSection: some View {

    VStack(
      alignment: .leading,
      spacing: 12
    ) {

      Text(
        "Reflection"
      )
      .font(.title2)
      .bold()

      Text(
        "What stood out to you?"
      )
      .font(.subheadline)
      .foregroundStyle(AppTheme.textSecondary)

      TextEditor(
        text: $reflection
      )
      .frame(
        minHeight: 140
      )
      .padding(10)
      .background(
        RoundedRectangle(
          cornerRadius: 16
        )
        .fill(
          AppTheme.surface
        )
      )
      .overlay {

        RoundedRectangle(
          cornerRadius: 16
        )
        .stroke(
          AppTheme.textSecondary
            .opacity(0.15),
          lineWidth: 1
        )
      }

      if !reflection
        .trimmingCharacters(
          in:
            .whitespacesAndNewlines
        )
        .isEmpty
      {

        Label(
          "Reflection saved",
          systemImage:
            "checkmark.circle.fill"
        )
        .font(.caption)
        .foregroundStyle(AppTheme.textSecondary)
      }
    }
  }

  // MARK: - Action Label

  private func primaryActionLabel(
    title: String,
    icon: String
  ) -> some View {

    HStack {

      Image(
        systemName:
          icon
      )

      Text(title)
        .fontWeight(
          .semibold
        )

      Spacer()

      Image(
        systemName:
          "chevron.right"
      )
    }
    .frame(
      maxWidth: .infinity
    )
    .padding(
      .vertical,
      14
    )
  }

  // MARK: - Reflection Storage

  private func loadReflection() {

    guard !hasLoadedReflection else {
      return
    }

    if let stored =
      noteService.reflection(
        journeyID:
          journey.id,
        checkpointID:
          checkpoint.id
      )
    {

      reflection =
        stored.text
    }

    hasLoadedReflection =
      true
  }

  private func saveReflection() {

    noteService.saveReflection(
      journey: journey,
      checkpoint: checkpoint,
      text: reflection
    )
  }

  // MARK: - Complete

  private func completeCheckpoint() {

    guard !isCompleting else {
      return
    }

    isCompleting =
      true

    saveReflection()

    sessionStore.setStage(
      .completed,
      journey: journey,
      checkpoint: checkpoint
    )

    onComplete()

    isCompleting =
      false
  }
}

// MARK: - Tool Row

private struct JourneyToolRow:
  View
{

  let title: String
  let subtitle: String
  let icon: String

  var body: some View {

    HStack(
      spacing: 14
    ) {

      Image(
        systemName:
          icon
      )
      .font(.title3)
      .frame(
        width: 34
      )

      VStack(
        alignment: .leading,
        spacing: 3
      ) {

        Text(title)
          .font(.headline)

        Text(subtitle)
          .font(.caption)
          .foregroundStyle(AppTheme.textSecondary)
      }

      Spacer()

      Image(
        systemName:
          "chevron.right"
      )
      .foregroundStyle(AppTheme.textSecondary)
    }
    .padding(16)
    .background(
      RoundedRectangle(
        cornerRadius: 16
      )
      .fill(
        AppTheme.surface
      )
    )
  }
}

// MARK: - Preview

#Preview {

  NavigationStack {

    JourneyCheckpointView(
      journey:
        JourneyLibrary.meetJesus,
      checkpoint:
        JourneyLibrary
        .meetJesus
        .checkpoints[0],
      onComplete: {}
    )
    .environmentObject(
      OnboardingViewModel()
    )
  }
}
