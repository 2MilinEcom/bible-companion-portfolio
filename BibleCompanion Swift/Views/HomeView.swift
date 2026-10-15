import SwiftUI

@MainActor
struct HomeView: View {
  @ObservedObject private var settings = AppSettingsStore.shared
  @ObservedObject private var navigation = MainNavigationCoordinator.shared

  // =====================================================
  // MARK: - Environment
  // =====================================================

  @EnvironmentObject
  var onboardingViewModel: OnboardingViewModel

  // =====================================================
  // MARK: - Tutorial
  // =====================================================

  @EnvironmentObject
  private var appTutorial: AppTutorialCoordinator

  @State
  private var tutorialOpenCheckpoint =
    false

  // =====================================================
  // MARK: - View Models
  // =====================================================

  @StateObject
  private var viewModel =
    HomeViewModel()

  @StateObject
  private var journeyProgress =
    JourneyProgressStore.shared

  @State
  private var showingCompletionChangePath =
    false

  @State
  private var continueItem: HomeContinueItem?

  @State private var showingSettings = false
  @State private var replayTourAfterSettings = false

  @ObservedObject
  private var dailyStudyStore = DailyStudyStore.shared

  @State
  private var dailyStudyPlan: DailyStudyPlan?

  @State
  private var showingDailyStudyFromWidget = false

  @State
  private var hasPreparedHome = false

  // =====================================================
  // MARK: - Foundation Journey
  // =====================================================

  private let foundationJourney =
    JourneyLibrary.meetJesus

  private var foundationCheckpoint: JourneyCheckpoint? {

    journeyProgress
      .currentCheckpoint(
        in:
          foundationJourney
      )
  }

  // =====================================================
  // MARK: - Current Focus
  // =====================================================

  private var currentFocusText: String {

    if let pathFocus =
      viewModel
      .activePersonalizedJourney?
      .focus?
      .label
      .trimmingCharacters(
        in:
          .whitespacesAndNewlines
      ),
      !pathFocus.isEmpty
    {

      return pathFocus
    }

    let profileFocus =
      onboardingViewModel
      .profile
      .resolvedStruggleLabel
      .trimmingCharacters(
        in:
          .whitespacesAndNewlines
      )

    if !profileFocus.isEmpty {

      return profileFocus
    }

    return onboardingViewModel
      .profile
      .primaryGoal
  }

  // =====================================================
  // MARK: - Daily Study Explicit Focus
  // =====================================================

  /// Daily Study reasons should come from something the user explicitly chose
  /// or wrote, not from an AI-derived struggle label.
  private var dailyStudyFocusText: String {

    if let pathFocus = viewModel
      .activePersonalizedJourney?
      .focus?
      .label
      .trimmingCharacters(in: .whitespacesAndNewlines),
      !pathFocus.isEmpty
    {
      return pathFocus
    }

    let selectedCategory = onboardingViewModel
      .profile
      .struggleCategory
      .trimmingCharacters(in: .whitespacesAndNewlines)

    if !selectedCategory.isEmpty,
      selectedCategory.lowercased() != "other"
    {
      return selectedCategory
    }

    let customText = onboardingViewModel
      .profile
      .customStruggleText
      .trimmingCharacters(in: .whitespacesAndNewlines)

    if !customText.isEmpty {
      return customText
    }

    return onboardingViewModel
      .profile
      .primaryGoal
  }

  // =====================================================
  // MARK: - Body
  // =====================================================

