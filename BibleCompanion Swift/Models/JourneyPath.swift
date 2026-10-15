import Foundation


// =========================================================
// MARK: - Journey Category
// =========================================================

enum JourneyCategory: String, Codable {

    case foundation
    case formation
    case discovery

    // Personalized paths such as:
    // Anger, Doubt, Forgiveness, custom AI-created paths, etc.
    case personalized
}


// =========================================================
// MARK: - Personalized Journey Status
// =========================================================

enum PersonalizedJourneyStatus: String, Codable {

    // The journey the user is currently working through.
    case active

    // The user switched to something else before finishing.
    // Progress should be preserved so they can return later.
    case paused

    // The user finished the path.
    case completed
}


// =========================================================
// MARK: - Journey Focus
// =========================================================

/// A snapshot of what caused a personalized journey
/// to be created.
///
/// This is intentionally stored WITH the journey.
/// That way, if the user's profile changes later,
/// we still remember what this specific journey
/// was originally built around.
struct JourneyFocus: Codable, Hashable {

    /// Normalized category.
    ///
    /// Examples:
    /// "Anger"
    /// "Doubt"
    /// "Forgiveness"
    /// "Relationships"
    let category: String


    /// Human-friendly name for this specific focus.
    ///
    /// Examples:
    /// "Anger when I feel disrespected"
    /// "Doubt caused by suffering"
    /// "Jealousy and comparison"
    let label: String


    /// The user's own words when they typed
    /// a custom struggle.
    ///
    /// We preserve this instead of only keeping
    /// the AI's interpretation.
    let originalText: String?


    /// Context discovered during onboarding
    /// or a future AI path-building conversation.
    let trigger: String?


    /// What the user said they want to grow in.
    let goal: String?


    init(
        category: String,
        label: String,
        originalText: String? = nil,
        trigger: String? = nil,
        goal: String? = nil
    ) {

        self.category =
            category

        self.label =
            label

        self.originalText =
            originalText

        self.trigger =
            trigger

        self.goal =
            goal
    }
}


// =========================================================
// MARK: - Journey Checkpoint
// =========================================================

struct JourneyCheckpoint:
    Identifiable,
    Codable,
    Hashable {

    let id: String

    let order: Int


    let title: String

    let subtitle: String


    let passage: String

    let focusQuestion: String


    // MARK: - Init

    init(
        id: String,
        order: Int,
        title: String,
        subtitle: String,
        passage: String,
        focusQuestion: String
    ) {

        self.id =
            id

        self.order =
            order

        self.title =
            title

        self.subtitle =
            subtitle

        self.passage =
            passage

        self.focusQuestion =
            focusQuestion
    }


    // MARK: - Recommendation Compatibility

    /// This keeps your existing JourneyCheckpointView
    /// and JourneyStudyView architecture working.
    ///
    /// A checkpoint can still be converted into the
    /// JourneyRecommendation format those views already use.
    var recommendation:
        JourneyRecommendation {

        JourneyRecommendation(
            title:
                title,
            reason:
                subtitle,
            actionTitle:
                "Begin",
            type:
                .guidedStudy,
            passage:
                passage,
            suggestedQuestion:
                focusQuestion
        )
    }
}


// =========================================================
// MARK: - Journey Path
// =========================================================

struct JourneyPath:
    Identifiable,
    Codable,
    Hashable {

    let id: String


    let title: String

    let subtitle: String


    let category:
        JourneyCategory


    let checkpoints:
        [JourneyCheckpoint]


    // MARK: - Personalized Metadata

    /// Nil for normal journeys such as Meet Jesus.
    ///
    /// Personalized journeys keep a snapshot of
    /// what the user was working through when
    /// this path was created.
    let focus:
        JourneyFocus?


    /// Useful later for sorting previous paths.
    ///
    /// Optional so old saved JourneyPath data
    /// can still decode without this property.
    let createdAt:
        Date?


    // MARK: - Init

    /// Existing code such as JourneyLibrary.meetJesus
    /// can continue using:
    ///
    /// JourneyPath(
    ///     id: ...,
    ///     title: ...,
    ///     subtitle: ...,
    ///     category: ...,
    ///     checkpoints: ...
    /// )
    ///
    /// without needing to change.
    init(
        id: String,
        title: String,
        subtitle: String,
        category: JourneyCategory,
        checkpoints: [JourneyCheckpoint],
        focus: JourneyFocus? = nil,
        createdAt: Date? = Date()
    ) {

        self.id =
            id

        self.title =
            title

        self.subtitle =
            subtitle

        self.category =
            category

        self.checkpoints =
            checkpoints

        self.focus =
            focus

        self.createdAt =
            createdAt
    }


    // MARK: - Helpers

    var isPersonalized:
        Bool {

        category ==
            .personalized
    }


    var checkpointCount:
        Int {

        checkpoints.count
    }


    /// Returns a checkpoint using its displayed order.
    ///
    /// Example:
    ///
    /// checkpoint(order: 3)
    func checkpoint(
        order: Int
    ) -> JourneyCheckpoint? {

        checkpoints.first {

            $0.order ==
                order
        }
    }
}


// =========================================================
// MARK: - Personalized Journey Record
// =========================================================

/// Represents one personalized path in the user's history.
///
/// This is separate from JourneyPath because the journey
/// itself describes the curriculum, while this object
/// describes the user's relationship to that curriculum.
///
/// Example:
///
/// Active:
///     Working Through Doubt
///
/// Past:
///     Understanding Anger — completed
///     Learning Forgiveness — paused
///
struct PersonalizedJourneyRecord:
    Identifiable,
    Codable,
    Hashable {

    var id: String {

        journey.id
    }


    let journey:
        JourneyPath


    var status:
        PersonalizedJourneyStatus


    /// When the user first accepted this path.
    let startedAt:
        Date


    /// Updated whenever meaningful progress or
    /// lifecycle changes happen.
    var lastUpdatedAt:
        Date


    /// Set when the journey stops being active,
    /// either because it was completed or replaced.
    var endedAt:
        Date?


    init(
        journey: JourneyPath,
        status: PersonalizedJourneyStatus = .active,
        startedAt: Date = Date(),
        lastUpdatedAt: Date = Date(),
        endedAt: Date? = nil
    ) {

        self.journey =
            journey

        self.status =
            status

        self.startedAt =
            startedAt

        self.lastUpdatedAt =
            lastUpdatedAt

        self.endedAt =
            endedAt
    }


    // MARK: - Helpers

    var isActive:
        Bool {

        status ==
            .active
    }


    var isPaused:
        Bool {

        status ==
            .paused
    }


    var isCompleted:
        Bool {

        status ==
            .completed
    }


    // MARK: - Lifecycle

    mutating func markActive() {

        status =
            .active

        endedAt =
            nil

        lastUpdatedAt =
            Date()
    }


    mutating func pause() {

        status =
            .paused

        endedAt =
            Date()

        lastUpdatedAt =
            Date()
    }


    mutating func complete() {

        status =
            .completed

        endedAt =
            Date()

        lastUpdatedAt =
            Date()
    }


    mutating func touch() {

        lastUpdatedAt =
            Date()
    }
}
