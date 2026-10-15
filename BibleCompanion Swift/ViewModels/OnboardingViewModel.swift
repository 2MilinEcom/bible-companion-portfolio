import Foundation
import Combine


@MainActor
final class OnboardingViewModel:
    ObservableObject {

    // =====================================================
    // MARK: - Profile
    // =====================================================

    @Published
    var profile:
        SpiritualProfile


    // =====================================================
    // MARK: - Struggle Analysis State
    // =====================================================

    @Published
    var isAnalyzingStruggle =
        false


    @Published
    var struggleAnalysisError:
        String?


    // =====================================================
    // MARK: - Personalized Path State
    // =====================================================

    /// Used when onboarding is ready to create
    /// the user's first personalized journey.
    @Published
    private(set)
    var preparedPersonalizedPath:
        JourneyPath?


    @Published
    private(set)
    var hasPreparedPersonalizedPath =
        false


    @Published
    var personalizedPathError:
        String?


    // =====================================================
    // MARK: - Services
    // =====================================================

    private let storageService:
        StorageService


    private let struggleAnalysisService:
        StruggleAnalysisService


    // =====================================================
    // MARK: - Main Onboarding Options
    // =====================================================

    let spiritualPositions = [

        "I'm exploring Christianity",

        "I believe, but I'm unsure about a lot",

        "I'm trying to grow in my faith",

        "I've followed Jesus for a while",

        "I'm returning after time away",

        "Something else"
    ]


    let bibleFamiliarityOptions = [

        "I'm almost completely new",

        "I've read parts of the Bible",

        "I read somewhat regularly",

        "I study Scripture deeply"
    ]


    let primaryGoals = [

        "I want to know if Christianity is true",

        "I want to understand the Bible",

        "I want to grow closer to God",

        "I'm struggling with something",

        "I have theological questions",

        "I want my beliefs challenged"
    ]


    let currentSeasons = [

        "I'm curious but unsure",

        "I'm actively growing",

        "I feel spiritually stuck",

        "I'm going through something difficult",

        "I'm returning to God",

        "I'm doing well and want to go deeper"
    ]


    let challengePreferences = [

        "Be gentle and help me understand",

        "Give me different perspectives",

        "Push back when my reasoning is weak",

        "Challenge me strongly"
    ]


    // =====================================================
    // MARK: - Struggle Options
    // =====================================================

    let struggleCategories = [

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
    // MARK: - Init
    // =====================================================

    init(
        storageService:
            StorageService? = nil,

        struggleAnalysisService:
            StruggleAnalysisService? = nil
    ) {

        self.storageService =
            storageService ?? .shared


        self.struggleAnalysisService =
            struggleAnalysisService ?? .shared


        self.profile =
            self.storageService
                .loadSpiritualProfile()
            ??
            SpiritualProfile.empty
    }


    // =====================================================
    // MARK: - Main Page Validation
    // =====================================================

    var canContinue:
        Bool {

        !profile
            .spiritualPosition
            .isEmpty

        &&

        !profile
            .bibleFamiliarity
            .isEmpty

        &&

        !profile
            .primaryGoal
            .isEmpty

        &&

        !profile
            .currentSeason
            .isEmpty

        &&

        !profile
            .challengePreference
            .isEmpty
    }


    // =====================================================
    // MARK: - Effective Struggle
    // =====================================================

    /// Kept for compatibility with your existing
    /// questionnaire UI.
    ///
    /// SpiritualProfile now also exposes
    /// resolvedStruggleCategory.
    var effectiveStruggleCategory:
        String {

        profile
            .resolvedStruggleCategory
    }


    /// Kept for compatibility with your existing UI.
    var effectiveStruggleLabel:
        String {

        profile
            .resolvedStruggleLabel
    }


    var needsCustomStruggleAnalysis:
        Bool {

        profile
            .usesCustomStruggle
    }


    var canAnalyzeCustomStruggle:
        Bool {

        needsCustomStruggleAnalysis

        &&

        !profile
            .customStruggleText
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .isEmpty
    }


    var customStruggleHasBeenAnalyzed:
        Bool {

        !profile
            .analyzedStruggleCategory
            .isEmpty

        &&

        !profile
            .struggleLabel
            .isEmpty
    }


    var shouldShowStruggleFollowUps:
        Bool {

        if needsCustomStruggleAnalysis {

            return
                customStruggleHasBeenAnalyzed
        }


        return
            !profile
                .struggleCategory
                .isEmpty
    }


    var canContinueStruggleDetails:
        Bool {

        shouldShowStruggleFollowUps

        &&

        !profile
            .struggleTrigger
            .isEmpty

        &&

        !profile
            .struggleGoal
            .isEmpty
    }


    // =====================================================
    // MARK: - AI Analysis
    // =====================================================

    func analyzeCustomStruggle()
        async -> Bool {

        let rawText =
            profile
                .customStruggleText
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        guard
            !rawText.isEmpty
        else {

            struggleAnalysisError =
                "Tell us a little about what you're struggling with first."

            return false
        }


        isAnalyzingStruggle =
            true


        struggleAnalysisError =
            nil


        defer {

            isAnalyzingStruggle =
                false
        }


        do {

            let analysis =
                try await
                struggleAnalysisService
                    .analyze(
                        text:
                            rawText
                    )


            profile
                .analyzedStruggleCategory =
                analysis.category


            profile
                .struggleLabel =
                analysis.label


            profile
                .struggleSummary =
                analysis.summary


            // A new analysis means the follow-up
            // questions should be answered again.

            profile
                .struggleTrigger =
                ""


            profile
                .struggleGoal =
                ""


            return true

        } catch {

            struggleAnalysisError =
                error
                    .localizedDescription


            return false
        }
    }


    // =====================================================
    // MARK: - Prepare Struggle for Summary
    // =====================================================

    func prepareStruggleForSummary()
        -> Bool {

        guard
            canContinueStruggleDetails
        else {

            return false
        }


        // For normal predefined categories,
        // the selection itself becomes the label.

        if
            profile
                .struggleCategory
            !=
            "Something else" {

            profile
                .analyzedStruggleCategory =
                ""


            profile
                .struggleLabel =
                profile
                    .struggleCategory


            profile
                .struggleSummary =
                ""


            profile
                .customStruggleText =
                ""
        }


        // Clear any path prepared from an older
        // questionnaire selection.
        clearPreparedPersonalizedPath()


        return true
    }


    // =====================================================
    // MARK: - Journey Focus
    // =====================================================

    /// The user's questionnaire converted into the
    /// format the journey system understands.
    var currentJourneyFocus:
        JourneyFocus? {

        guard
            let focus =
                profile
                    .journeyFocus
        else {

            return nil
        }


        // Normalize questionnaire category names into
        // the canonical names used by JourneyLibrary.
        //
        // This keeps the user-facing wording nice while
        // making path lookup reliable.

        return JourneyFocus(

            category:
                normalizedJourneyCategory(
                    focus.category
                ),

            label:
                focus.label,

            originalText:
                focus.originalText,

            trigger:
                focus.trigger,

            goal:
                focus.goal
        )
    }


    // =====================================================
    // MARK: - Curated Path
    // =====================================================

    /// Returns a curated path when JourneyLibrary
    /// already knows how to handle this topic.
    ///
    /// Example:
    ///
    /// Anger
    ///     → Understanding Your Anger
    ///
    /// Doubt
    ///     → Working Through Doubt
    var curatedPersonalizedPath:
        JourneyPath? {

        guard
            let focus =
                currentJourneyFocus
        else {

            return nil
        }


        return JourneyLibrary
            .personalizedPath(
                for:
                    focus
            )
    }


    var hasCuratedPersonalizedPath:
        Bool {

        curatedPersonalizedPath
        != nil
    }


    // =====================================================
    // MARK: - Prepare Initial Personalized Path
    // =====================================================

    /// Called during the onboarding loading screen.
    ///
    /// Returns a curated journey if one exists.
    ///
    /// If it returns nil, the app knows the user needs
    /// a custom AI-created path instead.
    @discardableResult
    func prepareInitialPersonalizedPath()
        -> JourneyPath? {

        personalizedPathError =
            nil


        guard
            let focus =
                currentJourneyFocus
        else {

            personalizedPathError =
                "We couldn't determine your current focus."

            preparedPersonalizedPath =
                nil


            hasPreparedPersonalizedPath =
                false


            return nil
        }


        guard
            let path =
                JourneyLibrary
                    .personalizedPath(
                        for:
                            focus
                    )
        else {

            // This is NOT necessarily an error.
            //
            // It usually means the user entered a
            // custom struggle that should be sent
            // to the future custom AI path builder.

            preparedPersonalizedPath =
                nil


            hasPreparedPersonalizedPath =
                false


            return nil
        }


        preparedPersonalizedPath =
            path


        hasPreparedPersonalizedPath =
            true


        return path
    }


    // =====================================================
    // MARK: - Activate Prepared Path
    // =====================================================

    /// Activates the path only after it has actually
    /// been prepared and approved by the flow.
    ///
    /// StorageService will pause an old active path
    /// rather than deleting it.
    @discardableResult
    func activatePreparedPersonalizedPath()
        -> Bool {

        guard
            let path =
                preparedPersonalizedPath
        else {

            return false
        }


        storageService
            .activatePersonalizedJourney(
                path
            )


        // The new JourneyPath now replaces the old
        // one-off recommendation concept.
        storageService
            .clearJourneyRecommendation()


        return true
    }


    // =====================================================
    // MARK: - Prepare + Activate Curated Path
    // =====================================================

    /// Convenience method for first-time onboarding.
    ///
    /// We will call this from JourneyPreparationView
    /// once that file is updated.
    @discardableResult
    func createAndActivateInitialPersonalizedPath()
        -> JourneyPath? {

        guard
            let path =
                prepareInitialPersonalizedPath()
        else {

            return nil
        }


        storageService
            .activatePersonalizedJourney(
                path
            )


        storageService
            .clearJourneyRecommendation()


        return path
    }


    // =====================================================
    // MARK: - Activate Any Approved Path
    // =====================================================

    /// This will also be reusable later for:
    ///
    /// Change Path
    ///     → Questionnaire
    ///
    /// Change Path
    ///     → Talk It Through
    ///
    /// AI can propose a JourneyPath, but nothing changes
    /// until the user taps "Use This Path."
    func activateApprovedPersonalizedPath(
        _ path: JourneyPath
    ) {

        storageService
            .activatePersonalizedJourney(
                path
            )


        storageService
            .clearJourneyRecommendation()


        preparedPersonalizedPath =
            path


        hasPreparedPersonalizedPath =
            true
    }


    // =====================================================
    // MARK: - Clear Prepared Path
    // =====================================================

    func clearPreparedPersonalizedPath() {

        preparedPersonalizedPath =
            nil


        hasPreparedPersonalizedPath =
            false


        personalizedPathError =
            nil
    }


    // =====================================================
    // MARK: - Category Normalization
    // =====================================================

    private func normalizedJourneyCategory(
        _ category: String
    ) -> String {

        let cleaned =
            category
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        switch cleaned
            .lowercased() {

        case "prayer and consistency",
             "prayer & consistency",
             "spiritual consistency":

            return
                "Prayer"


        case "fear or worry",
             "fear and worry",
             "fear / worry",
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
             "habits / self-control",
             "self control",
             "discipline":

            return
                "Self-control"


        default:

            return cleaned
        }
    }


    // =====================================================
    // MARK: - Adaptive Trigger Options
    // =====================================================

    func triggerOptions(
        for category: String
    ) -> [String] {

        switch category {

        case "Anger":

            return [

                "When I feel disrespected",

                "During conflict with someone close to me",

                "When things don't go the way I expected",

                "I hold things in until I explode",

                "I'm angry at myself",

                "I'm angry at someone who hurt me",

                "I'm angry at God",

                "I'm not really sure"
            ]


        case "Forgiveness":

            return [

                "Someone betrayed me",

                "Someone hurt me deeply",

                "I keep replaying what happened",

                "They haven't apologized",

                "I don't think they deserve forgiveness",

                "I can forgive, but I can't trust them",

                "I'm struggling to forgive myself",

                "I'm not really sure"
            ]


        case "Temptation":

            return [

                "It happens when I'm alone",

                "Stress makes it worse",

                "Boredom makes it worse",

                "It happens when I'm discouraged",

                "Certain people or environments trigger it",

                "It's become a repeated habit",

                "I usually regret it afterward",

                "I'm not really sure"
            ]


        case "Doubt":

            return [

                "I'm unsure whether God exists",

                "I'm unsure whether Christianity is true",

                "I struggle with parts of the Bible",

                "Suffering makes me question God",

                "I have questions about Jesus",

                "I have theological questions",

                "My faith feels uncertain lately",

                "I'm not really sure"
            ]


        case "Relationships":

            return [

                "Conflict keeps happening",

                "I don't feel understood",

                "I struggle with trust",

                "I struggle with boundaries",

                "I'm dealing with hurt from someone",

                "I want to handle relationships more biblically",

                "I'm not really sure"
            ]


        case "Prayer and consistency":

            return [

                "I don't know what to pray",

                "Prayer feels dry",

                "I struggle to stay consistent",

                "I get distracted easily",

                "I feel distant from God",

                "I only pray when things go wrong",

                "I'm not really sure"
            ]


        case "Fear or worry":

            return [

                "I keep thinking about what could go wrong",

                "Uncertainty makes it worse",

                "It affects my decisions",

                "I struggle to trust God with it",

                "It gets worse when I'm alone",

                "It comes up around a specific situation",

                "I'm not really sure"
            ]


        case "Loneliness":

            return [

                "I don't feel understood",

                "I feel disconnected from people",

                "I feel distant from God",

                "I have people around me but still feel alone",

                "A relationship changed or ended",

                "I don't know where I belong",

                "I'm not really sure"
            ]


        case "Grief or loss":

            return [

                "I lost someone close to me",

                "Something important ended",

                "I'm struggling with why God allowed it",

                "I feel angry",

                "I feel numb",

                "I feel alone",

                "I don't know how to move forward",

                "I'm not really sure"
            ]


        case "Purpose or direction":

            return [

                "I don't know what I'm supposed to do next",

                "I feel behind",

                "I have too many directions I could take",

                "I'm afraid of choosing wrong",

                "I don't know what God wants from me",

                "My life feels unfocused",

                "I'm not really sure"
            ]


        case "Habits and self-control":

            return [

                "I keep repeating the same behavior",

                "I do well for a while and then fall back",

                "Stress makes it harder",

                "I struggle when I'm alone",

                "I know what I should do but don't do it",

                "I want more discipline",

                "I'm not really sure"
            ]


        default:

            return [

                "It's been affecting me for a while",

                "It comes and goes",

                "Something recently happened",

                "I keep repeating the same pattern",

                "Certain situations make it worse",

                "I'm trying to understand what I'm feeling",

                "I'm not really sure"
            ]
        }
    }


    // =====================================================
    // MARK: - Adaptive Growth Goals
    // =====================================================

    func growthOptions(
        for category: String
    ) -> [String] {

        switch category {

        case "Anger":

            return [

                "Understand where my anger comes from",

                "Control what I say or do",

                "Know whether my anger is justified",

                "Learn how to respond without exploding",

                "Forgive someone I'm angry with",

                "Stop repeating the same pattern"
            ]


        case "Forgiveness":

            return [

                "Understand what forgiveness actually means",

                "Learn how to forgive someone",

                "Let go of bitterness",

                "Know whether forgiveness requires trust",

                "Forgive myself",

                "Stop letting the past control me"
            ]


        case "Temptation":

            return [

                "Understand why I keep returning to it",

                "Recognize my triggers",

                "Learn how to resist",

                "Build better habits",

                "Recover after I mess up",

                "Stop repeating the same cycle"
            ]


        case "Doubt":

            return [

                "Understand the evidence better",

                "Work through my hardest questions",

                "Understand Scripture more clearly",

                "Know what Christians actually believe",

                "Separate emotional doubt from intellectual doubt",

                "Become more confident in what I believe"
            ]


        case "Relationships":

            return [

                "Handle conflict better",

                "Learn healthier boundaries",

                "Become more forgiving",

                "Understand biblical relationships",

                "Communicate better",

                "Know when trust should be rebuilt"
            ]


        case "Prayer and consistency":

            return [

                "Build a consistent prayer life",

                "Learn how to pray",

                "Feel more connected to God",

                "Stay consistent when I don't feel motivated",

                "Understand what prayer is for",

                "Build spiritual discipline"
            ]


        case "Fear or worry":

            return [

                "Understand what is driving my fear",

                "Learn how to respond when worry starts",

                "Trust God more with uncertainty",

                "Stop letting fear control my decisions",

                "Build peace and steadiness",

                "Know what Scripture says about fear"
            ]


        case "Loneliness":

            return [

                "Understand why I feel so alone",

                "Feel closer to God",

                "Build healthier connection with people",

                "Stop isolating myself",

                "Find belonging",

                "Learn how biblical people handled loneliness"
            ]


        case "Grief or loss":

            return [

                "Understand where God is in this",

                "Learn how to grieve faithfully",

                "Work through my anger",

                "Find hope again",

                "Learn how biblical people handled grief",

                "Take the next step forward"
            ]


        case "Purpose or direction":

            return [

                "Understand what matters most right now",

                "Make wiser decisions",

                "Learn how Scripture talks about calling",

                "Stop being paralyzed by uncertainty",

                "Take a faithful next step",

                "Build clearer priorities"
            ]


        case "Habits and self-control":

            return [

                "Understand why I keep repeating this",

                "Recognize my triggers",

                "Build better habits",

                "Grow in self-control",

                "Recover well after I slip",

                "Stop repeating the same cycle"
            ]


        default:

            return [

                "Understand what I'm going through",

                "See what Scripture says about it",

                "Recognize unhealthy patterns",

                "Respond differently",

                "Grow spiritually through this",

                "Know what my next step should be"
            ]
        }
    }


    // =====================================================
    // MARK: - Resetting Struggle State
    // =====================================================

    func resetStruggleForNewCategory() {

        profile
            .customStruggleText =
            ""


        profile
            .analyzedStruggleCategory =
            ""


        profile
            .struggleLabel =
            ""


        profile
            .struggleSummary =
            ""


        profile
            .struggleTrigger =
            ""


        profile
            .struggleGoal =
            ""


        struggleAnalysisError =
            nil


        clearPreparedPersonalizedPath()
    }


    func clearCustomStruggleAnalysis() {

        profile
            .analyzedStruggleCategory =
            ""


        profile
            .struggleLabel =
            ""


        profile
            .struggleSummary =
            ""


        profile
            .struggleTrigger =
            ""


        profile
            .struggleGoal =
            ""


        struggleAnalysisError =
            nil


        clearPreparedPersonalizedPath()
    }


    // =====================================================
    // MARK: - Save
    // =====================================================

    func saveProfile() {

        storageService
            .saveSpiritualProfile(
                profile
            )


        // Keep clearing the OLD recommendation.
        //
        // This does NOT erase a persistent
        // personalized journey.

        storageService
            .clearJourneyRecommendation()
    }


    // =====================================================
    // MARK: - Reset
    // =====================================================

    func resetProfile() {

        profile =
            SpiritualProfile.empty


        clearPreparedPersonalizedPath()


        storageService
            .clearSpiritualProfile()


        storageService
            .clearJourneyRecommendation()
    }
}