  var body: some View {

    ScrollViewReader {
      scrollProxy in

      ScrollView {

        VStack(
          alignment: .leading,
          spacing: 28
        ) {

          openingSections
          personalizedSections
          exploreSections

          Spacer(
            minLength: 40
          )
        }
        .padding()
      }
      .overlayPreferenceValue(
        AppTutorialHomeTargetPreferenceKey.self
      ) { anchors in

        if appTutorial.isActive,
          isHomeTutorialStep(
            appTutorial.step
          )
        {

          AppCoachMarkOverlay(
            step:
              appTutorial.step,
            targetAnchor:
              homeTutorialAnchor(
                for:
                  appTutorial.step,
                anchors:
                  anchors
              ),
            onBack:
              homeTutorialBackAction(
                scrollProxy:
                  scrollProxy
              ),
            onPrimary: {

              handleHomeTutorialPrimary(
                scrollProxy:
                  scrollProxy
              )
            },
            onSkip: {

              appTutorial.finish()
            }
          )
          .transition(
            .opacity
          )
        }
      }
      .task {

        await prepareHome()

        hasPreparedHome = true
        refreshDailyStudyPlan()
        refreshContinueItem()

        if navigation.dailyStudyRequested {
          navigation.dailyStudyRequested = false
          if appTutorial.isActive { appTutorial.finish() }
          await openDailyStudyFromWidget()
        }

        if appTutorial.isActive {

          await MainActor.run {

            scrollToHomeTutorialStep(
              appTutorial.step,
              scrollProxy:
                scrollProxy,
              animated:
                false
            )
          }
        }
      }
      .onAppear {

        refreshContinueItem()

        if hasPreparedHome {
          refreshDailyStudyPlan()
        }
      }
      .onChange(of: appTutorial.isActive) { _, isActive in
        guard isActive else { return }
        scrollToHomeTutorialStep(
          appTutorial.step, scrollProxy: scrollProxy, animated: false)
      }
      .onChange(
        of:
          appTutorial.step
      ) { _, newStep in

        guard appTutorial.isActive else {
          return
        }

        scrollToHomeTutorialStep(
          newStep,
          scrollProxy:
            scrollProxy
        )
      }
      .navigationDestination(
        isPresented:
          $showingDailyStudyFromWidget
      ) {

        if let dailyStudyPlan {
          DailyStudyView(plan: dailyStudyPlan)
        } else {
          ProgressView("Preparing today's study...")
        }
      }
      .navigationDestination(
        isPresented:
          $showingCompletionChangePath
      ) {

        ChangePathView(
          onPathChanged: {

            refreshPersonalizedState()
          }
        )
        .environmentObject(
          onboardingViewModel
        )
      }
      .navigationDestination(
        isPresented:
          $tutorialOpenCheckpoint
      ) {

        if let journey =
          viewModel
          .activePersonalizedJourney,
          let checkpoint =
            journeyProgress
            .currentCheckpoint(
              in:
                journey
            )
        {

          JourneyCheckpointView(
            journey:
              journey,
            checkpoint:
              checkpoint,
            onComplete: {

              viewModel
                .completeCheckpoint(
                  checkpoint
                )
            }
          )

        } else {

          EmptyView()
        }
      }
    }
    .cloudScreen()
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          showingSettings = true
        } label: {
          Image(systemName: "gearshape")
        }
        .accessibilityLabel("Settings")
        .disabled(appTutorial.isActive)
      }
    }
    .sheet(isPresented: $showingSettings, onDismiss: settingsDidDismiss) {
      NavigationStack {
        AppSettingsView(onReplayTutorial: {
          // Reset the tutorial only after this presentation is gone, so no
          // coach mark or automatic navigation appears behind the Settings sheet.
          replayTourAfterSettings = true
          showingSettings = false
        })
      }
      .environmentObject(onboardingViewModel)
      .environmentObject(appTutorial)
    }
  }

  @MainActor
  private func settingsDidDismiss() {
    refreshPersonalizedState()
    refreshDailyStudyPlan()
    refreshContinueItem()
    guard replayTourAfterSettings else { return }
    replayTourAfterSettings = false
    appTutorial.reset()
  }


  @ViewBuilder
  private var openingSections: some View {
  // =================================================
  // MARK: Header
  // =================================================

  HomeCloudHero(
    preferredName: onboardingViewModel.profile.preferredName
  )
  .appTutorialHomeTarget(
    .home
  )

  // =================================================
  // MARK: Companion Growth
  // =================================================


  // =================================================
  // MARK: Daily Study
  // =================================================

  if !appTutorial.isActive,
    let dailyStudyPlan
  {
    NavigationLink {
      DailyStudyView(plan: dailyStudyPlan)
    } label: {
      DailyStudyHomeCard(
        plan: dailyStudyPlan,
        isComplete: dailyStudyStore.record(dateKey: dailyStudyPlan.dateKey)?.completedAt != nil
      )
    }
    .buttonStyle(.plain)
  }

  if settings.showGrowthOnHome || appTutorial.isActive {
    CompanionGrowthHomeCard()
  }

  // =================================================
  // MARK: Continue Where You Left Off
  // =================================================

  if !appTutorial.isActive,
    let continueItem
  {

    NavigationLink {

      continueDestination(
        for:
          continueItem
      )

    } label: {

      HomeContinueCard(
        item:
          continueItem
      )
    }
    .buttonStyle(
      .plain
    )
  }

  // =================================================
  // MARK: Foundation Journey
  // =================================================

  if !appTutorial.isActive, settings.showLibraryOnHome {
    HomeBibleLibrarySection(excludedTitle: continueItem?.title)
  }

  ActiveJourneyCard(
    journey:
      foundationJourney,
    currentCheckpoint:
      foundationCheckpoint,
    progressStore:
      journeyProgress
  )

  // =================================================
  // MARK: Current Focus
  // =================================================

  if !currentFocusText
    .trimmingCharacters(
      in:
        .whitespacesAndNewlines
    )
    .isEmpty
  {

    VStack(
      alignment: .leading,
      spacing: 6
    ) {

      Text(
        "YOUR CURRENT FOCUS"
      )
      .font(
        .caption
      )
      .fontWeight(
        .semibold
      )
      .foregroundStyle(AppTheme.textSecondary)

      Text(
        currentFocusText
      )
      .font(
        .headline
      )
    }
  }
  }

  @ViewBuilder
  private var personalizedSections: some View {
  Divider()

  // =================================================
  // MARK: Recommended for You
  // =================================================

  CloudSectionHeader(
    title: "Your Journey",
    subtitle: "A guided path through Scripture based on what you're working through.",
    icon: "sparkles"
  )
  .appTutorialHomeTarget(
    .personalized
  )

  // -------------------------------------------------
  // Persistent Personalized Journey
  // -------------------------------------------------

  if let personalizedJourney =
    viewModel
    .activePersonalizedJourney
  {

    PersonalizedJourneyCard(
      journey:
        personalizedJourney,
      progressStore:
        journeyProgress,
      onComplete: {
        checkpoint in

        viewModel
          .completeCheckpoint(
            checkpoint
          )
      },
      onChooseAnotherFocus: {

        showingCompletionChangePath =
          true

        viewModel
          .finishActivePersonalizedJourney()

        refreshPersonalizedState()
      },
      onKeepWorking: {

        viewModel
          .keepWorkingOnCurrentJourney()

        refreshPersonalizedState()
      },
      onPathChanged: {

        refreshPersonalizedState()
      }
    )

    // -------------------------------------------------
    // Loading
    // -------------------------------------------------

  } else if viewModel
    .isLoading
  {

    HStack(
      spacing: 12
    ) {

      ProgressView()

      Text(
        "Preparing your personalized path..."
      )
      .foregroundStyle(AppTheme.textSecondary)
    }
    .padding(
      .vertical,
      30
    )

    // -------------------------------------------------
    // Legacy One-Off Recommendation
    // -------------------------------------------------

  } else if let recommendation =
    viewModel
    .recommendation
  {

    JourneyCard(
      recommendation:
        recommendation
    ) {

      viewModel
        .completeRecommendation(
          recommendation,
          profile:
            onboardingViewModel
            .profile
        )
    }

    // -------------------------------------------------
    // Error
    // -------------------------------------------------

  } else if let error =
    viewModel
    .errorMessage
  {

    VStack(
      alignment: .leading,
      spacing: 12
    ) {

      Text(
        "We couldn't prepare your path."
      )
      .font(
        .headline
      )

      Text(
        error
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
            .refreshRecommendation(
              profile:
                onboardingViewModel
                .profile
            )
        }
      }
    }

    // -------------------------------------------------
    // No Active Personalized Journey
    // -------------------------------------------------

  } else {

    NoActivePersonalizedPathCard(
      hasPastJourneys:
        !viewModel
        .pastPersonalizedJourneys
        .isEmpty,
      onPathChanged: {

        refreshPersonalizedState()
      }
    )
  }
  }

  @ViewBuilder
  private var exploreSections: some View {
  Divider()

  // =================================================
  // MARK: Explore
  // =================================================

  CloudSectionHeader(
    title: "Explore",
    subtitle: "Read, ask, and keep growing at your own pace.",
    icon: "cloud.sun.fill"
  )

  NavigationLink {

    BibleExplorerView()

  } label: {

    HomeOptionRow(
      title:
        "Read Scripture",
      subtitle:
        "Search and study any passage.",
      icon:
        "book.fill"
    )
  }
  .buttonStyle(
    .plain
  )
  .appTutorialHomeTarget(
    .scripture
  )

  NavigationLink {

    CompanionView()

  } label: {

    HomeOptionRow(
      title:
        "Ask Companion",
      subtitle:
        "Ask anything about Scripture or faith.",
      icon:
        "sparkles",
      usesCompanionAvatar:
        true
    )
  }
  .buttonStyle(
    .plain
  )
  .appTutorialHomeTarget(
    .companion
  )

  NavigationLink {

    JourneyMapView(
      journey:
        foundationJourney
    )

  } label: {

    HomeOptionRow(
      title:
        "Meet Jesus Journey",
      subtitle:
        "See your foundation checkpoints and progress.",
      icon:
        "map.fill"
    )
  }
  .buttonStyle(
    .plain
  )
  }

  // =====================================================
  // MARK: - Daily Study
  // =====================================================

  @MainActor
  private func refreshDailyStudyPlan() {

    let recentReferences = BibleLibraryStore.shared.visits
      .prefix(12)
      .map { $0.location.reference }

    let previousPlans = dailyStudyStore
      .recentRecords(limit: 14)
      .map(\.plan)

    let proposedPlan = DailyStudyPlanner.makePlan(
      for: Date(),
      focusText: dailyStudyFocusText,
      goalText: onboardingViewModel.profile.primaryGoal,
      recentReferences: Array(recentReferences),
      previousPlans: previousPlans
    )

    let record = dailyStudyStore.ensurePlan(proposedPlan)
    dailyStudyPlan = record.plan

    DailyWidgetBridge.shared.publishSchedule(
      todayRecord: record,
      focusText: dailyStudyFocusText,
      goalText: onboardingViewModel.profile.primaryGoal,
      recentReferences: Array(recentReferences),
      previousPlans: previousPlans
    )
  }

  @MainActor
  private func openDailyStudyFromWidget() async {

    // When a widget snapshot exists, today's plan normally already exists in
    // DailyStudyStore. Reuse it immediately rather than choosing a new one.
    if let existing = dailyStudyStore.todayRecord {
      dailyStudyPlan = existing.plan
      showingDailyStudyFromWidget = true
      return
    }

    // If the app has not opened yet today, prepare the same Home state used by
    // a normal launch before locking today's plan.
    if !hasPreparedHome {
      await prepareHome()
      hasPreparedHome = true
    }

    refreshDailyStudyPlan()
    showingDailyStudyFromWidget = dailyStudyPlan != nil
  }

  // =====================================================
  // MARK: - Continue Destination
  // =====================================================

  @ViewBuilder
  private func continueDestination(
    for item:
      HomeContinueItem
  ) -> some View {

    switch item.destination {
    case .study(let reference, let passage):
      BibleStudyView(reference: reference, passage: passage)

    case .checkpoint(
      let journey,
      let checkpoint,
      let isPersonalized
    ):

      JourneyCheckpointView(
        journey:
          journey,
        checkpoint:
          checkpoint,
        onComplete: {

          if isPersonalized {

            viewModel
              .completeCheckpoint(
                checkpoint
              )

          } else {

            journeyProgress
              .complete(
                checkpoint,
                in:
                  journey
              )
          }

          refreshContinueItem()
        }
      )

    case .reading(
      let book,
      let chapter,
      let verses
    ):

      BibleReaderView(
        book:
          book,
        chapter:
          chapter,
        initialVerses:
          verses
      )

    case .companion(
      let conversationKey,
      let passage
    ):

      CompanionView(
        passage:
          passage,
        conversationKey:
          conversationKey
      )
    }
  }

  // =====================================================
  // MARK: - Continue Item
  // =====================================================

  @MainActor
  private func refreshContinueItem() {

    continueItem =
      HomeContinueService
      .shared
      .mostRecentItem(
        foundationJourney:
          foundationJourney,
        progressStore:
          journeyProgress
      )
  }

  // =====================================================
  // MARK: - Tutorial Navigation
  // =====================================================

  private func isHomeTutorialStep(
    _ step:
      GuidedAppTutorialStep
  ) -> Bool {

    switch step {

    case .welcome,
      .foundation,
      .personalized,
      .beginPath,
      .changePath,
      .scripture,
      .companion,
      .ready:

      return true

    default:

      return false
    }
  }

  private func homeTutorialTarget(
    for step:
      GuidedAppTutorialStep
  ) -> AppTutorialHomeTarget? {

    switch step {

    case .welcome:
      return .home

    case .foundation:
      return .foundation

    case .personalized:
      return .personalized

    case .beginPath:
      return .beginPath

    case .changePath:
      return .changePath

    case .scripture:
      return .scripture

    case .companion:
      return .companion

    case .ready:
      return nil

    default:
      return nil
    }
  }

  private func homeTutorialAnchor(
    for step:
      GuidedAppTutorialStep,
    anchors:
      [AppTutorialHomeTarget: Anchor<CGRect>]
  ) -> Anchor<CGRect>? {

    guard
      let target =
        homeTutorialTarget(
          for:
            step
        )
    else {

      return nil
    }

    return anchors[
      target
    ]
  }

  private func scrollToHomeTutorialStep(
    _ step:
      GuidedAppTutorialStep,
    scrollProxy:
      ScrollViewProxy,
    animated:
      Bool = true
  ) {

    guard
      let target =
        homeTutorialTarget(
          for:
            step
        )
    else {

      return
    }

    let action = {

      scrollProxy.scrollTo(
        target.scrollID,
        anchor:
          .top
      )
    }

    if animated {

      withAnimation(
        .easeInOut(
          duration: 0.42
        )
      ) {

        action()
      }

    } else {

      action()
    }
  }

  private func handleHomeTutorialPrimary(
    scrollProxy:
      ScrollViewProxy
  ) {

    switch appTutorial.step {

    case .welcome:
      appTutorial.move(
        to:
          .foundation
      )

    case .foundation:
      appTutorial.move(
        to:
          .personalized
      )

    case .personalized:
      appTutorial.move(
        to:
          .beginPath
      )

    case .beginPath:

      guard
        let journey =
          viewModel
          .activePersonalizedJourney,
        journeyProgress
          .currentCheckpoint(
            in:
              journey
          )
          != nil
      else {

        appTutorial.move(
          to:
            .changePath
        )

        return
      }

      appTutorial.move(
        to:
          .checkpointOverview
      )

      tutorialOpenCheckpoint =
        true

    case .changePath:

      appTutorial.move(
        to:
          .changeMethods
      )

      showingCompletionChangePath =
        true

    case .scripture:
      appTutorial.move(
        to:
          .companion
      )

    case .companion:
      appTutorial.move(
        to:
          .ready
      )

    case .ready:

      scrollProxy.scrollTo(
        AppTutorialHomeTarget.home.scrollID,
        anchor:
          .top
      )

      appTutorial.finish()

    default:
      break
    }
  }

  private func homeTutorialBackAction(
    scrollProxy:
      ScrollViewProxy
  ) -> (() -> Void)? {

    switch appTutorial.step {

    case .foundation:
      return {
        appTutorial.move(
          to:
            .welcome
        )
      }

    case .personalized:
      return {
        appTutorial.move(
          to:
            .foundation
        )
      }

    case .beginPath:
      return {
        appTutorial.move(
          to:
            .personalized
        )
      }

    case .changePath:
      return {
        appTutorial.move(
          to:
            .beginPath
        )
      }

    case .scripture:
      return {
        appTutorial.move(
          to:
            .changePath
        )
      }

    case .companion:
      return {
        appTutorial.move(
          to:
            .scripture
        )
      }

    case .ready:
      return {
        appTutorial.move(
          to:
            .companion
        )
      }

    default:
      return nil
    }
  }

  // =====================================================
  // MARK: - Refresh Personalized State
  // =====================================================

  @MainActor
  private func refreshPersonalizedState() {

    viewModel
      .loadPersonalizedJourneyState()

    viewModel
      .refreshPastJourneys()

    refreshContinueItem()
  }

  // =====================================================
  // MARK: - Prepare Home
  // =====================================================

  @MainActor
  private func prepareHome()
    async
  {

    // -------------------------------------------------
    // Load Existing Personalized State
    // -------------------------------------------------

    viewModel
      .loadPersonalizedJourneyState()

    // -------------------------------------------------
    // Migration for Existing Users
    // -------------------------------------------------

    if viewModel
      .activePersonalizedJourney
      == nil,

      viewModel
        .pastPersonalizedJourneys
        .isEmpty,

      let focus =
        onboardingViewModel
        .currentJourneyFocus,

      let path =
        JourneyLibrary
        .personalizedPath(
          for:
            focus
        )
    {

      viewModel
        .activatePersonalizedJourney(
          path
        )
    }

    // -------------------------------------------------
    // Show a saved recommendation immediately. Generate only after a user
    // chooses a focus; opening Today must not wait on an AI request.
    // -------------------------------------------------
    if viewModel.activePersonalizedJourney == nil {
      viewModel.recommendation = StorageService.shared.loadJourneyRecommendation()
    }

  }
}

