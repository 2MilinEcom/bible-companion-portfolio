import SwiftUI

// =========================================================
// MARK: - Bible Study View
// =========================================================

@MainActor
struct BibleStudyView:
  View
{

  @State private var didRecordStudyVisit = false

  let reference: String

  let passage: String

  @EnvironmentObject
  private var onboardingViewModel: OnboardingViewModel

  @StateObject
  private var viewModel =
    BibleStudyViewModel()

  @ObservedObject
  private var reflectionStore =
    PassageReflectionStore.shared

  @State
  private var reflection =
    ""

  @State
  private var hasLoadedReflection =
    false

  @State
  private var understandExpanded =
    true

  @State
  private var contextExpanded =
    false

  @State
  private var themesExpanded =
    true

  @State
  private var deeperExpanded =
    false

  var body: some View {

    ScrollView {

      VStack(
        alignment:
          .leading,
        spacing:
          22
      ) {

        header

        passagePreview
        if let location = BibleLibraryReference.parse(reference) {
          ScrollView(.horizontal, showsIndicators: false) {
            BibleLibraryActions(location: location)
          }
        }

        if viewModel.isLoading {

          loadingCard

        } else if let error =
          viewModel.errorMessage
        {

          errorCard(
            error
          )

        } else if let guide =
          viewModel.guide
        {

          guideContent(
            guide
          )
        }

        Spacer(
          minLength:
            36
        )
      }
      .padding()
    }
    .cloudScreen()
    .navigationTitle(
      "Study"
    )
    .navigationBarTitleDisplayMode(
      .inline
    )
    .onAppear {
      if !didRecordStudyVisit {
        didRecordStudyVisit = true
        ResumeActivityStore.shared.recordStudy(reference: reference, passage: passage)
      }
    }
    .task {

      loadReflection()

      await viewModel
        .load(
          reference:
            reference,
          passage:
            passage,
          profile:
            onboardingViewModel
            .profile
        )
    }
    .onChange(
      of:
        reflection
    ) { _, newValue in

      guard
        hasLoadedReflection
      else {
        return
      }

      reflectionStore
        .save(
          reference:
            reference,
          text:
            newValue
        )
    }
  }

  // =====================================================
  // MARK: - Header
  // =====================================================

  private var header: some View {

    HStack(
      alignment:
        .center,
      spacing:
        14
    ) {

      CompanionAvatar(
        size:
          58,
        behavior:
          viewModel.isLoading
          ? .thinking
          : .floating
      )

      VStack(
        alignment:
          .leading,
        spacing:
          4
      ) {

        Text(
          "STUDY WITH COMPANION"
        )
        .font(
          .caption
        )
        .fontWeight(
          .bold
        )
        .tracking(
          0.7
        )
        .foregroundStyle(AppTheme.textSecondary)

        Text(
          reference
        )
        .font(
          .title2
        )
        .bold()
      }

      Spacer()
    }
  }

  // =====================================================
  // MARK: - Passage Preview
  // =====================================================

  private var passagePreview: some View {

    VStack(
      alignment:
        .leading,
      spacing:
        10
    ) {

      Label(
        "Selected Passage",
        systemImage:
          "book.closed.fill"
      )
      .font(
        .headline
      )

      Text(
        passage
      )
      .bibleReadingStyle()
      .foregroundStyle(AppTheme.textPrimary)
      .lineLimit(
        9
      )
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
      RoundedRectangle(
        cornerRadius:
          20
      )
      .fill(
        AppTheme.surface
      )
    )
  }

  // =====================================================
  // MARK: - Loading
  // =====================================================

  private var loadingCard: some View {

    HStack(
      spacing:
        14
    ) {

      ProgressView()

      VStack(
        alignment:
          .leading,
        spacing:
          3
      ) {

        Text(
          "Building your study guide..."
        )
        .font(
          .headline
        )

        Text(
          "Looking at the passage, context, and what may be most useful to explore."
        )
        .font(
          .subheadline
        )
        .foregroundStyle(AppTheme.textSecondary)
      }
    }
    .padding(
      20
    )
    .frame(
      maxWidth:
        .infinity,
      alignment:
        .leading
    )
    .background(
      RoundedRectangle(
        cornerRadius:
          20
      )
      .fill(
        AppTheme.surface
      )
    )
  }

  // =====================================================
  // MARK: - Error
  // =====================================================

  private func errorCard(
    _ message:
      String
  ) -> some View {

    VStack(
      alignment:
        .leading,
      spacing:
        12
    ) {

      Text(
        "The study guide couldn't load."
      )
      .font(
        .headline
      )

      Text(
        message
      )
      .font(
        .caption
      )
      .foregroundStyle(AppTheme.textSecondary)

      Button(
        "Try Again"
      ) {

        Task {

          await viewModel
            .retry(
              reference:
                reference,
              passage:
                passage,
              profile:
                onboardingViewModel
                .profile
            )
        }
      }
      .buttonStyle(
        .borderedProminent
      )
    }
    .padding(
      20
    )
    .frame(
      maxWidth:
        .infinity,
      alignment:
        .leading
    )
    .background(
      RoundedRectangle(
        cornerRadius:
          20
      )
      .fill(
        AppTheme.surface
      )
    )
  }

  // =====================================================
  // MARK: - Guide
  // =====================================================

  @ViewBuilder
  private func guideContent(
    _ guide:
      BibleStudyGuide
  ) -> some View {

    VStack(
      alignment:
        .leading,
      spacing:
        8
    ) {

      Text(
        guide.title
      )
      .font(
        .largeTitle
      )
      .bold()

      Text(
        "Move through as much or as little as you need."
      )
      .font(
        .subheadline
      )
      .foregroundStyle(AppTheme.textSecondary)
    }

    StudyDisclosureCard(
      title:
        "Understand",
      subtitle:
        "What is happening here?",
      icon:
        "text.book.closed",
      isExpanded:
        $understandExpanded
    ) {

      Text(
        guide.understand
      )
    }

    StudyDisclosureCard(
      title:
        "Context",
      subtitle:
        "Where does this fit?",
      icon:
        "clock.arrow.circlepath",
      isExpanded:
        $contextExpanded
    ) {

      Text(
        guide.context
      )
    }

    StudyDisclosureCard(
      title:
        "Key Themes",
      subtitle:
        "Ideas the passage keeps in view",
      icon:
        "list.bullet.rectangle",
      isExpanded:
        $themesExpanded
    ) {

      VStack(
        alignment:
          .leading,
        spacing:
          16
      ) {

        ForEach(
          guide.themes
        ) { theme in

          VStack(
            alignment:
              .leading,
            spacing:
              5
          ) {

            Text(
              theme.title
            )
            .font(
              .headline
            )

            Text(
              theme.explanation
            )
            .foregroundStyle(AppTheme.textSecondary)
          }
        }
      }
    }

    StudyDisclosureCard(
      title:
        "Go Deeper",
      subtitle:
        "Questions worth sitting with",
      icon:
        "questionmark.bubble",
      isExpanded:
        $deeperExpanded
    ) {

      VStack(
        alignment:
          .leading,
        spacing:
          18
      ) {

        ForEach(
          guide.goDeeper
        ) { item in

          VStack(
            alignment:
              .leading,
            spacing:
              6
          ) {

            Text(
              item.question
            )
            .font(
              .headline
            )

            if !item
              .whyItMatters
              .isEmpty
            {

              Text(
                item.whyItMatters
              )
              .font(
                .subheadline
              )
              .foregroundStyle(AppTheme.textSecondary)
            }
          }
        }
      }
    }

    if let connection =
      guide
      .meaningfulJourneyConnection
    {

      journeyConnectionCard(
        connection
      )
    }

    NavigationLink {

      PerspectivesView(
        passage:
          passage
      )

    } label: {

      StudyNavigationCard(
        title:
          "Compare Christian Views",
        subtitle:
          "See where major interpretations agree and differ.",
        icon:
          "person.3.fill"
      )
    }
    .buttonStyle(
      .plain
    )

    reflectionCard

    NavigationLink {

      CompanionView(
        passage:
          passage,
        mode:
          .explain,
        initialPrompt:
          "I'd like to keep studying \(reference). Help me work through what stands out in this passage.",
        conversationKey:
          studyConversationKey
      )

    } label: {

      HStack(
        spacing:
          14
      ) {

        CompanionAvatar(
          size:
            48,
          behavior:
            .floating
        )

        VStack(
          alignment:
            .leading,
          spacing:
            3
        ) {

          Text(
            "Continue the Conversation"
          )
          .font(
            .headline
          )

          Text(
            "Ask anything about this passage with the study context in view."
          )
          .font(
            .subheadline
          )
          .foregroundStyle(AppTheme.textSecondary)
        }

        Spacer()

        Image(
          systemName:
            "arrow.right"
        )
        .foregroundStyle(
          AppTheme.accent
        )
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
        RoundedRectangle(
          cornerRadius:
            20
        )
        .fill(
          AppTheme.accent
            .opacity(
              0.09
            )
        )
      )
    }
    .buttonStyle(
      .plain
    )
  }

  // =====================================================
  // MARK: - Journey Connection
  // =====================================================

  private func journeyConnectionCard(
    _ connection:
      String
  ) -> some View {

    HStack(
      alignment:
        .top,
      spacing:
        14
    ) {

      CompanionAvatar(
        size:
          48
      )

      VStack(
        alignment:
          .leading,
        spacing:
          6
      ) {

        Text(
          "Your Journey"
        )
        .font(
          .headline
        )

        Text(
          connection
        )
        .foregroundStyle(AppTheme.textSecondary)

        Text(
          "Shown only when the passage naturally connects with what you're already working through."
        )
        .font(
          .caption
        )
        .foregroundStyle(
          .tertiary
        )
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
      RoundedRectangle(
        cornerRadius:
          20
      )
      .fill(
        AppTheme.accent
          .opacity(
            0.07
          )
      )
    )
  }

  // =====================================================
  // MARK: - Reflection
  // =====================================================

  private var reflectionCard: some View {

    VStack(
      alignment:
        .leading,
      spacing:
        12
    ) {

      HStack {

        Label(
          "Reflect",
          systemImage:
            "square.and.pencil"
        )
        .font(
          .headline
        )

        Spacer()

        if !reflection
          .trimmingCharacters(
            in:
              .whitespacesAndNewlines
          )
          .isEmpty
        {

          Label(
            "Saved",
            systemImage:
              "checkmark.circle.fill"
          )
          .font(
            .caption
          )
          .foregroundStyle(AppTheme.textSecondary)
        }
      }

      Text(
        "What stands out, challenges you, raises a question, or feels worth remembering?"
      )
      .font(
        .subheadline
      )
      .foregroundStyle(AppTheme.textSecondary)

      TextEditor(
        text:
          $reflection
      )
      .frame(
        minHeight:
          140
      )
      .padding(
        8
      )
      .background(
        RoundedRectangle(
          cornerRadius:
            14
        )
        .fill(
          AppTheme.surfaceSoft
        )
      )

      Text(
        "Your reflection is saved privately and can help your Companion remember what you actually wrote later."
      )
      .font(
        .caption
      )
      .foregroundStyle(AppTheme.textSecondary)
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
      RoundedRectangle(
        cornerRadius:
          20
      )
      .fill(
        AppTheme.surface
      )
    )
  }

  private func loadReflection() {

    guard
      !hasLoadedReflection
    else {
      return
    }

    reflection =
      reflectionStore
      .text(
        for:
          reference
      )

    hasLoadedReflection =
      true
  }

  private var studyConversationKey: String {

    let safeReference =
      reference
      .lowercased()
      .components(
        separatedBy:
          CharacterSet
          .alphanumerics
          .inverted
      )
      .filter {
        !$0.isEmpty
      }
      .joined(
        separator:
          "-"
      )

    return
      "passage-study::\(safeReference)"
  }
}

// =========================================================
// MARK: - Disclosure Card
// =========================================================

private struct StudyDisclosureCard<Content: View>:
  View
{

  let title: String

  let subtitle: String

  let icon: String

  @Binding
  var isExpanded: Bool

  let content: Content

  init(
    title:
      String,
    subtitle:
      String,
    icon:
      String,
    isExpanded:
      Binding<Bool>,
    @ViewBuilder content:
      () -> Content
  ) {

    self.title =
      title

    self.subtitle =
      subtitle

    self.icon =
      icon

    self._isExpanded =
      isExpanded

    self.content =
      content()
  }

  var body: some View {

    VStack(
      alignment:
        .leading,
      spacing:
        0
    ) {

      Button {

        withAnimation(
          .easeInOut(
            duration:
              0.22
          )
        ) {

          isExpanded
            .toggle()
        }

      } label: {

        HStack(
          spacing:
            12
        ) {

          Image(
            systemName:
              icon
          )
          .frame(
            width:
              24
          )
          .foregroundStyle(
            AppTheme.accent
          )

          VStack(
            alignment:
              .leading,
            spacing:
              2
          ) {

            Text(
              title
            )
            .font(
              .headline
            )
            .foregroundStyle(AppTheme.textPrimary)

            Text(
              subtitle
            )
            .font(
              .caption
            )
            .foregroundStyle(AppTheme.textSecondary)
          }

          Spacer()

          Image(
            systemName:
              isExpanded
              ? "chevron.up"
              : "chevron.down"
          )
          .font(
            .caption
          )
          .foregroundStyle(AppTheme.textSecondary)
        }
        .contentShape(
          Rectangle()
        )
      }
      .buttonStyle(
        .plain
      )

      if isExpanded {

        Divider()
          .padding(
            .vertical,
            14
          )

        content
          .foregroundStyle(AppTheme.textSecondary)
          .lineSpacing(
            3
          )
          .transition(
            .opacity
              .combined(
                with:
                  .move(
                    edge:
                      .top
                  )
              )
          )
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
      RoundedRectangle(
        cornerRadius:
          20
      )
      .fill(
        AppTheme.surface
      )
    )
  }
}

// =========================================================
// MARK: - Navigation Card
// =========================================================

private struct StudyNavigationCard:
  View
{

  let title: String

  let subtitle: String

  let icon: String

  var body: some View {

    HStack(
      spacing:
        14
    ) {

      Image(
        systemName:
          icon
      )
      .font(
        .title3
      )
      .frame(
        width:
          34
      )
      .foregroundStyle(
        AppTheme.accent
      )

      VStack(
        alignment:
          .leading,
        spacing:
          3
      ) {

        Text(
          title
        )
        .font(
          .headline
        )

        Text(
          subtitle
        )
        .font(
          .subheadline
        )
        .foregroundStyle(AppTheme.textSecondary)
      }

      Spacer()

      Image(
        systemName:
          "chevron.right"
      )
      .foregroundStyle(AppTheme.textSecondary)
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
      RoundedRectangle(
        cornerRadius:
          20
      )
      .fill(
        AppTheme.surface
      )
    )
  }
}

#Preview {

  NavigationStack {

    BibleStudyView(
      reference:
        "John 15:1-8",
      passage:
        """
        John 15:1-8

        1 I am the true vine, and my Father is the gardener.
        2 He cuts off every branch in me that bears no fruit...
        """
    )
    .environmentObject(
      OnboardingViewModel()
    )
  }
}
