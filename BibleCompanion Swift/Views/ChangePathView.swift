import SwiftUI


struct ChangePathView: View {

    // =====================================================
    // MARK: - Environment
    // =====================================================

    @Environment(\.dismiss)
    private var dismiss


    @EnvironmentObject
    private var onboardingViewModel:
        OnboardingViewModel


    @EnvironmentObject
    private var appTutorial:
        AppTutorialCoordinator


    // =====================================================
    // MARK: - View Models
    // =====================================================

    @StateObject
    private var viewModel =
        HomeViewModel()


    @StateObject
    private var progressStore =
        JourneyProgressStore.shared


    // =====================================================
    // MARK: - State
    // =====================================================

    @State
    private var journeyToResume:
        PersonalizedJourneyRecord?


    // =====================================================
    // MARK: - Callback
    // =====================================================

    let onPathChanged:
        () -> Void


    init(
        onPathChanged:
            @escaping () -> Void = {}
    ) {

        self.onPathChanged =
            onPathChanged
    }


    // =====================================================
    // MARK: - Body
    // =====================================================

    var body: some View {

        ScrollViewReader { scrollProxy in

            ScrollView {

            VStack(
                alignment:
                    .leading,
                spacing:
                    28
            ) {

                // =================================================
                // MARK: Header
                // =================================================

                VStack(
                    alignment:
                        .leading,
                    spacing:
                        8
                ) {

                    Text(
                        "Change Path"
                    )
                    .font(
                        .largeTitle
                    )
                    .bold()


                    Text(
                        "Choose something new to work through, or return to a path you've already started."
                    )
                    .font(
                        .body
                    )
                    .foregroundStyle(AppTheme.textSecondary)
                }


                // =================================================
                // MARK: Current Path
                // =================================================

                if let activeJourney =
                    viewModel
                        .activePersonalizedJourney {

                    currentPathCard(
                        journey:
                            activeJourney
                    )

                } else {

                    noCurrentPathCard
                }


                // =================================================
                // MARK: Progress Preservation Message
                // =================================================

                HStack(
                    alignment:
                        .top,
                    spacing:
                        12
                ) {

                    Image(
                        systemName:
                            "bookmark.fill"
                    )
                    .foregroundStyle(
                        AppTheme.accent
                    )


                    Text(
                        "Changing your path won't erase your progress. Your current path will be saved so you can return to it later."
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
                        AppTheme.surface
                    )
                )


                // =================================================
                // MARK: Choose Method Header
                // =================================================

                VStack(
                    alignment:
                        .leading,
                    spacing:
                        6
                ) {

                    Text(
                        "Choose a New Focus"
                    )
                    .font(
                        .title2
                    )
                    .bold()


                    Text(
                        "You can choose directly or talk it through first."
                    )
                    .font(
                        .subheadline
                    )
                    .foregroundStyle(AppTheme.textSecondary)
                }


                // =================================================
                // MARK: Change Path Methods
                // =================================================

                VStack(
                    spacing:
                        14
                ) {

                    // =============================================
                    // Guided Questionnaire
                    // =============================================

                    NavigationLink {

                        GuidedPathSetupView(
                            onPathChanged: {

                                refresh()

                                onPathChanged()
                            }
                        )
                        .environmentObject(
                            onboardingViewModel
                        )

                    } label: {

                        ChangePathMethodCard(
                            icon:
                                "list.bullet.clipboard",
                            title:
                                "Guided Questionnaire",
                            subtitle:
                                "Choose a topic, tell us what tends to bring it up, and what you want to grow in.",
                            detail:
                                "Best if you already know what you want to work on."
                        )
                    }
                    .buttonStyle(
                        .plain
                    )


                    // =============================================
                    // Talk It Through
                    // =============================================

                    NavigationLink {

                        TalkItThroughPathView(
                            onPathChanged: {

                                // Refresh Change Path screen
                                // after the user approves a path.

                                refresh()


                                // Refresh HomeView as well.

                                onPathChanged()
                            }
                        )
                        .environmentObject(
                            onboardingViewModel
                        )

                    } label: {

                        ChangePathMethodCard(
                            icon:
                                "bubble.left.and.bubble.right.fill",
                            title:
                                "Talk It Through",
                            subtitle:
                                "Talk with Companion about what's going on before deciding what your next path should focus on.",
                            detail:
                                "Best if you're not quite sure how to describe it yet.",
                            usesCompanionAvatar:
                                true
                        )
                    }
                    .buttonStyle(
                        .plain
                    )
                }


                .appTutorialChangePathTarget(
                    .methods
                )


                // =================================================
                // MARK: Past Paths
                // =================================================

                Divider()


                VStack(
                    alignment:
                        .leading,
                    spacing:
                        6
                ) {

                    Text(
                        "Past Paths"
                    )
                    .font(
                        .title2
                    )
                    .bold()


                    Text(
                        "Your previous progress stays saved."
                    )
                    .font(
                        .subheadline
                    )
                    .foregroundStyle(AppTheme.textSecondary)
                }
                .appTutorialChangePathTarget(
                    .pastPaths
                )


                if viewModel
                    .pastPersonalizedJourneys
                    .isEmpty {

                    emptyPastPathsCard

                } else {

                    VStack(
                        spacing:
                            14
                    ) {

                        ForEach(
                            viewModel
                                .pastPersonalizedJourneys
                        ) { record in

                            pastPathCard(
                                record:
                                    record
                            )
                        }
                    }
                }


                Spacer(
                    minLength:
                        30
                )
            }
            .padding()
        }
        .overlayPreferenceValue(
            AppTutorialChangePathTargetPreferenceKey.self
        ) { anchors in

            if appTutorial.isActive,
               isChangePathTutorialStep(
                appTutorial.step
               ) {

                AppCoachMarkOverlay(
                    step:
                        appTutorial.step,
                    targetAnchor:
                        changePathTutorialAnchor(
                            anchors:
                                anchors
                        ),
                    onBack: {

                        handleChangePathTutorialBack(
                            scrollProxy:
                                scrollProxy
                        )
                    },
                    onPrimary: {

                        handleChangePathTutorialPrimary(
                            scrollProxy:
                                scrollProxy
                        )
                    },
                    onSkip: {

                        appTutorial.finish()
                    }
                )
            }
        }
        .cloudScreen()
        .navigationTitle(
            "Change Path"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .onAppear {

            refresh()


            if appTutorial.isActive {

                scrollToChangePathTutorialStep(
                    appTutorial.step,
                    scrollProxy:
                        scrollProxy,
                    animated:
                        false
                )
            }
        }
        .onChange(
            of:
                appTutorial.step
        ) { _, newStep in

            guard appTutorial.isActive else {
                return
            }

            scrollToChangePathTutorialStep(
                newStep,
                scrollProxy:
                    scrollProxy
            )
        }
        .alert(
            "Resume this path?",
            item:
                $journeyToResume
        ) { record in

            Button(
                "Cancel",
                role:
                    .cancel
            ) {}


            Button(
                "Resume Path"
            ) {

                resume(
                    record
                )
            }

        } message: { record in

            Text(
                "Your current path will be paused, not deleted. You'll return to \(record.journey.title) where you left off."
            )
        }
        }
    }


    // =====================================================
    // MARK: - Tutorial
    // =====================================================

    private func isChangePathTutorialStep(
        _ step:
            GuidedAppTutorialStep
    ) -> Bool {

        step == .changeMethods
        ||
        step == .pastPaths
    }


    private func changePathTutorialAnchor(
        anchors:
            [AppTutorialChangePathTarget: Anchor<CGRect>]
    ) -> Anchor<CGRect>? {

        switch appTutorial.step {

        case .changeMethods:
            return anchors[.methods]

        case .pastPaths:
            return anchors[.pastPaths]

        default:
            return nil
        }
    }


    private func scrollToChangePathTutorialStep(
        _ step:
            GuidedAppTutorialStep,
        scrollProxy:
            ScrollViewProxy,
        animated:
            Bool = true
    ) {

        let target:
            AppTutorialChangePathTarget?


        switch step {

        case .changeMethods:
            target = .methods

        case .pastPaths:
            target = .pastPaths

        default:
            target = nil
        }


        guard let target else {
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


    private func handleChangePathTutorialPrimary(
        scrollProxy:
            ScrollViewProxy
    ) {

        switch appTutorial.step {

        case .changeMethods:

            scrollToChangePathTutorialStep(
                .pastPaths,
                scrollProxy:
                    scrollProxy
            )


            DispatchQueue.main.asyncAfter(
                deadline:
                    .now() + 0.25
            ) {

                appTutorial.move(
                    to:
                        .pastPaths
                )
            }

        case .pastPaths:

            appTutorial.move(
                to:
                    .scripture
            )

            dismiss()

        default:
            break
        }
    }


    private func handleChangePathTutorialBack(
        scrollProxy:
            ScrollViewProxy
    ) {

        switch appTutorial.step {

        case .changeMethods:

            appTutorial.move(
                to:
                    .changePath
            )

            dismiss()

        case .pastPaths:

            appTutorial.move(
                to:
                    .changeMethods
            )

            scrollToChangePathTutorialStep(
                .changeMethods,
                scrollProxy:
                    scrollProxy
            )

        default:
            break
        }
    }


    // =====================================================
    // MARK: - Current Path Card
    // =====================================================

    @ViewBuilder
    private func currentPathCard(
        journey:
            JourneyPath
    ) -> some View {

        let completed =
            progressStore
                .completedCount(
                    in:
                        journey
                )


        let total =
            journey
                .checkpoints
                .count


        let progress =
            progressStore
                .progress(
                    in:
                        journey
                )


        VStack(
            alignment:
                .leading,
            spacing:
                14
        ) {

            Text(
                "CURRENT PATH"
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


            if let focus =
                journey
                    .focus?
                    .label
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    ),
               !focus.isEmpty {

                Text(
                    focus
                )
                .font(
                    .subheadline
                )
                .foregroundStyle(AppTheme.textSecondary)
            }


            HStack {

                Text(
                    "\(completed) of \(total) checkpoints"
                )
                .font(
                    .subheadline
                )
                .fontWeight(
                    .semibold
                )


                Spacer()


                Text(
                    "\(Int(progress * 100))%"
                )
                .font(
                    .subheadline
                )
                .foregroundStyle(AppTheme.textSecondary)
            }


            ProgressView(
                value:
                    progress
            )
            .tint(AppTheme.accent)


            if let checkpoint =
                progressStore
                    .currentCheckpoint(
                        in:
                            journey
                    ) {

                VStack(
                    alignment:
                        .leading,
                    spacing:
                        5
                ) {

                    Text(
                        "CURRENTLY ON"
                    )
                    .font(
                        .caption2
                    )
                    .fontWeight(
                        .bold
                    )
                    .foregroundStyle(AppTheme.textSecondary)


                    Text(
                        checkpoint.title
                    )
                    .font(
                        .headline
                    )


                    Label(
                        checkpoint.passage,
                        systemImage:
                            "book.closed.fill"
                    )
                    .font(
                        .subheadline
                    )
                    .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(
                    .top,
                    4
                )

            } else {

                Label(
                    "All checkpoints completed",
                    systemImage:
                        "checkmark.seal.fill"
                )
                .font(
                    .subheadline
                )
                .fontWeight(
                    .semibold
                )
                .foregroundStyle(
                    AppTheme.accent
                )
            }


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
                        "View Current Path"
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
                    .top,
                    4
                )
            }
            .buttonStyle(
                .plain
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
                    22
            )
            .fill(
                AppTheme.accent
                    .opacity(
                        0.08
                    )
            )
        )
    }


    // =====================================================
    // MARK: - No Current Path Card
    // =====================================================

    private var noCurrentPathCard:
        some View {

        VStack(
            alignment:
                .leading,
            spacing:
                10
        ) {

            Text(
                "NO ACTIVE PATH"
            )
            .font(
                .caption
            )
            .fontWeight(
                .bold
            )
            .foregroundStyle(AppTheme.textSecondary)


            Text(
                "Choose what you want to work through next."
            )
            .font(
                .headline
            )


            Text(
                "Your previous journeys and their progress are still saved below."
            )
            .font(
                .subheadline
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
                    18
            )
            .fill(
                AppTheme.surface
            )
        )
    }


    // =====================================================
    // MARK: - Past Path Card
    // =====================================================

    @ViewBuilder
    private func pastPathCard(
        record:
            PersonalizedJourneyRecord
    ) -> some View {

        let journey =
            record.journey


        let completed =
            progressStore
                .completedCount(
                    in:
                        journey
                )


        let total =
            journey
                .checkpoints
                .count


        let progress =
            progressStore
                .progress(
                    in:
                        journey
                )


        VStack(
            alignment:
                .leading,
            spacing:
                14
        ) {

            // =================================================
            // MARK: Header
            // =================================================

            HStack(
                alignment:
                    .top
            ) {

                VStack(
                    alignment:
                        .leading,
                    spacing:
                        5
                ) {

                    Text(
                        statusText(
                            for:
                                record
                        )
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
                        .headline
                    )


                    if let focus =
                        journey
                            .focus?
                            .label
                            .trimmingCharacters(
                                in:
                                    .whitespacesAndNewlines
                            ),
                       !focus.isEmpty {

                        Text(
                            focus
                        )
                        .font(
                            .caption
                        )
                        .foregroundStyle(AppTheme.textSecondary)
                    }
                }


                Spacer()


                VStack(
                    alignment:
                        .trailing,
                    spacing:
                        3
                ) {

                    Text(
                        "\(completed)/\(total)"
                    )
                    .font(
                        .subheadline
                    )
                    .fontWeight(
                        .semibold
                    )


                    Text(
                        "\(Int(progress * 100))%"
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(AppTheme.textSecondary)
                }
            }


            ProgressView(
                value:
                    progress
            )
            .tint(AppTheme.accent)


            // =================================================
            // MARK: Date
            // =================================================

            Text(
                dateText(
                    for:
                        record
                )
            )
            .font(
                .caption
            )
            .foregroundStyle(AppTheme.textSecondary)


            Divider()


            // =================================================
            // MARK: Actions
            // =================================================

            HStack(
                spacing:
                    16
            ) {

                NavigationLink {

                    JourneyMapView(
                        journey:
                            journey
                    )

                } label: {

                    Label(
                        "Review",
                        systemImage:
                            "book.open"
                    )
                    .font(
                        .subheadline
                    )
                    .fontWeight(
                        .semibold
                    )
                }


                Spacer()


                if record.status
                    ==
                    .paused {

                    Button {

                        journeyToResume =
                            record

                    } label: {

                        Label(
                            "Resume",
                            systemImage:
                                "arrow.counterclockwise"
                        )
                        .font(
                            .subheadline
                        )
                        .fontWeight(
                            .semibold
                        )
                    }
                }


                if record.status
                    ==
                    .completed {

                    Button {

                        journeyToResume =
                            record

                    } label: {

                        Label(
                            "Work On Again",
                            systemImage:
                                "arrow.counterclockwise"
                        )
                        .font(
                            .subheadline
                        )
                        .fontWeight(
                            .semibold
                        )
                    }
                }
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
                    18
            )
            .fill(
                AppTheme.surface
            )
        )
    }


    // =====================================================
    // MARK: - Empty Past Paths
    // =====================================================

    private var emptyPastPathsCard:
        some View {

        VStack(
            alignment:
                .leading,
            spacing:
                10
        ) {

            Image(
                systemName:
                    "clock.arrow.circlepath"
            )
            .font(
                .title2
            )
            .foregroundStyle(AppTheme.textSecondary)


            Text(
                "No previous paths yet"
            )
            .font(
                .headline
            )


            Text(
                "When you change topics, your previous paths will appear here so you can review or resume them."
            )
            .font(
                .subheadline
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
                    18
            )
            .fill(
                AppTheme.surface
            )
        )
    }


    // =====================================================
    // MARK: - Resume Path
    // =====================================================

    private func resume(
        _ record:
            PersonalizedJourneyRecord
    ) {

        viewModel
            .resumePersonalizedJourney(
                journeyID:
                    record.id
            )


        refresh()


        onPathChanged()


        dismiss()
    }


    // =====================================================
    // MARK: - Refresh
    // =====================================================

    private func refresh() {

        viewModel
            .loadPersonalizedJourneyState()


        viewModel
            .refreshPastJourneys()
    }


    // =====================================================
    // MARK: - Status
    // =====================================================

    private func statusText(
        for record:
            PersonalizedJourneyRecord
    ) -> String {

        switch record.status {

        case .active:

            return
                "ACTIVE"


        case .paused:

            return
                "PAUSED"


        case .completed:

            return
                "COMPLETED"
        }
    }


    // =====================================================
    // MARK: - Date
    // =====================================================

    private func dateText(
        for record:
            PersonalizedJourneyRecord
    ) -> String {

        switch record.status {

        case .active:

            return
                "Updated \(formattedDate(record.lastUpdatedAt))"


        case .paused:

            return
                "Paused \(formattedDate(record.endedAt ?? record.lastUpdatedAt))"


        case .completed:

            return
                "Completed \(formattedDate(record.endedAt ?? record.lastUpdatedAt))"
        }
    }


    private func formattedDate(
        _ date:
            Date
    ) -> String {

        date.formatted(
            date:
                .abbreviated,
            time:
                .omitted
        )
    }
}


// =========================================================
// MARK: - Change Path Method Card
// =========================================================

private struct ChangePathMethodCard:
    View {

    let icon:
        String


    let title:
        String


    let subtitle:
        String


    let detail:
        String


    var usesCompanionAvatar =
        false


    var body: some View {

        HStack(
            alignment:
                .top,
            spacing:
                16
        ) {

            ZStack {

                RoundedRectangle(
                    cornerRadius:
                        14
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


                if usesCompanionAvatar {

                    CompanionAvatar(
                        size: 48
                    )

                } else {

                    Image(
                        systemName:
                            icon
                    )
                    .font(
                        .title3
                    )
                    .foregroundStyle(
                        AppTheme.accent
                    )
                }
            }


            VStack(
                alignment:
                    .leading,
                spacing:
                    6
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


                Text(
                    detail
                )
                .font(
                    .caption
                )
                .foregroundStyle(AppTheme.textSecondary)
                .padding(
                    .top,
                    2
                )
            }


            Spacer()


            Image(
                systemName:
                    "chevron.right"
            )
            .font(
                .subheadline
            )
            .foregroundStyle(AppTheme.textSecondary)
            .padding(
                .top,
                4
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
}


// =========================================================
// MARK: - Preview
// =========================================================

#Preview {

    NavigationStack {

        ChangePathView()
            .environmentObject(
                OnboardingViewModel()
            )
            .environmentObject(
                AppTutorialCoordinator()
            )
    }
}