// =========================================================
// MARK: - Foundation Journey Card
// =========================================================

struct ActiveJourneyCard: View {

  let journey: JourneyPath

  let currentCheckpoint: JourneyCheckpoint?

  @ObservedObject
  var progressStore: JourneyProgressStore

  private var completedCount: Int {

    progressStore
      .completedCount(
        in:
          journey
      )
  }

  private var progress: Double {

    progressStore
      .progress(
        in:
          journey
      )
  }

  private var percentage: Int {

    Int(
      progress * 100
    )
  }

  var body: some View {

    VStack(
      alignment: .leading,
      spacing: 18
    ) {

      CloudScenery(
        mood: .mountainPath,
        showsCompanion: true,
        height: 118
      )
      .clipShape(
        RoundedRectangle(
          cornerRadius: 18,
          style: .continuous
        )
      )

      // =================================================
      // MARK: Header
      // =================================================

      HStack(
        alignment: .top
      ) {

        VStack(
          alignment: .leading,
          spacing: 5
        ) {

          Text(
            "FOUNDATION JOURNEY"
          )
          .font(
            .caption
          )
          .fontWeight(
            .bold
          )
          .foregroundStyle(AppTheme.textSecondary)

          Text(
            journey.title
          )
          .font(
            .title
          )
          .bold()

          Text(
            journey.subtitle
          )
          .font(
            .subheadline
          )
          .foregroundStyle(AppTheme.textSecondary)
        }
        .appTutorialHomeTarget(
          .foundation
        )

        Spacer()

        VStack(
          alignment: .trailing,
          spacing: 2
        ) {

          Text(
            "\(completedCount)/\(journey.checkpoints.count)"
          )
          .font(
            .headline
          )

          Text(
            "\(percentage)%"
          )
          .font(
            .caption
          )
          .foregroundStyle(AppTheme.textSecondary)
        }
      }

      // =================================================
      // MARK: Progress
      // =================================================

      ProgressView(
        value:
          progress
      )
      .tint(AppTheme.accent)

      // =================================================
      // MARK: Current Checkpoint
      // =================================================

      if let currentCheckpoint {

        VStack(
          alignment: .leading,
          spacing: 10
        ) {

          Text(
            "NEXT CHECKPOINT"
          )
          .font(
            .caption2
          )
          .fontWeight(
            .bold
          )
          .foregroundStyle(AppTheme.textSecondary)

          Text(
            currentCheckpoint
              .title
          )
          .font(
            .headline
          )

          Label(
            currentCheckpoint
              .passage,
            systemImage:
              "book.closed.fill"
          )
          .font(
            .subheadline
          )
          .foregroundStyle(AppTheme.textSecondary)

          Text(
            currentCheckpoint
              .subtitle
          )
          .font(
            .subheadline
          )
          .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(
          16
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
              16
          )
          .fill(
            AppTheme.surfaceSoft
          )
        )

        // =============================================
        // MARK: Continue
        // =============================================

        NavigationLink {

          JourneyCheckpointView(
            journey:
              journey,
            checkpoint:
              currentCheckpoint,
            onComplete: {

              progressStore
                .complete(
                  currentCheckpoint,
                  in:
                    journey
                )
            }
          )

        } label: {

          HStack {

            Text(
              "Continue Meet Jesus"
            )
            .fontWeight(
              .semibold
            )

            Spacer()

            Image(
              systemName:
                "arrow.right"
            )
          }
          .frame(
            maxWidth:
              .infinity
          )
          .padding(
            .vertical,
            14
          )
        }
        .buttonStyle(
          .borderedProminent
        )
      .foregroundStyle(Color.white)

      } else {

        VStack(
          spacing: 10
        ) {

          Image(
            systemName:
              "checkmark.seal.fill"
          )
          .font(
            .largeTitle
          )
          .foregroundStyle(
            AppTheme.accent
          )

          Text(
            "Journey Complete"
          )
          .font(
            .headline
          )

          Text(
            "You've completed every checkpoint in the Meet Jesus journey."
          )
          .font(
            .subheadline
          )
          .foregroundStyle(AppTheme.textSecondary)
          .multilineTextAlignment(
            .center
          )
        }
        .frame(
          maxWidth:
            .infinity
        )
        .padding()
      }

      // =================================================
      // MARK: Full Map
      // =================================================

      NavigationLink {

        JourneyMapView(
          journey:
            journey
        )

      } label: {

        HStack {

          Image(
            systemName:
              "map"
          )

          Text(
            "View Full Journey"
          )
          .fontWeight(
            .semibold
          )

          Spacer()

          Image(
            systemName:
              "chevron.right"
          )
        }
        .padding(
          .vertical,
          5
        )
      }
      .buttonStyle(
        .plain
      )
    }
    .padding(
      20
    )
    .background(
      RoundedRectangle(
        cornerRadius: 24,
        style: .continuous
      )
      .fill(AppTheme.cardGradient)
      .shadow(
        color: AppTheme.shadow,
        radius: 15,
        y: 7
      )
    )
    .overlay(
      RoundedRectangle(
        cornerRadius: 24,
        style: .continuous
      )
      .stroke(Color.white.opacity(0.72), lineWidth: 1)
    )
  }
}

