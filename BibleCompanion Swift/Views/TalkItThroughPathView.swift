//
//  TalkItThroughPathView.swift
//  BibleCompanion Swift
//
//  Created by Shopify on 10/2/26.
//

import SwiftUI


// =========================================================
// MARK: - Talk It Through Path View
// =========================================================

struct TalkItThroughPathView: View {

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

    private let conversationService =
        PathConversationService.shared


    private let journeyService =
        JourneyService.shared


    private let studyHistoryService =
        StudyHistoryService.shared


    private let storageService =
        StorageService.shared


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
    // MARK: - Conversation State
    // =====================================================

    @State
    private var messages:
        [PathChatMessage] = [

            PathChatMessage(
                role:
                    .companion,
                text:
                    """
                    What's been weighing on you lately?

                    You don't need to know exactly what the issue is yet. Just tell me what's been on your mind.
                    """
            )
        ]


    @State
    private var inputText =
        ""


    @State
    private var previousResponseID:
        String?


    @State
    private var isSending =
        false


    @State
    private var conversationError:
        String?


    // =====================================================
    // MARK: - Focus Proposal
    // =====================================================

    @State
    private var proposedFocus:
        JourneyFocus?


    @State
    private var showProposal =
        false


    // =====================================================
    // MARK: - Path Generation
    // =====================================================

    @State
    private var generatedPath:
        JourneyPath?


    @State
    private var isBuildingPath =
        false


    @State
    private var pathError:
        String?


    // =====================================================
    // MARK: - Keyboard
    // =====================================================

    @FocusState
    private var inputFocused:
        Bool


    // =====================================================
    // MARK: - Body
    // =====================================================

