import SwiftUI

// =========================================================
// MARK: - Daily Study View
// =========================================================

@MainActor
struct DailyStudyView: View {

  @Environment(\.scenePhase) private var scenePhase

  let plan: DailyStudyPlan

  @EnvironmentObject
  private var onboardingViewModel: OnboardingViewModel

  @StateObject
  private var viewModel: DailyStudyViewModel

  @ObservedObject
  private var store = DailyStudyStore.shared

  init(plan: DailyStudyPlan) {
    self.plan = plan
    _viewModel = StateObject(wrappedValue: DailyStudyViewModel(plan: plan))
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        header
        whyTodayCard
        scriptureCard

        if viewModel.isLoading {
          loadingCard
        }

        if let error = viewModel.errorMessage {
          generationNotice(error)
        }

        if let content = viewModel.content {
          studyContent(content)
          reflectionCard(content)
          prayerCard(content)
          actionLinks
          completionCard
        }

        recentDailyStudies

        Spacer(minLength: 36)
      }
      .padding()
    }
    .cloudScreen()
    .scrollDismissesKeyboard(.interactively)
    .onDisappear { viewModel.flushReflection() }
    .onChange(of: scenePhase) { _, phase in
      if phase != .active { viewModel.flushReflection() }
    }
    .navigationTitle("Daily Study")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await viewModel.load(profile: onboardingViewModel.profile)
    }

  }

  // =====================================================
  // MARK: - Header
  // =====================================================

  private var header: some View {
    HStack(alignment: .center, spacing: 14) {
      CompanionAvatar(
        size: 66,
        behavior: viewModel.isLoading ? .thinking : .floating
      )

      VStack(alignment: .leading, spacing: 4) {
        Text("TODAY WITH COMPANION")
          .font(.caption)
          .fontWeight(.bold)
          .tracking(0.8)
          .foregroundStyle(AppTheme.textSecondary)

        Text(plan.title)
          .font(.title2)
          .fontWeight(.bold)

        Text(plan.date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
          .font(.subheadline)
          .foregroundStyle(AppTheme.textSecondary)
      }

      Spacer()
    }
  }

  // =====================================================
  // MARK: - Why Today
  // =====================================================

  private var whyTodayCard: some View {
    VStack(alignment: .leading, spacing: 8) {
      Label(plan.reasonTitle, systemImage: "sparkles")
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundStyle(AppTheme.accent)

      Text(plan.reason)
        .font(.subheadline)
        .foregroundStyle(AppTheme.textSecondary)
        .lineSpacing(3)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(AppTheme.accent.opacity(0.07))
    )
  }

  // =====================================================
  // MARK: - Scripture
  // =====================================================

  private var scriptureCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Label("Today's Scripture", systemImage: "book.closed.fill")
          .font(.headline)

        Spacer()

        Text(plan.reference)
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(AppTheme.accent)
      }

      if viewModel.passageText.isEmpty {
        if viewModel.errorMessage == nil {
          ProgressView()
        }
      } else {
        Text(viewModel.passageText)
          .bibleReadingStyle()
          .foregroundStyle(AppTheme.textPrimary)
          .lineSpacing(3)
      }

      if let location = plan.location {
        NavigationLink {
          BibleReaderView(
            book: location.book,
            chapter: location.chapter,
            initialVerses: location.verses
          )
        } label: {
          Label("Read in Bible", systemImage: "arrow.up.right.square")
            .font(.subheadline)
            .fontWeight(.semibold)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.accent)
      }
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .fill(AppTheme.surface)
    )
  }

  // =====================================================
  // MARK: - Loading / Error
  // =====================================================

  private var loadingCard: some View {
    HStack(spacing: 12) {
      ProgressView()
      VStack(alignment: .leading, spacing: 2) {
        Text("Preparing a short guide…")
          .fontWeight(.semibold)
        Text("Today's passage stays the same even if you leave and come back.")
          .font(.caption)
          .foregroundStyle(AppTheme.textSecondary)
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 18)
        .fill(AppTheme.surface)
    )
  }

  private func generationNotice(_ message: String) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Label("Using the simple study guide", systemImage: "wifi.exclamationmark")
        .font(.subheadline)
        .fontWeight(.semibold)

      Text(message)
        .font(.caption)
        .foregroundStyle(AppTheme.textSecondary)

      Button("Try Companion Again") {
        Task {
          await viewModel.retry(profile: onboardingViewModel.profile)
        }
      }
      .buttonStyle(.bordered)
      .disabled(viewModel.isLoading)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 18)
        .fill(AppTheme.surface)
    )
  }

  // =====================================================
  // MARK: - Generated Study
  // =====================================================

  @ViewBuilder
  private func studyContent(_ content: DailyStudyContent) -> some View {
    dailySection(
      title: "Big Idea",
      icon: "lightbulb.fill",
      text: content.bigIdea
    )

    VStack(alignment: .leading, spacing: 12) {
      Label("Notice", systemImage: "eye.fill")
        .font(.headline)

      ForEach(Array(content.observations.enumerated()), id: \.offset) { index, item in
        HStack(alignment: .top, spacing: 10) {
          Text("\(index + 1)")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(AppTheme.accent)
            .frame(width: 24, height: 24)
            .background(Circle().fill(AppTheme.accent.opacity(0.1)))

          Text(item)
            .font(.body)
            .lineSpacing(3)

          Spacer(minLength: 0)
        }
      }
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(AppTheme.surface)
    )

    dailySection(
      title: "Try This Today",
      icon: "figure.walk",
      text: content.practice
    )
  }

  private func dailySection(
    title: String,
    icon: String,
    text: String
  ) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Label(title, systemImage: icon)
        .font(.headline)

      Text(text)
        .font(.body)
        .lineSpacing(3)
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(AppTheme.surface)
    )
  }

  // =====================================================
  // MARK: - Reflect
  // =====================================================

  private func reflectionCard(_ content: DailyStudyContent) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Label("Reflect", systemImage: "square.and.pencil")
        .font(.headline)

      Text(content.reflectionQuestion)
        .font(.body)
        .fontWeight(.semibold)
        .lineSpacing(3)

      DailyReflectionEditor(model: viewModel)
        .frame(minHeight: 118)
        .padding(10)
        .scrollContentBackground(.hidden)
        .background(
          RoundedRectangle(cornerRadius: 14)
            .fill(AppTheme.surfaceStrong)
        )
        .overlay(
          RoundedRectangle(cornerRadius: 14)
            .stroke(AppTheme.textSecondary.opacity(0.15), lineWidth: 1)
        )

      Text("Autosaved on this device. Daily reflections are not automatically added to Companion memory.")
        .font(.caption)
        .foregroundStyle(AppTheme.textSecondary)
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(AppTheme.accent.opacity(0.06))
    )
  }

  // =====================================================
  // MARK: - Prayer
  // =====================================================

  private func prayerCard(_ content: DailyStudyContent) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Label("Prayer Prompt", systemImage: "heart.fill")
        .font(.headline)

      Text(content.prayerPrompt)
        .font(.body)
        .lineSpacing(3)

      Text("This is a prompt for your own prayer, not a message presented as God's words to you.")
        .font(.caption)
        .foregroundStyle(AppTheme.textSecondary)
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(AppTheme.surface)
    )
  }

  // =====================================================
  // MARK: - Continue
  // =====================================================

  private var actionLinks: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Keep Going")
        .font(.headline)

      if let location = plan.location {
        NavigationLink {
          BibleStudyView(
            reference: BibleLibraryReference.legacyStudyReference(location),
            passage: viewModel.fullPassage
          )
        } label: {
          actionRow(
            title: "Study This Passage",
            subtitle: "Open the full Study with Companion experience",
            icon: "book.pages"
          )
        }
        .buttonStyle(.plain)
      }

      NavigationLink {
        CompanionView(
          passage: viewModel.fullPassage,
          mode: .explain,
          initialPrompt: companionPrompt,
          conversationKey: "daily-study-\(plan.dateKey)"
        )
      } label: {
        actionRow(
          title: "Talk About Today's Study",
          subtitle: "Continue in a saved conversation with Companion",
          icon: "bubble.left.and.bubble.right.fill"
        )
      }
      .buttonStyle(.plain)
    }
  }

  private func actionRow(
    title: String,
    subtitle: String,
    icon: String
  ) -> some View {
    HStack(spacing: 13) {
      Image(systemName: icon)
        .font(.title3)
        .foregroundStyle(AppTheme.accent)
        .frame(width: 34)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .fontWeight(.semibold)
          .foregroundStyle(AppTheme.textPrimary)
        Text(subtitle)
          .font(.caption)
          .foregroundStyle(AppTheme.textSecondary)
      }

      Spacer()

      Image(systemName: "chevron.right")
        .font(.caption.weight(.bold))
        .foregroundStyle(AppTheme.textSecondary)
    }
    .padding(15)
    .background(
      RoundedRectangle(cornerRadius: 17)
        .fill(AppTheme.surface)
    )
  }

  private var companionPrompt: String {
    let cleanReflection = viewModel.reflection.trimmingCharacters(in: .whitespacesAndNewlines)

    if cleanReflection.isEmpty {
      return "I want to talk more about today's Daily Study on \(plan.reference). What should I pay attention to?"
    }

    return "I want to talk more about today's Daily Study on \(plan.reference). My reflection so far is: \(String(cleanReflection.prefix(900)))"
  }

  // =====================================================
  // MARK: - Completion
  // =====================================================

  private var completionCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      if viewModel.isCompleted {
        Label("Today's study is complete", systemImage: "checkmark.circle.fill")
          .font(.headline)
          .foregroundStyle(AppTheme.accent)

        Text("You can revisit it anytime. Completing a Daily Study is simply a record of what you finished today; it isn't a spiritual score.")
          .font(.caption)
          .foregroundStyle(AppTheme.textSecondary)
      } else {
        Text("Finished for today?")
          .font(.headline)

        Text("Mark this study complete when you're ready. You can still come back and edit your reflection later.")
          .font(.subheadline)
          .foregroundStyle(AppTheme.textSecondary)

        Button {
          withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.markComplete()
          }
        } label: {
          Label("Mark Today's Study Complete", systemImage: "checkmark.circle")
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
      }
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(AppTheme.surface)
    )
  }

  // =====================================================
  // MARK: - Recent Daily Studies
  // =====================================================

  @ViewBuilder
  private var recentDailyStudies: some View {
    let recent = store.recentStartedRecords(excluding: plan.dateKey, limit: 5)

    if !recent.isEmpty {
      VStack(alignment: .leading, spacing: 10) {
        Text("Recent Daily Studies")
          .font(.headline)

        ForEach(recent) { record in
          NavigationLink {
            DailyStudyView(plan: record.plan)
          } label: {
            HStack(spacing: 12) {
              VStack(alignment: .leading, spacing: 2) {
                Text(record.plan.title)
                  .font(.subheadline)
                  .fontWeight(.semibold)
                  .foregroundStyle(AppTheme.textPrimary)

                Text("\(record.plan.reference) • \(record.plan.date.formatted(.dateTime.month(.abbreviated).day()))")
                  .font(.caption)
                  .foregroundStyle(AppTheme.textSecondary)
              }

              Spacer()

              if record.completedAt != nil {
                Image(systemName: "checkmark.circle.fill")
                  .foregroundStyle(AppTheme.accent)
              } else {
                Image(systemName: "chevron.right")
                  .font(.caption.weight(.bold))
                  .foregroundStyle(AppTheme.textSecondary)
              }
            }
            .padding(.vertical, 6)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.top, 4)
    }
  }
}