// =========================================================
// MARK: - Personalized Journey Card
// =========================================================

struct PersonalizedJourneyCard: View {

  @EnvironmentObject
  private var onboardingViewModel: OnboardingViewModel

  let journey: JourneyPath

  @ObservedObject
  var progressStore: JourneyProgressStore

  let onComplete: (JourneyCheckpoint) -> Void

  let onChooseAnotherFocus: () -> Void

  let onKeepWorking: () -> Void

  let onPathChanged: () -> Void

  @State
  private var keptWorkingConfirmation =
    false

  // =====================================================
  // MARK: - Progress
  // =====================================================

  private var completedCount: Int {

    progressStore
      .completedCount(
        in:
          journey
      )
  }

  private var progress: Double {

    progressStore
      .progress(
        in:
          journey
      )
  }

  private var percentage: Int {

    Int(
      progress * 100
    )
  }

  private var currentCheckpoint: JourneyCheckpoint? {

    progressStore
      .currentCheckpoint(
        in:
          journey
      )
  }

  private var completedCheckpoints: [JourneyCheckpoint] {

    progressStore
      .completedCheckpointList(
        in:
          journey
      )
  }

  private var recentCompletedCheckpoints: [JourneyCheckpoint] {

    Array(
      completedCheckpoints
        .suffix(
          3
        )
    )
  }

