//
//  GuidedPathSetupView.swift
//  BibleCompanion Swift
//
//  Created by Shopify on 10/2/26.
//

import SwiftUI


struct GuidedPathSetupView: View {

    // =====================================================
    // MARK: - Environment
    // =====================================================

    @Environment(\.dismiss)
    private var dismiss


    @EnvironmentObject
    private var onboardingViewModel:
        OnboardingViewModel


    // =====================================================
    // MARK: - Services
    // =====================================================

    private let storageService =
        StorageService.shared


    private let journeyService =
        JourneyService.shared


    private let studyHistoryService =
        StudyHistoryService.shared


    private let struggleAnalysisService =
        StruggleAnalysisService.shared


    private let personalizationContextService =
        PersonalizationContextService.shared


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
    // MARK: - Flow State
    // =====================================================

    @State
    private var step =
        0


    @State
    private var selectedCategory =
        ""


    @State
    private var customText =
        ""


    @State
    private var analyzedCategory =
        ""


    @State
    private var analyzedLabel =
        ""


    @State
    private var analyzedSummary =
        ""


    @State
    private var selectedTrigger =
        ""


    @State
    private var selectedGoal =
        ""


    // =====================================================
    // MARK: - Generation State
    // =====================================================

    @State
    private var proposedPath:
        JourneyPath?


    @State
    private var isAnalyzing =
        false


    @State
    private var isBuildingPath =
        false


    @State
    private var errorMessage:
        String?


    // =====================================================
    // MARK: - Categories
    // =====================================================

    private let categories = [

        "Anger",

        "Forgiveness",

        "Temptation",

        "Doubt",

        "Relationships",

        "Prayer and consistency",

        "Fear or worry",

        "Loneliness",

        "Grief or loss",

        "Purpose or direction",

        "Habits and self-control",

        "Something else"
    ]


    // =====================================================
    // MARK: - Body
    // =====================================================

