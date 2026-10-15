import Foundation


struct SpiritualProfile:
    Codable {

    // =====================================================
    // MARK: - Core Spiritual Profile
    // =====================================================

    /// The name the user wants their Companion to use.
    /// This is intentionally a preferred name, not a legal-name field.
    var name:
        String

    var spiritualPosition:
        String

    var bibleFamiliarity:
        String

    var primaryGoal:
        String

    var currentSeason:
        String

    var challengePreference:
        String


    // =====================================================
    // MARK: - Personalized Struggle Context
    // =====================================================

    /// What the user selected directly.
    ///
    /// Examples:
    ///
    /// "Anger"
    /// "Doubt"
    /// "Forgiveness"
    /// "Something else"
    var struggleCategory:
        String


    /// Preserved exactly as the user typed it
    /// when they choose "Something else".
    ///
    /// Example:
    ///
    /// "I keep comparing myself to everyone
    /// and feel like I'm falling behind."
    var customStruggleText:
        String


    /// AI-normalized category for custom text.
    ///
    /// Examples:
    ///
    /// "Anger"
    /// "Jealousy and comparison"
    /// "Fear"
    ///
    /// This does NOT replace the user's original wording.
    var analyzedStruggleCategory:
        String


    /// Short human-friendly label.
    ///
    /// Example:
    ///
    /// "Jealousy and comparison"
    var struggleLabel:
        String


    /// Neutral summary of what the user described.
    ///
    /// Example:
    ///
    /// "The user compares their progress with others
    /// and feels discouraged when they believe they
    /// are falling behind."
    var struggleSummary:
        String


    /// Context around when the struggle tends to appear.
    var struggleTrigger:
        String


    /// What the user wants to grow toward.
    var struggleGoal:
        String


    // =====================================================
    // MARK: - Init
    // =====================================================

    init(
        name: String = "",
        spiritualPosition: String,
        bibleFamiliarity: String,
        primaryGoal: String,
        currentSeason: String,
        challengePreference: String,
        struggleCategory: String = "",
        customStruggleText: String = "",
        analyzedStruggleCategory: String = "",
        struggleLabel: String = "",
        struggleSummary: String = "",
        struggleTrigger: String = "",
        struggleGoal: String = ""
    ) {

        self.name =
            name

        self.spiritualPosition =
            spiritualPosition

        self.bibleFamiliarity =
            bibleFamiliarity

        self.primaryGoal =
            primaryGoal

        self.currentSeason =
            currentSeason

        self.challengePreference =
            challengePreference


        self.struggleCategory =
            struggleCategory

        self.customStruggleText =
            customStruggleText

        self.analyzedStruggleCategory =
            analyzedStruggleCategory

        self.struggleLabel =
            struggleLabel

        self.struggleSummary =
            struggleSummary

        self.struggleTrigger =
            struggleTrigger

        self.struggleGoal =
            struggleGoal
    }


    // =====================================================
    // MARK: - Preferred Name
    // =====================================================

    /// A trimmed version of the name that is safe to use in UI copy.
    var preferredName: String {

        name
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
    }


    // =====================================================
    // MARK: - Resolved Struggle Category
    // =====================================================

    /// The category the personalized-path system
    /// should actually use.
    ///
    /// Normal selection:
    ///
    /// struggleCategory = "Anger"
    ///
    /// becomes:
    ///
    /// resolvedStruggleCategory = "Anger"
    ///
    ///
    /// Custom selection:
    ///
    /// struggleCategory = "Something else"
    /// analyzedStruggleCategory = "Anger"
    ///
    /// becomes:
    ///
    /// resolvedStruggleCategory = "Anger"
    ///
    ///
    /// This allows custom responses to still match
    /// curated JourneyLibrary paths when appropriate.
    var resolvedStruggleCategory:
        String {

        let selected =
            struggleCategory
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        let analyzed =
            analyzedStruggleCategory
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        let isCustomSelection =
            selected
                .caseInsensitiveCompare(
                    "Something else"
                )
            ==
            .orderedSame


        if
            isCustomSelection,
            !analyzed.isEmpty {

            return analyzed
        }


        if !selected.isEmpty {

            return selected
        }


        if !analyzed.isEmpty {

            return analyzed
        }


        return ""
    }


    // =====================================================
    // MARK: - Resolved Struggle Label
    // =====================================================

    /// The user-facing name for this focus.
    ///
    /// Priority:
    ///
    /// 1. AI-generated human-friendly label
    /// 2. Custom text
    /// 3. Resolved category
    var resolvedStruggleLabel:
        String {

        let label =
            struggleLabel
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        if !label.isEmpty {

            return label
        }


        let customText =
            customStruggleText
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        if !customText.isEmpty {

            return customText
        }


        return resolvedStruggleCategory
    }


    // =====================================================
    // MARK: - Custom Struggle
    // =====================================================

    var usesCustomStruggle:
        Bool {

        struggleCategory
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .caseInsensitiveCompare(
                "Something else"
            )
        ==
        .orderedSame
    }


    // =====================================================
    // MARK: - Has Personalized Focus
    // =====================================================

    var hasStruggleContext:
        Bool {

        !resolvedStruggleCategory
            .isEmpty
        ||
        !resolvedStruggleLabel
            .isEmpty
        ||
        !customStruggleText
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .isEmpty
    }


    // =====================================================
    // MARK: - Journey Focus
    // =====================================================

    /// Converts onboarding data into the format used
    /// by the personalized journey system.
    ///
    /// This is the bridge between:
    ///
    /// Questionnaire
    ///       ↓
    /// SpiritualProfile
    ///       ↓
    /// JourneyFocus
    ///       ↓
    /// JourneyLibrary.personalizedPath(...)
    ///
    var journeyFocus:
        JourneyFocus? {

        guard
            hasStruggleContext
        else {

            return nil
        }


        let category =
            resolvedStruggleCategory


        let label =
            resolvedStruggleLabel


        let originalText:
            String? = {

            let text =
                customStruggleText
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )


            guard
                !text.isEmpty
            else {

                return nil
            }


            return text
        }()


        let trigger:
            String? = {

            let text =
                struggleTrigger
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )


            guard
                !text.isEmpty
            else {

                return nil
            }


            return text
        }()


        let goal:
            String? = {

            let text =
                struggleGoal
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )


            guard
                !text.isEmpty
            else {

                return nil
            }


            return text
        }()


        return JourneyFocus(

            category:
                category,

            label:
                label,

            originalText:
                originalText,

            trigger:
                trigger,

            goal:
                goal
        )
    }


    // =====================================================
    // MARK: - Curated Path Availability
    // =====================================================

    /// Convenience property.
    ///
    /// This does NOT generate or save a path.
    ///
    /// It simply tells us whether JourneyLibrary has
    /// an existing curated curriculum for this focus.
    var hasCuratedPersonalizedPath:
        Bool {

        guard
            let journeyFocus
        else {

            return false
        }


        return JourneyLibrary
            .personalizedPath(
                for:
                    journeyFocus
            )
        != nil
    }


    // =====================================================
    // MARK: - Display Summary
    // =====================================================

    /// Useful later for the "Change Path" screens
    /// and personalized-path header.
    var personalizedFocusDisplayText:
        String {

        let label =
            resolvedStruggleLabel


        if !label.isEmpty {

            return label
        }


        return
            "Your current focus"
    }


    // =====================================================
    // MARK: - Backwards-Compatible Decoding
    // =====================================================

    enum CodingKeys:
        String,
        CodingKey {

        case name
        case spiritualPosition
        case bibleFamiliarity
        case primaryGoal
        case currentSeason
        case challengePreference

        case struggleCategory
        case customStruggleText
        case analyzedStruggleCategory
        case struggleLabel
        case struggleSummary
        case struggleTrigger
        case struggleGoal
    }


    init(
        from decoder: Decoder
    ) throws {

        let container =
            try decoder.container(
                keyedBy:
                    CodingKeys.self
            )


        name =
            try container
                .decodeIfPresent(
                    String.self,
                    forKey:
                        .name
                )
            ?? ""


        spiritualPosition =
            try container
                .decodeIfPresent(
                    String.self,
                    forKey:
                        .spiritualPosition
                )
            ?? ""


        bibleFamiliarity =
            try container
                .decodeIfPresent(
                    String.self,
                    forKey:
                        .bibleFamiliarity
                )
            ?? ""


        primaryGoal =
            try container
                .decodeIfPresent(
                    String.self,
                    forKey:
                        .primaryGoal
                )
            ?? ""


        currentSeason =
            try container
                .decodeIfPresent(
                    String.self,
                    forKey:
                        .currentSeason
                )
            ?? ""


        challengePreference =
            try container
                .decodeIfPresent(
                    String.self,
                    forKey:
                        .challengePreference
                )
            ?? ""


        struggleCategory =
            try container
                .decodeIfPresent(
                    String.self,
                    forKey:
                        .struggleCategory
                )
            ?? ""


        customStruggleText =
            try container
                .decodeIfPresent(
                    String.self,
                    forKey:
                        .customStruggleText
                )
            ?? ""


        analyzedStruggleCategory =
            try container
                .decodeIfPresent(
                    String.self,
                    forKey:
                        .analyzedStruggleCategory
                )
            ?? ""


        struggleLabel =
            try container
                .decodeIfPresent(
                    String.self,
                    forKey:
                        .struggleLabel
                )
            ?? ""


        struggleSummary =
            try container
                .decodeIfPresent(
                    String.self,
                    forKey:
                        .struggleSummary
                )
            ?? ""


        struggleTrigger =
            try container
                .decodeIfPresent(
                    String.self,
                    forKey:
                        .struggleTrigger
                )
            ?? ""


        struggleGoal =
            try container
                .decodeIfPresent(
                    String.self,
                    forKey:
                        .struggleGoal
                )
            ?? ""
    }


    // =====================================================
    // MARK: - Empty Profile
    // =====================================================

    static let empty =
        SpiritualProfile(

            name:
                "",

            spiritualPosition:
                "",

            bibleFamiliarity:
                "",

            primaryGoal:
                "",

            currentSeason:
                "",

            challengePreference:
                "",

            struggleCategory:
                "",

            customStruggleText:
                "",

            analyzedStruggleCategory:
                "",

            struggleLabel:
                "",

            struggleSummary:
                "",

            struggleTrigger:
                "",

            struggleGoal:
                ""
        )
}