  // =====================================================
  // MARK: - Body
  // =====================================================

  var body: some View {

    VStack(
      alignment: .leading,
      spacing: 18
    ) {

      CloudScenery(
        mood: .sunrise,
        showsCompanion: true,
        height: 112
      )
      .clipShape(
        RoundedRectangle(
          cornerRadius: 18,
          style: .continuous
        )
      )

      // =================================================
      // MARK: Journey Header
      // =================================================

      HStack(
        alignment: .top,
        spacing: 14
      ) {

        VStack(
          alignment: .leading,
          spacing: 6
        ) {

          Text(
            "YOUR PERSONALIZED PATH"
          )
          .font(
            .caption
          )
          .fontWeight(
            .bold
          )
          .foregroundStyle(AppTheme.textSecondary)

          Text(
            journey.title
          )
          .font(
            .title2
          )
          .bold()

          Text(
            journey.subtitle
          )
          .font(
            .subheadline
          )
          .foregroundStyle(AppTheme.textSecondary)
        }

        Spacer()

        VStack(
          alignment: .trailing,
          spacing: 3
        ) {

          Text(
            "\(completedCount) of \(journey.checkpoints.count)"
          )
          .font(
            .headline
          )

          Text(
            "\(percentage)%"
          )
          .font(
            .caption
          )
          .foregroundStyle(AppTheme.textSecondary)
        }
      }

      // =================================================
      // MARK: Progress
      // =================================================

      ProgressView(
        value:
          progress
      )
      .tint(AppTheme.accent)

      // =================================================
      // MARK: What You've Covered
      // =================================================

      if !completedCheckpoints
        .isEmpty
      {

        VStack(
          alignment: .leading,
          spacing: 10
        ) {

          Text(
            "WHAT YOU'VE COVERED"
          )
          .font(
            .caption2
          )
          .fontWeight(
            .bold
          )
          .foregroundStyle(AppTheme.textSecondary)

          ForEach(
            recentCompletedCheckpoints
          ) { checkpoint in

            HStack(
              alignment: .top,
              spacing: 9
            ) {

              Image(
                systemName:
                  "checkmark.circle.fill"
              )
              .font(
                .subheadline
              )
              .foregroundStyle(
                AppTheme.accent
              )

              VStack(
                alignment:
                  .leading,
                spacing: 2
              ) {

                Text(
                  checkpoint
                    .title
                )
                .font(
                  .subheadline
                )
                .fontWeight(
                  .semibold
                )

                Text(
                  checkpoint
                    .passage
                )
                .font(
                  .caption
                )
                .foregroundStyle(AppTheme.textSecondary)
              }
            }
          }

          if completedCheckpoints
            .count
            > recentCompletedCheckpoints
            .count
          {

            Text(
              "+ \(completedCheckpoints.count - recentCompletedCheckpoints.count) earlier checkpoints"
            )
            .font(
              .caption
            )
            .foregroundStyle(AppTheme.textSecondary)
          }
        }
        .padding(
          14
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
              14
          )
          .fill(
            AppTheme.surfaceSoft
          )
        )
      }

      // =================================================
      // MARK: Next Checkpoint
      // =================================================

      if let currentCheckpoint {

        VStack(
          alignment: .leading,
          spacing: 10
        ) {

          Text(
            "NEXT · CHECKPOINT \(currentCheckpoint.order) OF \(journey.checkpoints.count)"
          )
          .font(
            .caption2
          )
          .fontWeight(
            .bold
          )
          .foregroundStyle(AppTheme.textSecondary)

          Text(
            currentCheckpoint
              .title
          )
          .font(
            .title3
          )
          .fontWeight(
            .semibold
          )

          Label(
            currentCheckpoint
              .passage,
            systemImage:
              "book.closed.fill"
          )
          .font(
            .subheadline
          )
          .foregroundStyle(AppTheme.textSecondary)

          Text(
            currentCheckpoint
              .subtitle
          )
          .font(
            .subheadline
          )
          .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(
          16
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
              16
          )
          .fill(
            AppTheme.surfaceSoft
          )
        )

        // =============================================
        // MARK: Continue Path
        // =============================================

        NavigationLink {

          JourneyCheckpointView(
            journey:
              journey,
            checkpoint:
              currentCheckpoint,
            onComplete: {

              onComplete(
                currentCheckpoint
              )
            }
          )

        } label: {

          HStack {

            Text(
              completedCount == 0
                ? "Begin Path"
                : "Continue Path"
            )
            .fontWeight(
              .semibold
            )

            Spacer()

            Image(
              systemName:
                "arrow.right"
            )
          }
          .frame(
            maxWidth:
              .infinity
          )
          .padding(
            .vertical,
            14
          )
        }
        .buttonStyle(
          .borderedProminent
        )
      .foregroundStyle(Color.white)
        .appTutorialHomeTarget(
          .beginPath
        )

      } else {

        VStack(
          alignment: .leading,
          spacing: 18
        ) {

          HStack(
            alignment: .top,
            spacing: 12
          ) {

            Image(
              systemName:
                "checkmark.seal.fill"
            )
            .font(
              .largeTitle
            )
            .foregroundStyle(
              AppTheme.accent
            )

            VStack(
              alignment: .leading,
              spacing: 5
            ) {

              Text(
                "Path Complete"
              )
              .font(
                .title3
              )
              .fontWeight(
                .semibold
              )

              Text(
                "You've completed all \(journey.checkpoints.count) checkpoints in \(journey.title)."
              )
              .font(
                .subheadline
              )
              .foregroundStyle(AppTheme.textSecondary)
            }
          }

          Divider()

          VStack(
            alignment: .leading,
            spacing: 6
          ) {

            Text(
              "Do you feel ready to move on?"
            )
            .font(
              .headline
            )

            Text(
              "You can choose a new focus, keep this as your active path, or review everything you've covered."
            )
            .font(
              .subheadline
            )
            .foregroundStyle(AppTheme.textSecondary)
          }

          Button {

            onChooseAnotherFocus()

          } label: {

            HStack {

              Image(
                systemName:
                  "arrow.triangle.branch"
              )

              Text(
                "Choose Another Focus"
              )
              .fontWeight(
                .semibold
              )

              Spacer()

              Image(
                systemName:
                  "arrow.right"
              )
            }
            .frame(
              maxWidth:
                .infinity
            )
            .padding(
              .vertical,
              13
            )
          }
          .buttonStyle(
            .borderedProminent
          )
      .foregroundStyle(Color.white)

          Button {

            onKeepWorking()

            withAnimation {

              keptWorkingConfirmation =
                true
            }

          } label: {

            HStack {

              Image(
                systemName:
                  "bookmark.fill"
              )

              Text(
                "I Want to Keep Working on This"
              )
              .fontWeight(
                .semibold
              )

              Spacer()
            }
            .frame(
              maxWidth:
                .infinity
            )
            .padding(
              .vertical,
              13
            )
          }
          .buttonStyle(
            .bordered
          )

          NavigationLink {

            JourneyReviewView(
              journey:
                journey
            )

          } label: {

            HStack {

              Image(
                systemName:
                  "book.open"
              )

              Text(
                "Review What I've Learned"
              )
              .fontWeight(
                .semibold
              )

              Spacer()

              Image(
                systemName:
                  "chevron.right"
              )
            }
            .padding(
              .vertical,
              7
            )
          }
          .buttonStyle(
            .plain
          )

          if keptWorkingConfirmation {

            HStack(
              alignment: .top,
              spacing: 10
            ) {

              Image(
                systemName:
                  "checkmark.circle.fill"
              )
              .foregroundStyle(
                AppTheme.accent
              )

              Text(
                "We'll keep this as your active focus. You can revisit the passages or review the full path whenever you want."
              )
              .font(
                .caption
              )
              .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(
              12
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
                  12
              )
              .fill(
                AppTheme.accent
                  .opacity(
                    0.08
                  )
              )
            )
            .transition(
              .opacity
            )
          }
        }
        .padding(
          16
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
              18
          )
          .fill(
            AppTheme.surfaceSoft
          )
        )
      }