    var body: some View {

        VStack(
            spacing:
                0
        ) {

            // =================================================
            // MARK: Header
            // =================================================

            header


            Divider()


            // =================================================
            // MARK: Conversation
            // =================================================

            conversationArea


            Divider()


            // =================================================
            // MARK: Input
            // =================================================

            if generatedPath == nil {

                inputArea
            }
        }
        .cloudScreen()
        .navigationTitle(
            "Talk It Through"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .navigationBarBackButtonHidden(
            isSending
            ||
            isBuildingPath
        )
        .interactiveDismissDisabled(
            isSending
            ||
            isBuildingPath
        )
    }


    // =====================================================
    // MARK: - Header
    // =====================================================

    private var header:
        some View {

        HStack(
            spacing:
                12
        ) {

            CompanionAvatar(
                size: 44,
                behavior: .floating
            )


            VStack(
                alignment:
                    .leading,
                spacing:
                    2
            ) {

                Text(
                    "Talk It Through"
                )
                .font(
                    .headline
                )


                Text(
                    "Figure out what you want to work through."
                )
                .font(
                    .caption
                )
                .foregroundStyle(AppTheme.textSecondary)
            }


            Spacer()
        }
        .padding(
            .horizontal
        )
        .padding(
            .vertical,
            12
        )
        .background(
            AppTheme.surfaceStrong
        )
    }


    // =====================================================
    // MARK: - Conversation Area
    // =====================================================

    private var conversationArea:
        some View {

        ScrollViewReader { proxy in

            ScrollView {

                LazyVStack(
                    spacing:
                        16
                ) {

                    // =========================================
                    // Messages
                    // =========================================

                    ForEach(
                        messages
                    ) { message in

                        PathChatBubble(
                            message:
                                message
                        )
                        .id(
                            message.id
                        )
                    }


                    // =========================================
                    // Typing Indicator
                    // =========================================

                    if isSending {

                        typingIndicator
                            .id(
                                "typing"
                            )
                    }


                    // =========================================
                    // Conversation Error
                    // =========================================

                    if let conversationError {

                        errorCard(
                            title:
                                "Couldn't send that",
                            message:
                                conversationError
                        )
                    }


                    // =========================================
                    // Proposed Focus
                    // =========================================

                    if
                        showProposal,
                        let proposedFocus,
                        generatedPath == nil {

                        proposedFocusCard(
                            focus:
                                proposedFocus
                        )
                        .id(
                            "proposal"
                        )
                    }


                    // =========================================
                    // Building Path
                    // =========================================

                    if isBuildingPath {

                        buildingPathCard
                            .id(
                                "building"
                            )
                    }


                    // =========================================
                    // Path Error
                    // =========================================

                    if let pathError {

                        VStack(
                            alignment:
                                .leading,
                            spacing:
                                12
                        ) {

                            errorCard(
                                title:
                                    "Couldn't build the path",
                                message:
                                    pathError
                            )


                            Button {

                                Task {

                                    await buildPath()
                                }

                            } label: {

                                Text(
                                    "Try Again"
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
                                .borderedProminent
                            )
                        }
                    }


                    // =========================================
                    // Generated Path Preview
                    // =========================================

                    if let generatedPath {

                        pathPreview(
                            generatedPath
                        )
                        .id(
                            "pathPreview"
                        )
                    }


                    Color
                        .clear
                        .frame(
                            height:
                                1
                        )
                        .id(
                            "bottom"
                        )
                }
                .padding()
            }
            .scrollDismissesKeyboard(
                .interactively
            )
            .onChange(
                of:
                    messages.count
            ) {

                scrollToBottom(
                    proxy
                )
            }
            .onChange(
                of:
                    isSending
            ) {

                scrollToBottom(
                    proxy
                )
            }
            .onChange(
                of:
                    showProposal
            ) {

                scrollToBottom(
                    proxy
                )
            }
            .onChange(
                of:
                    isBuildingPath
            ) {

                scrollToBottom(
                    proxy
                )
            }
            .onChange(
                of:
                    generatedPath?
                        .id
            ) {

                scrollToBottom(
                    proxy
                )
            }
        }
    }


    // =====================================================
    // MARK: - Input Area
    // =====================================================

    private var inputArea:
        some View {

        VStack(
            spacing:
                8
        ) {

            HStack(
                alignment:
                    .bottom,
                spacing:
                    10
            ) {

                TextField(
                    "Type what's on your mind...",
                    text:
                        $inputText,
                    axis:
                        .vertical
                )
                .lineLimit(
                    1...5
                )
                .focused(
                    $inputFocused
                )
                .submitLabel(
                    .send
                )
                .onSubmit {

                    sendCurrentMessage()
                }
                .padding(
                    .horizontal,
                    14
                )
                .padding(
                    .vertical,
                    11
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


                Button {

                    sendCurrentMessage()

                } label: {

                    ZStack {

                        Circle()
                            .fill(
                                canSend
                                ? AppTheme.accent
                                : AppTheme.textSecondary
                                    .opacity(
                                        0.18
                                    )
                            )
                            .frame(
                                width:
                                    42,
                                height:
                                    42
                            )


                        Image(
                            systemName:
                                "arrow.up"
                        )
                        .fontWeight(
                            .bold
                        )
                        .foregroundStyle(
                            canSend
                            ? Color.white
                            : AppTheme.textSecondary
                        )
                    }
                }
                .buttonStyle(
                    .plain
                )
                .disabled(
                    !canSend
                )
            }


            Text(
                showProposal
                ? "You can keep talking if the proposed focus doesn't feel quite right."
                : "Companion may ask a few questions before proposing a focus."
            )
            .font(
                .caption2
            )
            .foregroundStyle(AppTheme.textSecondary)
            .frame(
                maxWidth:
                    .infinity,
                alignment:
                    .leading
            )
        }
        .padding(
            .horizontal
        )
        .padding(
            .vertical,
            10
        )
        .background(
            .ultraThinMaterial
        )
    }


    // =====================================================
    // MARK: - Can Send
    // =====================================================

    private var canSend:
        Bool {

        !inputText
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .isEmpty

        &&
        !isSending

        &&
        !isBuildingPath
    }


    // =====================================================
    // MARK: - Send Current Message
    // =====================================================

    private func sendCurrentMessage() {

        let cleaned =
            inputText
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        guard
            !cleaned.isEmpty,
            !isSending,
            !isBuildingPath
        else {

            return
        }


        inputText =
            ""


        inputFocused =
            false


        messages.append(

            PathChatMessage(
                role:
                    .user,
                text:
                    cleaned
            )
        )


        // -------------------------------------------------
        // If there was already a proposal and the user
        // keeps talking, hide the old proposal while the
        // Companion reassesses the conversation.
        // -------------------------------------------------

        showProposal =
            false


        generatedPath =
            nil


        pathError =
            nil


        conversationError =
            nil


        Task {

            await sendMessage(
                cleaned
            )
        }
    }


    // =====================================================
    // MARK: - Send Message
    // =====================================================

    @MainActor
    private func sendMessage(
        _ message:
            String
    ) async {

        isSending =
            true


        defer {

            isSending =
                false
        }


        do {

            let profile =
                onboardingViewModel
                    .profile


            let personalizationContext =
                buildPathConversationContext(
                    message:
                        message,
                    profile:
                        profile
                )


            let response:
                PathConversationResponse


            if let previousResponseID {

                response =
                    try await
                    conversationService
                        .continueConversation(

                            message:
                                message,

                            profile:
                                profile,

                            previousResponseID:
                                previousResponseID,

                            personalizationContext:
                                personalizationContext
                        )

            } else {

                response =
                    try await
                    conversationService
                        .start(

                            message:
                                message,

                            profile:
                                profile,

                            personalizationContext:
                                personalizationContext
                        )
            }


            self.previousResponseID =
                response
                    .responseID


            messages.append(

                PathChatMessage(
                    role:
                        .companion,
                    text:
                        response
                            .cleanedReply
                )
            )


            // -------------------------------------------------
            // Proposal
            // -------------------------------------------------

            if
                let focus =
                    response
                        .proposedFocus {

                proposedFocus =
                    focus


                withAnimation {

                    showProposal =
                        true
                }

            } else {

                proposedFocus =
                    nil


                showProposal =
                    false
            }

        } catch {

            conversationError =
                error
                    .localizedDescription
        }
    }


    // =====================================================
    // MARK: - Conversation Personalization Context
    // =====================================================

    /// Builds background context for the current Talk It Through
    /// turn.
    ///
    /// The user's current message remains authoritative. Existing
    /// Journey history, reflections, summaries, and study activity
    /// are supporting context only and should never silently decide
    /// what the user's new focus must be.
    private func buildPathConversationContext(
        message:
            String,
        profile:
            SpiritualProfile
    ) -> PersonalizationContext {

        let activeJourney =
            storageService
                .loadActivePersonalizedPath()


        let pastJourneys =
            storageService
                .loadPastPersonalizedJourneys()


        return personalizationContextService
            .buildContext(
                profile:
                    profile,
                activeJourney:
                    activeJourney,
                pastJourneys:
                    pastJourneys,
                purpose:
                    .journeyGeneration,
                currentPassage:
                    "",
                currentMessage:
                    message
            )
    }


    // =====================================================
    // MARK: - Proposed Focus Card
    // =====================================================

    @ViewBuilder
    private func proposedFocusCard(
        focus:
            JourneyFocus
    ) -> some View {

        VStack(
            alignment:
                .leading,
            spacing:
                16
        ) {

            // =================================================
            // Header
            // =================================================

            HStack {

                VStack(
                    alignment:
                        .leading,
                    spacing:
                        4
                ) {

                    Text(
                        "PROPOSED FOCUS"
                    )
                    .font(
                        .caption
                    )
                    .fontWeight(
                        .bold
                    )
                    .foregroundStyle(AppTheme.textSecondary)


                    Text(
                        focus.label
                    )
                    .font(
                        .title2
                    )
                    .bold()
                }


                Spacer()


                Image(
                    systemName:
                        "scope"
                )
                .font(
                    .title2
                )
                .foregroundStyle(
                    AppTheme.accent
                )
            }


            Divider()


            // =================================================
            // Concern
            // =================================================

            if let originalText =
                cleaned(
                    focus.originalText
                ) {

                proposalDetail(
                    icon:
                        "text.quote",
                    title:
                        "What you're working through",
                    value:
                        originalText
                )
            }


            // =================================================
            // Trigger
            // =================================================

            if let trigger =
                cleaned(
                    focus.trigger
                ) {

                proposalDetail(
                    icon:
                        "bolt.fill",
                    title:
                        "When it tends to show up",
                    value:
                        trigger
                )
            }


            // =================================================
            // Goal
            // =================================================

            if let goal =
                cleaned(
                    focus.goal
                ) {

                proposalDetail(
                    icon:
                        "arrow.up.right",
                    title:
                        "What you want to grow toward",
                    value:
                        goal
                )
            }


            // =================================================
            // Build Path
            // =================================================

            Button {

                Task {

                    await buildPath()
                }

            } label: {

                HStack {

                    Text(
                        "Build My Path"
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
            .disabled(
                isBuildingPath
            )


            // =================================================
            // Keep Talking
            // =================================================

            Button {

                keepTalking()

            } label: {

                Text(
                    "Keep Talking"
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
        .padding(
            20
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
        .overlay(

            RoundedRectangle(
                cornerRadius:
                    22
            )
            .stroke(
                AppTheme.accent
                    .opacity(
                        0.15
                    )
            )
        )
    }


    // =====================================================
    // MARK: - Proposal Detail
    // =====================================================

    @ViewBuilder
    private func proposalDetail(
        icon:
            String,
        title:
            String,
        value:
            String
    ) -> some View {

        HStack(
            alignment:
                .top,
            spacing:
                12
        ) {

            Image(
                systemName:
                    icon
            )
            .font(
                .subheadline
            )
            .foregroundStyle(
                AppTheme.accent
            )
            .frame(
                width:
                    22
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
                    .caption
                )
                .foregroundStyle(AppTheme.textSecondary)


                Text(
                    value
                )
                .font(
                    .subheadline
                )
            }


            Spacer()
        }
    }


    // =====================================================
    // MARK: - Keep Talking
    // =====================================================

    private func keepTalking() {

        withAnimation {

            showProposal =
                false
        }


        generatedPath =
            nil


        pathError =
            nil


        inputFocused =
            true
    }


    // =====================================================
    // MARK: - Build Path
    // =====================================================

    @MainActor
    private func buildPath()
        async {

        guard
            let proposedFocus
        else {

            pathError =
                "There's no proposed focus to build from yet."

            return
        }


        isBuildingPath =
            true


        pathError =
            nil


        inputFocused =
            false


        defer {

            isBuildingPath =
                false
        }


        // -------------------------------------------------
        // Curated Journey
        // -------------------------------------------------

        if let curated =
            JourneyLibrary
                .personalizedPath(
                    for:
                        proposedFocus
                ) {

            try?
                await Task.sleep(
                    nanoseconds:
                        500_000_000
                )


            generatedPath =
                curated


            return
        }


        // -------------------------------------------------
        // AI-Generated Journey
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


            let profile =
                profileSnapshot(
                    using:
                        proposedFocus
                )


            // -------------------------------------------------
            // Shared Personalization Context
            // -------------------------------------------------
            //
            // The focus created from this conversation is the
            // authoritative direction for the new path.
            //
            // Existing Journey history, reflections, summaries,
            // and study activity are supporting context only.

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
                            profile,
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
                                proposedFocus
                            )
                    )


            let path =
                try await
                journeyService
                    .generateCustomPath(

                        profile:
                            profile,

                        focus:
                            proposedFocus,

                        recentActivity:
                            recentActivity,

                        personalizationContext:
                            personalizationContext
                    )


            generatedPath =
                path

        } catch {

            pathError =
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
            cleaned(
                focus.originalText
            ) {

            pieces.append(
                "The user described the focus as: \(originalText)"
            )
        }


        if let trigger =
            cleaned(
                focus.trigger
            ) {

            pieces.append(
                "The issue tends to show up around: \(trigger)"
            )
        }


        if let goal =
            cleaned(
                focus.goal
            ) {

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
    // MARK: - Profile Snapshot
    // =====================================================

    private func profileSnapshot(
        using focus:
            JourneyFocus
    ) -> SpiritualProfile {

        var profile =
            onboardingViewModel
                .profile


        apply(
            focus:
                focus,
            to:
                &profile
        )


        return profile
    }


    // =====================================================
    // MARK: - Apply Focus to Profile
    // =====================================================

    private func apply(
        focus:
            JourneyFocus,
        to profile:
            inout SpiritualProfile
    ) {

        let normalizedCategory =
            focus.category
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        let isOther =
            normalizedCategory
                .lowercased()
            ==
            "other"


        profile
            .struggleCategory =
            isOther
            ? "Something else"
            : normalizedCategory


        profile
            .customStruggleText =
            isOther
            ? (
                focus.originalText
                ??
                ""
            )
            : ""


        profile
            .analyzedStruggleCategory =
            isOther
            ? normalizedCategory
            : ""


        profile
            .struggleLabel =
            focus.label


        profile
            .struggleSummary =
            focus.originalText
            ??
            ""


        profile
            .struggleTrigger =
            focus.trigger
            ??
            ""


        profile
            .struggleGoal =
            focus.goal
            ??
            ""
    }


    // =====================================================
    // MARK: - Building Path Card
    // =====================================================

    private var buildingPathCard:
        some View {

        VStack(
            alignment:
                .leading,
            spacing:
                16
        ) {

            HStack(
                spacing:
                    12
            ) {

                ProgressView()


                VStack(
                    alignment:
                        .leading,
                    spacing:
                        3
                ) {

                    Text(
                        "Building your path..."
                    )
                    .font(
                        .headline
                    )


                    Text(
                        "Choosing Scripture and arranging your checkpoints."
                    )
                    .font(
                        .subheadline
                    )
                    .foregroundStyle(AppTheme.textSecondary)
                }
            }


            Divider()


            buildStatusRow(
                title:
                    "Understanding your focus",
                completed:
                    true
            )


            buildStatusRow(
                title:
                    "Choosing relevant Scripture",
                completed:
                    true
            )


            buildStatusRow(
                title:
                    "Preparing your checkpoints",
                completed:
                    false
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
    // MARK: - Build Status Row
    // =====================================================

    @ViewBuilder
    private func buildStatusRow(
        title:
            String,
        completed:
            Bool
    ) -> some View {

        HStack(
            spacing:
                12
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
                title
            )
            .font(
                .subheadline
            )
        }
    }


    // =====================================================
    // MARK: - Path Preview
    // =====================================================

    @ViewBuilder
    private func pathPreview(
        _ path:
            JourneyPath
    ) -> some View {

        VStack(
            alignment:
                .leading,
            spacing:
                20
        ) {

            // =================================================
            // Header
            // =================================================

            VStack(
                alignment:
                    .leading,
                spacing:
                    7
            ) {

                Text(
                    "YOUR PROPOSED PATH"
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
                    .title
                )
                .bold()


                Text(
                    path.subtitle
                )
                .font(
                    .subheadline
                )
                .foregroundStyle(AppTheme.textSecondary)


                Text(
                    "\(path.checkpoints.count) checkpoints"
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


            Divider()


            // =================================================
            // Checkpoints
            // =================================================

            ForEach(
                path.checkpoints
            ) { checkpoint in

                checkpointPreview(
                    checkpoint
                )
            }


            Divider()


            // =================================================
            // Confirmation
            // =================================================

            VStack(
                alignment:
                    .leading,
                spacing:
                    6
            ) {

                Text(
                    "Ready to make this your active path?"
                )
                .font(
                    .headline
                )


                Text(
                    "Your current path will be saved, not deleted."
                )
                .font(
                    .subheadline
                )
                .foregroundStyle(AppTheme.textSecondary)
            }


            // =================================================
            // Use Path
            // =================================================

            Button {

                usePath(
                    path
                )

            } label: {

                HStack {

                    Text(
                        "Use This Path"
                    )
                    .fontWeight(
                        .semibold
                    )


                    Spacer()


                    Image(
                        systemName:
                            "checkmark"
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


            // =================================================
            // Keep Talking
            // =================================================

            Button {

                generatedPath =
                    nil


                pathError =
                    nil


                showProposal =
                    true


                inputFocused =
                    true

            } label: {

                Text(
                    "Keep Talking"
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
                .bordered
            )
        }
        .padding(
            20
        )
        .background(

            RoundedRectangle(
                cornerRadius:
                    24
            )
            .fill(
                AppTheme.surface
            )
        )
    }


    // =====================================================
    // MARK: - Checkpoint Preview
    // =====================================================

    @ViewBuilder
    private func checkpointPreview(
        _ checkpoint:
            JourneyCheckpoint
    ) -> some View {

        HStack(
            alignment:
                .top,
            spacing:
                14
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
                            34,
                        height:
                            34
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
                alignment:
                    .leading,
                spacing:
                    5
            ) {

                Text(
                    checkpoint.title
                )
                .font(
                    .headline
                )


                Label(
                    checkpoint.passage,
                    systemImage:
                        "book.closed"
                )
                .font(
                    .caption
                )
                .foregroundStyle(AppTheme.textSecondary)


                Text(
                    checkpoint.subtitle
                )
                .font(
                    .subheadline
                )
                .foregroundStyle(AppTheme.textSecondary)


                Text(
                    checkpoint.focusQuestion
                )
                .font(
                    .caption
                )
                .italic()
                .foregroundStyle(AppTheme.textSecondary)
                .padding(
                    .top,
                    2
                )
            }


            Spacer()
        }
    }


    // =====================================================
    // MARK: - Use Path
    // =====================================================

    @MainActor
    private func usePath(
        _ path:
            JourneyPath
    ) {

        guard
            let proposedFocus
        else {

            return
        }


        // -------------------------------------------------
        // Save updated profile
        // -------------------------------------------------

        var updatedProfile =
            onboardingViewModel
                .profile


        apply(
            focus:
                proposedFocus,
            to:
                &updatedProfile
        )


        onboardingViewModel
            .profile =
            updatedProfile


        onboardingViewModel
            .saveProfile()


        // -------------------------------------------------
        // Activate new path
        // -------------------------------------------------

        storageService
            .activatePersonalizedJourney(
                path
            )


        storageService
            .clearJourneyRecommendation()


        // -------------------------------------------------
        // Refresh caller
        // -------------------------------------------------

        onPathChanged()


        // -------------------------------------------------
        // Return to Change Path screen
        // -------------------------------------------------

        dismiss()
    }


    // =====================================================
    // MARK: - Typing Indicator
    // =====================================================

    private var typingIndicator:
        some View {

        HStack(
            alignment: .center,
            spacing: 10
        ) {

            CompanionAvatar(
                size: 36,
                behavior: .thinking
            )


            HStack(
                spacing:
                    6
            ) {

                ProgressView()
                    .controlSize(
                        .small
                    )


                Text(
                    "Companion is thinking..."
                )
                .font(
                    .subheadline
                )
                .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(
                .horizontal,
                14
            )
            .padding(
                .vertical,
                10
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


            Spacer(
                minLength:
                    60
            )
        }
    }


    // =====================================================
    // MARK: - Error Card
    // =====================================================

    @ViewBuilder
    private func errorCard(
        title:
            String,
        message:
            String
    ) -> some View {

        VStack(
            alignment:
                .leading,
            spacing:
                6
        ) {

            Label(
                title,
                systemImage:
                    "exclamationmark.circle"
            )
            .font(
                .headline
            )


            Text(
                message
            )
            .font(
                .subheadline
            )
            .foregroundStyle(AppTheme.textSecondary)
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
                    16
            )
            .fill(
                AppTheme.surface
            )
        )
    }


    // =====================================================
    // MARK: - Optional Cleaner
    // =====================================================

    private func cleaned(
        _ value:
            String?
    ) -> String? {

        guard
            let value
        else {

            return nil
        }


        let cleaned =
            value
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        return cleaned.isEmpty
        ? nil
        : cleaned
    }


    // =====================================================
    // MARK: - Scroll Helper
    // =====================================================

    private func scrollToBottom(
        _ proxy:
            ScrollViewProxy
    ) {

        DispatchQueue
            .main
            .asyncAfter(
                deadline:
                    .now()
                    +
                    0.08
            ) {

                withAnimation(
                    .easeOut(
                        duration:
                            0.25
                    )
                ) {

                    proxy.scrollTo(
                        "bottom",
                        anchor:
                            .bottom
                    )
                }
            }
    }
}


// =========================================================
// MARK: - Local Chat Message
// =========================================================

private struct PathChatMessage:
    Identifiable,
    Equatable {

    enum Role:
        Equatable {

        case user

        case companion
    }


    let id:
        UUID


    let role:
        Role


    let text:
        String


    init(
        id:
            UUID = UUID(),
        role:
            Role,
        text:
            String
    ) {

        self.id =
            id


        self.role =
            role


        self.text =
            text
    }
}


// =========================================================
// MARK: - Chat Bubble
// =========================================================

private struct PathChatBubble:
    View {

    let message:
        PathChatMessage


    var body: some View {

        HStack(
            alignment:
                .bottom,
            spacing:
                10
        ) {

            if message.role
                ==
                .companion {

                CompanionAvatar(
                    size: 34
                )
            }


            if message.role
                ==
                .user {

                Spacer(
                    minLength:
                        55
                )
            }


            VStack(
                alignment:
                    .leading,
                spacing:
                    4
            ) {

                if message.role
                    ==
                    .companion {

                    Text(
                        "COMPANION"
                    )
                    .font(
                        .caption2
                    )
                    .fontWeight(
                        .bold
                    )
                    .foregroundStyle(AppTheme.textSecondary)
                }


                Text(
                    message.text
                )
                .font(
                    .body
                )
                .textSelection(
                    .enabled
                )
            }
            .padding(
                .horizontal,
                14
            )
            .padding(
                .vertical,
                11
            )
            .background(

                RoundedRectangle(
                    cornerRadius:
                        18
                )
                .fill(
                    message.role
                    ==
                    .user
                    ?
                    AppTheme.accent
                    :
                    AppTheme.surface
                )
            )
            .foregroundStyle(
                message.role
                ==
                .user
                ?
                Color.white
                :
                AppTheme.textPrimary
            )


            if message.role
                ==
                .companion {

                Spacer(
                    minLength:
                        55
                )
            }
        }
        .frame(
            maxWidth:
                .infinity
        )
    }
}


// =========================================================
// MARK: - Preview
// =========================================================

#Preview {

    NavigationStack {

        TalkItThroughPathView()
            .environmentObject(
                OnboardingViewModel()
            )
    }
}