    var body: some View {

        VStack(
            spacing: 0
        ) {

            // =================================================
            // MARK: Progress Header
            // =================================================

            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                HStack {

                    Text(
                        headerTitle
                    )
                    .font(
                        .title2
                    )
                    .bold()


                    Spacer()


                    if step < 3 {

                        Text(
                            "\(step + 1) of 3"
                        )
                        .font(
                            .subheadline
                        )
                        .foregroundStyle(AppTheme.textSecondary)
                    }
                }


                if step < 3 {

                    ProgressView(
                        value:
                            Double(
                                step + 1
                            ),
                        total:
                            3
                    )
                    .tint(AppTheme.accent)
                }
            }
            .padding()
            .background(
                AppTheme.surfaceStrong
            )


            Divider()


            // =================================================
            // MARK: Content
            // =================================================

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 24
                ) {

                    switch step {

                    case 0:

                        topicStep


                    case 1:

                        triggerStep


                    case 2:

                        goalStep


                    default:

                        reviewStep
                    }


                    Spacer(
                        minLength: 30
                    )
                }
                .padding()
            }


            // =================================================
            // MARK: Bottom Action
            // =================================================

            if step < 3 {

                Divider()


                bottomAction
                    .padding()
                    .background(
                        .ultraThinMaterial
                    )
            }
        }
        .cloudScreen()
        .navigationTitle(
            "Guided Path"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .navigationBarBackButtonHidden(
            isAnalyzing
            ||
            isBuildingPath
        )
    }


    // =====================================================
    // MARK: - Topic Step
    // =====================================================

    private var topicStep:
        some View {

        VStack(
            alignment: .leading,
            spacing: 20
        ) {

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                Text(
                    "What do you want to work through?"
                )
                .font(
                    .largeTitle
                )
                .bold()


                Text(
                    "Choose the topic that feels closest. You can change paths anytime."
                )
                .foregroundStyle(AppTheme.textSecondary)
            }


            VStack(
                spacing: 12
            ) {

                ForEach(
                    categories,
                    id:
                        \.self
                ) { category in

                    Button {

                        selectCategory(
                            category
                        )

                    } label: {

                        selectionRow(
                            title:
                                category,
                            selected:
                                selectedCategory
                                ==
                                category
                        )
                    }
                    .buttonStyle(
                        .plain
                    )
                }
            }


            if selectedCategory
                ==
                "Something else" {

                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {

                    Text(
                        "Tell us what's been going on"
                    )
                    .font(
                        .headline
                    )


                    TextEditor(
                        text:
                            $customText
                    )
                    .frame(
                        minHeight:
                            130
                    )
                    .padding(
                        10
                    )
                    .background(

                        RoundedRectangle(
                            cornerRadius:
                                14
                        )
                        .fill(
                            AppTheme.surface
                        )
                    )
                    .overlay(

                        RoundedRectangle(
                            cornerRadius:
                                14
                        )
                        .stroke(
                            AppTheme.textSecondary
                                .opacity(
                                    0.15
                                )
                        )
                    )


                    Text(
                        "Use your own words. Your original wording will be preserved."
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(
                    .top,
                    8
                )
            }


            if let errorMessage {

                errorCard(
                    errorMessage
                )
            }
        }
    }


    // =====================================================
    // MARK: - Trigger Step
    // =====================================================

    private var triggerStep:
        some View {

        VStack(
            alignment: .leading,
            spacing: 20
        ) {

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                Text(
                    "When does this come up most?"
                )
                .font(
                    .largeTitle
                )
                .bold()


                Text(
                    "This helps shape the path around the situations you're actually facing."
                )
                .foregroundStyle(AppTheme.textSecondary)
            }


            if !displayFocusLabel
                .isEmpty {

                focusPill(
                    displayFocusLabel
                )
            }


            VStack(
                spacing: 12
            ) {

                ForEach(
                    triggerOptions,
                    id:
                        \.self
                ) { option in

                    Button {

                        selectedTrigger =
                            option

                    } label: {

                        selectionRow(
                            title:
                                option,
                            selected:
                                selectedTrigger
                                ==
                                option
                        )
                    }
                    .buttonStyle(
                        .plain
                    )
                }
            }
        }
    }


    // =====================================================
    // MARK: - Goal Step
    // =====================================================

    private var goalStep:
        some View {

        VStack(
            alignment: .leading,
            spacing: 20
        ) {

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                Text(
                    "What would growth look like?"
                )
                .font(
                    .largeTitle
                )
                .bold()


                Text(
                    "Choose what you'd most like Scripture to help you understand or change."
                )
                .foregroundStyle(AppTheme.textSecondary)
            }


            if !displayFocusLabel
                .isEmpty {

                focusPill(
                    displayFocusLabel
                )
            }


            VStack(
                spacing: 12
            ) {

                ForEach(
                    growthOptions,
                    id:
                        \.self
                ) { option in

                    Button {

                        selectedGoal =
                            option

                    } label: {

                        selectionRow(
                            title:
                                option,
                            selected:
                                selectedGoal
                                ==
                                option
                        )
                    }
                    .buttonStyle(
                        .plain
                    )
                }
            }


            if let errorMessage {

                errorCard(
                    errorMessage
                )
            }
        }
    }


    // =====================================================
    // MARK: - Review Step
    // =====================================================

    private var reviewStep:
        some View {

        VStack(
            alignment: .leading,
            spacing: 24
        ) {

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                Text(
                    proposedPath == nil
                    ? "Building your path..."
                    : "Your path is ready"
                )
                .font(
                    .largeTitle
                )
                .bold()


                Text(
                    proposedPath == nil
                    ? "Choosing Scripture and checkpoints around what you shared."
                    : "Nothing changes until you choose Use This Path."
                )
                .foregroundStyle(AppTheme.textSecondary)
            }


            if isBuildingPath {

                buildingPathCard
            }


            if let path =
                proposedPath {

                proposedPathCard(
                    path
                )


                Button {

                    useProposedPath(
                        path
                    )

                } label: {

                    Text(
                        "Use This Path"
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
                        15
                    )
                }
                .buttonStyle(
                    .borderedProminent
                )


                Button {

                    withAnimation {

                        proposedPath =
                            nil

                        step =
                            0
                    }

                } label: {

                    Text(
                        "Choose Something Else"
                    )
                    .fontWeight(
                        .semibold
                    )
                    .frame(
                        maxWidth:
                            .infinity
                    )
                }
                .buttonStyle(
                    .borderless
                )
            }


            if let errorMessage {

                errorCard(
                    errorMessage
                )


                Button(
                    "Try Again"
                ) {

                    Task {

                        await buildProposedPath()
                    }
                }
                .buttonStyle(
                    .borderedProminent
                )
            }
        }
        .task {

            if proposedPath == nil,
               !isBuildingPath,
               errorMessage == nil {

                await buildProposedPath()
            }
        }
    }


    // =====================================================
    // MARK: - Bottom Action
    // =====================================================

    private var bottomAction:
        some View {

        Button {

            Task {

                await continueForward()
            }

        } label: {

            HStack {

                if isAnalyzing {

                    ProgressView()
                        .tint(
                            .white
                        )


                    Text(
                        "Understanding..."
                    )

                } else {

                    Text(
                        step == 2
                        ? "Build My Path"
                        : "Continue"
                    )


                    Spacer()


                    Image(
                        systemName:
                            "arrow.right"
                    )
                }
            }
            .fontWeight(
                .semibold
            )
            .frame(
                maxWidth:
                    .infinity
            )
            .padding(
                .vertical,
                15
            )
        }
        .buttonStyle(
            .borderedProminent
        )
        .disabled(
            !canContinue
            ||
            isAnalyzing
        )
        .opacity(
            canContinue
            ? 1
            : 0.5
        )
    }


    // =====================================================
    // MARK: - Continue
    // =====================================================

    @MainActor
    private func continueForward()
        async {

        errorMessage =
            nil


        switch step {

        case 0:

            if selectedCategory
                ==
                "Something else" {

                await analyzeCustomTopic()

            } else {

                analyzedCategory =
                    ""

                analyzedLabel =
                    selectedCategory

                analyzedSummary =
                    ""

                selectedTrigger =
                    ""

                selectedGoal =
                    ""

                withAnimation {

                    step =
                        1
                }
            }


        case 1:

            withAnimation {

                step =
                    2
            }


        case 2:

            proposedPath =
                nil

            withAnimation {

                step =
                    3
            }


        default:

            break
        }
    }


    // =====================================================
    // MARK: - Custom Analysis
    // =====================================================

    @MainActor
    private func analyzeCustomTopic()
        async {

        let text =
            customText
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        guard !text.isEmpty else {

            errorMessage =
                "Tell us a little about what you want to work through."

            return
        }


        isAnalyzing =
            true


        defer {

            isAnalyzing =
                false
        }


        do {

            let analysis =
                try await
                struggleAnalysisService
                    .analyze(
                        text:
                            text
                    )


            analyzedCategory =
                analysis.category


            analyzedLabel =
                analysis.label


            analyzedSummary =
                analysis.summary


            selectedTrigger =
                ""


            selectedGoal =
                ""


            withAnimation {

                step =
                    1
            }

        } catch {

            errorMessage =
                error
                    .localizedDescription
        }
    }


    // =====================================================
    // MARK: - Build Proposed Path
    // =====================================================

    @MainActor
    private func buildProposedPath()
        async {

        guard
            let focus =
                journeyFocus
        else {

            errorMessage =
                "We couldn't determine the focus for this path."

            return
        }


        isBuildingPath =
            true


        errorMessage =
            nil


        defer {

            isBuildingPath =
                false
        }


        // -------------------------------------------------
        // Curated Path
        // -------------------------------------------------

        if let curated =
            JourneyLibrary
                .personalizedPath(
                    for:
                        focus
                ) {

            // Small delay so the transition feels
            // intentional rather than flashing instantly.

            try? await Task.sleep(
                nanoseconds:
                    450_000_000
            )


            proposedPath =
                curated


            return
        }


        // -------------------------------------------------
        // Custom AI Path
        // -------------------------------------------------

        do {

            let history =
                studyHistoryService
                    .loadActivities()


            let recentActivity =
                Array(
                    history
                        .prefix(
                            10
                        )
                )


            // -------------------------------------------------
            // Shared Personalization Context
            // -------------------------------------------------
            //
            // The confirmed focus remains authoritative for this
            // new path. Existing Journey/reflection/history context
            // is supporting background only.

            let activeJourney =
                storageService
                    .loadActivePersonalizedPath()


            let pastJourneys =
                storageService
                    .loadPastPersonalizedJourneys()


            let personalizationContext =
                personalizationContextService
                    .buildContext(
                        profile:
                            updatedProfileSnapshot,
                        activeJourney:
                            activeJourney,
                        pastJourneys:
                            pastJourneys,
                        purpose:
                            .journeyGeneration,
                        currentPassage:
                            "",
                        currentMessage:
                            pathGenerationContextMessage(
                                focus
                            )
                    )


            let generated =
                try await
                journeyService
                    .generateCustomPath(
                        profile:
                            updatedProfileSnapshot,
                        focus:
                            focus,
                        recentActivity:
                            recentActivity,
                        personalizationContext:
                            personalizationContext
                    )


            proposedPath =
                generated

        } catch {

            errorMessage =
                error
                    .localizedDescription
        }
    }


    // =====================================================
    // MARK: - Path Generation Context Message
    // =====================================================

    private func pathGenerationContextMessage(
        _ focus:
            JourneyFocus
    ) -> String {

        var pieces = [
            "Build a personalized Scripture journey for \(focus.label)."
        ]


        if let originalText =
            focus.originalText?
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                ),
           !originalText.isEmpty {

            pieces.append(
                "The user described the focus as: \(originalText)"
            )
        }


        if let trigger =
            focus.trigger?
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                ),
           !trigger.isEmpty {

            pieces.append(
                "The issue tends to show up around: \(trigger)"
            )
        }


        if let goal =
            focus.goal?
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                ),
           !goal.isEmpty {

            pieces.append(
                "The user's stated growth goal is: \(goal)"
            )
        }


        return pieces
            .joined(
                separator:
                    " "
            )
    }


    // =====================================================
    // MARK: - Use Path
    // =====================================================

    @MainActor
    private func useProposedPath(
        _ path: JourneyPath
    ) {

        // -------------------------------------------------
        // Update Profile Only Now
        // -------------------------------------------------
        //
        // Merely browsing the Change Path flow should not
        // mutate the person's saved profile.

        var updatedProfile =
            onboardingViewModel
                .profile


        updatedProfile
            .struggleCategory =
            selectedCategory


        updatedProfile
            .customStruggleText =
            selectedCategory
            ==
            "Something else"
            ? customText
            : ""


        updatedProfile
            .analyzedStruggleCategory =
            selectedCategory
            ==
            "Something else"
            ? analyzedCategory
            : ""


        updatedProfile
            .struggleLabel =
            displayFocusLabel


        updatedProfile
            .struggleSummary =
            selectedCategory
            ==
            "Something else"
            ? analyzedSummary
            : ""


        updatedProfile
            .struggleTrigger =
            selectedTrigger


        updatedProfile
            .struggleGoal =
            selectedGoal


        onboardingViewModel
            .profile =
            updatedProfile


        onboardingViewModel
            .saveProfile()


        // -------------------------------------------------
        // Activate New Path
        // -------------------------------------------------

        storageService
            .activatePersonalizedJourney(
                path
            )


        storageService
            .clearJourneyRecommendation()


        onPathChanged()


        dismiss()
    }


    // =====================================================
    // MARK: - Journey Focus
    // =====================================================

    private var journeyFocus:
        JourneyFocus? {

        let category =
            normalizedCategory


        guard
            !category.isEmpty,
            !displayFocusLabel.isEmpty
        else {

            return nil
        }


        let originalText:
            String? = {

            guard
                selectedCategory
                ==
                "Something else"
            else {

                return nil
            }


            let value =
                customText
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )


            return value.isEmpty
            ? nil
            : value
        }()


        return JourneyFocus(

            category:
                category,

            label:
                displayFocusLabel,

            originalText:
                originalText,

            trigger:
                selectedTrigger,

            goal:
                selectedGoal
        )
    }


    // =====================================================
    // MARK: - Updated Profile Snapshot
    // =====================================================

    private var updatedProfileSnapshot:
        SpiritualProfile {

        var profile =
            onboardingViewModel
                .profile


        profile
            .struggleCategory =
            selectedCategory


        profile
            .customStruggleText =
            selectedCategory
            ==
            "Something else"
            ? customText
            : ""


        profile
            .analyzedStruggleCategory =
            selectedCategory
            ==
            "Something else"
            ? analyzedCategory
            : ""


        profile
            .struggleLabel =
            displayFocusLabel


        profile
            .struggleSummary =
            selectedCategory
            ==
            "Something else"
            ? analyzedSummary
            : ""


        profile
            .struggleTrigger =
            selectedTrigger


        profile
            .struggleGoal =
            selectedGoal


        return profile
    }


    // =====================================================
    // MARK: - Category Helpers
    // =====================================================

    private var sourceCategory:
        String {

        if selectedCategory
            ==
            "Something else" {

            return analyzedCategory
        }


        return selectedCategory
    }


    private var normalizedCategory:
        String {

        let cleaned =
            sourceCategory
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        switch cleaned
            .lowercased() {

        case "prayer and consistency",
             "prayer & consistency":

            return
                "Prayer"


        case "fear or worry",
             "fear and worry",
             "worry",
             "anxiety":

            return
                "Fear"


        case "grief or loss",
             "loss":

            return
                "Grief"


        case "purpose or direction",
             "direction",
             "calling":

            return
                "Purpose"


        case "habits and self-control",
             "habits and self control",
             "self control",
             "discipline":

            return
                "Self-control"


        default:

            return cleaned
        }
    }


    private var displayFocusLabel:
        String {

        if selectedCategory
            ==
            "Something else" {

            let label =
                analyzedLabel
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )


            if !label.isEmpty {

                return label
            }


            return customText
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
        }


        return selectedCategory
    }


    // =====================================================
    // MARK: - Adaptive Options
    // =====================================================

    private var triggerOptions:
        [String] {

        onboardingViewModel
            .triggerOptions(
                for:
                    questionnaireCategory
            )
    }


    private var growthOptions:
        [String] {

        onboardingViewModel
            .growthOptions(
                for:
                    questionnaireCategory
            )
    }


    private var questionnaireCategory:
        String {

        if selectedCategory
            ==
            "Something else" {

            return normalizedCategory
        }


        return selectedCategory
    }


    // =====================================================
    // MARK: - Validation
    // =====================================================

    private var canContinue:
        Bool {

        switch step {

        case 0:

            guard
                !selectedCategory
                    .isEmpty
            else {

                return false
            }


            if selectedCategory
                ==
                "Something else" {

                return
                    !customText
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        )
                        .isEmpty
            }


            return true


        case 1:

            return
                !selectedTrigger
                    .isEmpty


        case 2:

            return
                !selectedGoal
                    .isEmpty


        default:

            return false
        }
    }


    // =====================================================
    // MARK: - Select Category
    // =====================================================

    private func selectCategory(
        _ category: String
    ) {

        if selectedCategory
            !=
            category {

            selectedCategory =
                category


            customText =
                ""


            analyzedCategory =
                ""


            analyzedLabel =
                ""


            analyzedSummary =
                ""


            selectedTrigger =
                ""


            selectedGoal =
                ""


            proposedPath =
                nil


            errorMessage =
                nil
        }
    }


    // =====================================================
    // MARK: - Proposed Path Card
    // =====================================================

    @ViewBuilder
    private func proposedPathCard(
        _ path: JourneyPath
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            VStack(
                alignment: .leading,
                spacing: 6
            ) {

                Text(
                    "PROPOSED PATH"
                )
                .font(
                    .caption
                )
                .fontWeight(
                    .bold
                )
                .foregroundStyle(AppTheme.textSecondary)


                Text(
                    path.title
                )
                .font(
                    .title2
                )
                .bold()


                Text(
                    path.subtitle
                )
                .font(
                    .subheadline
                )
                .foregroundStyle(AppTheme.textSecondary)
            }


            Divider()


            ForEach(
                path.checkpoints
            ) { checkpoint in

                HStack(
                    alignment: .top,
                    spacing: 12
                ) {

                    ZStack {

                        Circle()
                            .fill(
                                AppTheme.accent
                                    .opacity(
                                        0.12
                                    )
                            )
                            .frame(
                                width:
                                    32,
                                height:
                                    32
                            )


                        Text(
                            "\(checkpoint.order)"
                        )
                        .font(
                            .caption
                        )
                        .fontWeight(
                            .bold
                        )
                        .foregroundStyle(
                            AppTheme.accent
                        )
                    }


                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {

                        Text(
                            checkpoint
                                .title
                        )
                        .font(
                            .headline
                        )


                        Text(
                            checkpoint
                                .passage
                        )
                        .font(
                            .caption
                        )
                        .foregroundStyle(AppTheme.textSecondary)


                        Text(
                            checkpoint
                                .subtitle
                        )
                        .font(
                            .subheadline
                        )
                        .foregroundStyle(AppTheme.textSecondary)
                    }


                    Spacer()
                }
            }
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


    // =====================================================
    // MARK: - Building Card
    // =====================================================

    private var buildingPathCard:
        some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            preparationRow(
                text:
                    "Understanding your focus",
                completed:
                    true
            )


            preparationRow(
                text:
                    "Choosing relevant Scripture",
                completed:
                    true
            )


            preparationRow(
                text:
                    "Preparing your checkpoints",
                completed:
                    false
            )
        }
        .padding(
            20
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


    @ViewBuilder
    private func preparationRow(
        text: String,
        completed: Bool
    ) -> some View {

        HStack(
            spacing: 12
        ) {

            if completed {

                Image(
                    systemName:
                        "checkmark.circle.fill"
                )
                .foregroundStyle(
                    AppTheme.accent
                )

            } else {

                ProgressView()
                    .controlSize(
                        .small
                    )
            }


            Text(
                text
            )
            .font(
                .subheadline
            )
        }
    }


    // =====================================================
    // MARK: - Selection Row
    // =====================================================

    @ViewBuilder
    private func selectionRow(
        title: String,
        selected: Bool
    ) -> some View {

        HStack(
            spacing: 14
        ) {

            Text(
                title
            )
            .multilineTextAlignment(
                .leading
            )


            Spacer()


            Image(
                systemName:
                    selected
                    ? "checkmark.circle.fill"
                    : "circle"
            )
            .foregroundStyle(
                selected
                ? AppTheme.accent
                : AppTheme.textSecondary
            )
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
                selected
                ? AppTheme.accent
                    .opacity(
                        0.09
                    )
                : AppTheme.surface
            )
        )
    }


    // =====================================================
    // MARK: - Focus Pill
    // =====================================================

    @ViewBuilder
    private func focusPill(
        _ title: String
    ) -> some View {

        HStack(
            spacing: 8
        ) {

            Image(
                systemName:
                    "scope"
            )


            Text(
                title
            )
            .fontWeight(
                .semibold
            )
        }
        .font(
            .subheadline
        )
        .padding(
            .horizontal,
            12
        )
        .padding(
            .vertical,
            8
        )
        .background(
            Capsule()
                .fill(
                    AppTheme.accent
                        .opacity(
                            0.10
                        )
                )
        )
    }


    // =====================================================
    // MARK: - Error
    // =====================================================

    @ViewBuilder
    private func errorCard(
        _ message: String
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 10
        ) {

            Image(
                systemName:
                    "exclamationmark.circle"
            )


            Text(
                message
            )
            .font(
                .subheadline
            )
        }
        .foregroundStyle(AppTheme.textSecondary)
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
                AppTheme.surface
            )
        )
    }


    // =====================================================
    // MARK: - Header
    // =====================================================

    private var headerTitle:
        String {

        switch step {

        case 0:

            return
                "Choose a Focus"


        case 1:

            return
                "Understand the Pattern"


        case 2:

            return
                "Choose Your Goal"


        default:

            return
                "Review Your Path"
        }
    }
}


// =========================================================
// MARK: - Preview
// =========================================================

#Preview {

    NavigationStack {

        GuidedPathSetupView()
            .environmentObject(
                OnboardingViewModel()
            )
    }
}