      if currentCheckpoint != nil {

        Divider()

        // =================================================
        // MARK: View Full Path
        // =================================================

        NavigationLink {

          JourneyMapView(
            journey:
              journey
          )

        } label: {

          HStack {

            Image(
              systemName:
                "map"
            )

            Text(
              "View Full Path"
            )
            .fontWeight(
              .semibold
            )

            Spacer()

            Image(
              systemName:
                "chevron.right"
            )
          }
          .padding(
            .vertical,
            5
          )
        }
        .buttonStyle(
          .plain
        )

        // =================================================
        // MARK: Change Path
        // =================================================

        NavigationLink {

          ChangePathView(
            onPathChanged: {

              onPathChanged()
            }
          )
          .environmentObject(
            onboardingViewModel
          )

        } label: {

          HStack {

            Image(
              systemName:
                "arrow.triangle.branch"
            )

            Text(
              "Change Path"
            )
            .fontWeight(
              .semibold
            )

            Spacer()

            Image(
              systemName:
                "chevron.right"
            )
          }
          .padding(
            .vertical,
            5
          )
        }
        .buttonStyle(
          .plain
        )
        .appTutorialHomeTarget(
          .changePath
        )
      }
    }
    .padding(
      20
    )
    .background(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(AppTheme.cardGradient)
        .shadow(color: AppTheme.shadow, radius: 15, y: 7)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .stroke(Color.white.opacity(0.72), lineWidth: 1)
    )
  }
}

// =========================================================
// MARK: - Legacy Recommendation Card
// =========================================================

struct JourneyCard: View {

  let recommendation: JourneyRecommendation

  let onComplete: () -> Void

  var body: some View {

    VStack(
      alignment: .leading,
      spacing: 16
    ) {

      Text(
        recommendation
          .title
      )
      .font(
        .title2
      )
      .bold()

      Text(
        recommendation
          .reason
      )
      .foregroundStyle(AppTheme.textSecondary)

      if !recommendation
        .passage
        .isEmpty
      {

        HStack {

          Image(
            systemName:
              "book.closed.fill"
          )

          Text(
            recommendation
              .passage
          )
          .fontWeight(
            .semibold
          )
        }
      }

      if !recommendation
        .suggestedQuestion
        .isEmpty
      {

        VStack(
          alignment: .leading,
          spacing: 5
        ) {

          Text(
            "Consider"
          )
          .font(
            .caption
          )
          .foregroundStyle(AppTheme.textSecondary)

          Text(
            recommendation
              .suggestedQuestion
          )
          .font(
            .subheadline
          )
        }
      }

      NavigationLink {

        JourneyStudyView(
          recommendation:
            recommendation,
          onComplete:
            onComplete
        )

      } label: {

        Text(
          recommendation
            .actionTitle
        )
        .fontWeight(
          .semibold
        )
        .frame(
          maxWidth:
            .infinity
        )
        .padding(
          .vertical,
          14
        )
      }
      .buttonStyle(
        .borderedProminent
      )
      .foregroundStyle(Color.white)
    }
    .padding(
      20
    )
    .background(

      RoundedRectangle(
        cornerRadius:
          22
      )
      .fill(
        AppTheme.surface
      )
    )
  }
}

// =========================================================
// MARK: - No Active Personalized Path
// =========================================================

private struct NoActivePersonalizedPathCard: View {

  @EnvironmentObject
  private var onboardingViewModel: OnboardingViewModel

  let hasPastJourneys: Bool

  let onPathChanged: () -> Void

  var body: some View {

    VStack(
      alignment: .leading,
      spacing: 14
    ) {

      Image(
        systemName:
          hasPastJourneys
          ? "checkmark.circle"
          : "map"
      )
      .font(
        .title2
      )
      .foregroundStyle(
        AppTheme.accent
      )

      Text(
        hasPastJourneys
          ? "No active path right now"
          : "Choose a personalized path"
      )
      .font(
        .headline
      )

      Text(
        hasPastJourneys
          ? "Your previous paths and progress are still saved."
          : "Choose something you'd like to work through and build a focused Scripture path."
      )
      .font(
        .subheadline
      )
      .foregroundStyle(AppTheme.textSecondary)

      NavigationLink {

        ChangePathView(
          onPathChanged:
            onPathChanged
        )
        .environmentObject(
          onboardingViewModel
        )

      } label: {

        HStack {

          Text(
            "Choose a Path"
          )
          .fontWeight(
            .semibold
          )

          Spacer()

          Image(
            systemName:
              "arrow.right"
          )
        }
        .frame(
          maxWidth:
            .infinity
        )
        .padding(
          .vertical,
          13
        )
      }
      .buttonStyle(
        .borderedProminent
      )
      .foregroundStyle(Color.white)
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
          22
      )
      .fill(
        AppTheme.surface
      )
    )
  }
}

// =========================================================
// MARK: - Home Option Row
// =========================================================

struct HomeOptionRow: View {

  let title: String

  let subtitle: String

  let icon: String

  var usesCompanionAvatar =
    false

  var body: some View {

    HStack(
      spacing: 16
    ) {

      if usesCompanionAvatar {

        CompanionAvatar(
          size: 40
        )
        .frame(
          width: 36
        )

      } else {

        CloudIconTile(
          systemName: icon,
          tint: AppTheme.accentDeep,
          size: 42
        )
      }

      VStack(
        alignment: .leading,
        spacing: 4
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
    .padding(14)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(AppTheme.surfaceStrong)
        .shadow(color: AppTheme.shadow, radius: 9, y: 4)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .stroke(Color.white.opacity(0.72), lineWidth: 1)
    )
  }
}

// =========================================================
// MARK: - Preview
// =========================================================

#Preview {

  NavigationStack {

    HomeView()
      .environmentObject(
        OnboardingViewModel()
      )
      .environmentObject(
        AppTutorialCoordinator()
      )
  }
}
