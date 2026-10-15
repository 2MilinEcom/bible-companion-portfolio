import Foundation
import Combine


// =========================================================
// MARK: - Companion Growth Metrics
// =========================================================

struct CompanionGrowthMetrics:
    Equatable {

    let completedCheckpoints: Int
    let checkpointReflections: Int
    let completedJourneys: Int
    let finalJourneyReflections: Int
    let journeySummaries: Int


    static let zero =
        CompanionGrowthMetrics(
            completedCheckpoints: 0,
            checkpointReflections: 0,
            completedJourneys: 0,
            finalJourneyReflections: 0,
            journeySummaries: 0
        )
}


// =========================================================
// MARK: - Companion Growth Milestone
// =========================================================

struct CompanionGrowthMilestone:
    Identifiable,
    Codable {

    let id: UUID
    let stage: CompanionStage
    let reachedAt: Date

    /// True when this milestone was reconstructed from progress that existed
    /// before milestone history was introduced. Future transformations are exact.
    let isBackfilled: Bool


    init(
        id: UUID = UUID(),
        stage: CompanionStage,
        reachedAt: Date = Date(),
        isBackfilled: Bool = false
    ) {

        self.id = id
        self.stage = stage
        self.reachedAt = reachedAt
        self.isBackfilled = isBackfilled
    }
}


// =========================================================
// MARK: - Companion Growth Store
// =========================================================

/// Central source of truth for Companion growth.
///
/// Growth is intentionally based on durable, meaningful engagement that the
/// app already stores: completed checkpoints, reflections, completed journeys,
/// final journey reflections, and journey summaries.
///
/// It does NOT award points for opening the app, sending lots of messages, or
/// repeating the same action. That keeps growth from becoming a spiritual
/// score or something that can be spammed.
final class CompanionGrowthStore:
    ObservableObject {

    static let shared =
        CompanionGrowthStore()


    // =====================================================
    // MARK: - Published State
    // =====================================================

    @Published
    private(set) var points =
        0


    @Published
    private(set) var stage:
        CompanionStage = .egg


    @Published
    private(set) var metrics:
        CompanionGrowthMetrics = .zero


    /// A stage waiting to be celebrated in the UI.
    /// This is separate from `stage` so the whole app can immediately use
    /// the new artwork while a single global reveal is presented once.
    @Published
    private(set) var pendingStageReveal:
        CompanionStage?


    /// Saved history of Companion transformations.
    /// Egg is the starting form, so only actual growth stages are recorded.
    @Published
    private(set) var milestones:
        [CompanionGrowthMilestone] = []


    // =====================================================
    // MARK: - Point Weights
    // =====================================================

    /// These values can be tuned later without changing the UI.
    private enum Weight {

        static let checkpoint = 3
        static let checkpointReflection = 2
        static let completedJourney = 8
        static let finalJourneyReflection = 4
        static let journeySummary = 3
    }


    // =====================================================
    // MARK: - Persistence
    // =====================================================

    /// Growth never moves backward just because a reflection is edited,
    /// a checkpoint is reset, or scoring weights are adjusted later.
    private let highestPointsKey =
        "companionGrowthHighestPoints"


    /// Keep the key introduced by CompanionIdentity so older builds remain
    /// compatible with the new growth system.
    private let stageKey =
        "companionStage"


    /// Highest growth stage whose reveal the user has already seen.
    /// Using the highest stage makes the celebration durable and prevents
    /// repeated popups every time the app refreshes its growth metrics.
    private let lastCelebratedStageKey =
        "companionGrowthLastCelebratedStage"


    private let milestonesKey =
        "companionGrowthMilestones"


    // =====================================================
    // MARK: - Existing Stores
    // =====================================================

    private let progressStore =
        JourneyProgressStore.shared


    private let noteService =
        StudyNoteService.shared


    private let reflectionStore =
        JourneyReflectionStore.shared


    private let summaryStore =
        JourneySummaryStore.shared


    private let storageService =
        StorageService.shared


    private var cancellables =
        Set<AnyCancellable>()


    // =====================================================
    // MARK: - Init
    // =====================================================

    private init() {

        restorePersistedFloor()
        loadMilestones()
        backfillCurrentStageIfNeeded()
        bindToExistingStores()
        refresh()
    }


    // =====================================================
    // MARK: - Public Progress
    // =====================================================

    var nextStage:
        CompanionStage? {

        stage.nextStage
    }


    var pointsForNextStage:
        Int? {

        nextStage?
            .minimumGrowthPoints
    }


    var pointsRemaining:
        Int? {

        guard
            let threshold =
                pointsForNextStage
        else {

            return nil
        }


        return max(
            threshold - points,
            0
        )
    }


    var sortedMilestones:
        [CompanionGrowthMilestone] {

        milestones
            .sorted {
                $0.reachedAt > $1.reachedAt
            }
    }


    /// Marks the currently pending growth moment as seen.
    /// The Companion remains at the new stage; this only dismisses the
    /// one-time celebration.
    func acknowledgePendingStageReveal() {

        guard
            let revealedStage =
                pendingStageReveal
        else {

            return
        }


        let previouslyCelebrated =
            UserDefaults.standard
                .integer(
                    forKey:
                        lastCelebratedStageKey
                )


        UserDefaults.standard.set(
            max(
                previouslyCelebrated,
                revealedStage.rawValue
            ),
            forKey:
                lastCelebratedStageKey
        )


        pendingStageReveal =
            nil
    }


    #if DEBUG
    /// Developer-only preview used to inspect the reveal without changing
    /// real growth points or the user's persisted stage.
    func previewStageReveal(
        _ stage:
            CompanionStage
    ) {

        pendingStageReveal =
            stage
    }
    #endif


    var progressToNextStage:
        Double {

        guard
            let next =
                nextStage
        else {

            return 1
        }


        let currentFloor =
            stage.minimumGrowthPoints


        let nextFloor =
            next.minimumGrowthPoints


        let span =
            max(
                nextFloor - currentFloor,
                1
            )


        let earnedInsideStage =
            max(
                points - currentFloor,
                0
            )


        return min(
            max(
                Double(earnedInsideStage)
                /
                Double(span),
                0
            ),
            1
        )
    }


    // =====================================================
    // MARK: - Refresh
    // =====================================================

    /// Rebuilds the growth score from data the app already owns.
    ///
    /// This also makes the system retroactive: an existing user who already
    /// completed checkpoints/reflections does not start back at zero simply
    /// because Companion growth was added later.
    func refresh() {

        let newMetrics =
            calculateMetrics()


        let calculatedPoints =
            score(
                newMetrics
            )


        let persistedHighestPoints =
            UserDefaults.standard
                .integer(
                    forKey:
                        highestPointsKey
                )


        let lifetimePoints =
            max(
                calculatedPoints,
                persistedHighestPoints
            )


        let calculatedStage =
            CompanionStage.stage(
                forGrowthPoints:
                    lifetimePoints
            )


        let persistedStage =
            CompanionStage(
                rawValue:
                    UserDefaults.standard
                        .integer(
                            forKey:
                                stageKey
                        )
            )
            ?? .egg


        let lifetimeStage =
            maxStage(
                persistedStage,
                calculatedStage
            )


        if Thread.isMainThread {

            apply(
                metrics:
                    newMetrics,
                points:
                    lifetimePoints,
                stage:
                    lifetimeStage
            )

        } else {

            DispatchQueue.main.async {

                self.apply(
                    metrics:
                        newMetrics,
                    points:
                        lifetimePoints,
                    stage:
                        lifetimeStage
                )
            }
        }
    }


    // =====================================================
    // MARK: - Store Binding
    // =====================================================

    private func bindToExistingStores() {

        progressStore
            .$completedCheckpoints
            .dropFirst()
            .receive(
                on:
                    DispatchQueue.main
            )
            .sink {
                [weak self] _ in

                self?.refresh()
            }
            .store(
                in:
                    &cancellables
            )


        noteService
            .$notes
            .dropFirst()
            .receive(
                on:
                    DispatchQueue.main
            )
            .sink {
                [weak self] _ in

                self?.refresh()
            }
            .store(
                in:
                    &cancellables
            )


        reflectionStore
            .$records
            .dropFirst()
            .receive(
                on:
                    DispatchQueue.main
            )
            .sink {
                [weak self] _ in

                self?.refresh()
            }
            .store(
                in:
                    &cancellables
            )


        summaryStore
            .$records
            .dropFirst()
            .receive(
                on:
                    DispatchQueue.main
            )
            .sink {
                [weak self] _ in

                self?.refresh()
            }
            .store(
                in:
                    &cancellables
            )
    }


    // =====================================================
    // MARK: - Metrics
    // =====================================================

    private func calculateMetrics()
        -> CompanionGrowthMetrics {

        let completedCheckpointCount =
            progressStore
                .completedCheckpoints
                .values
                .reduce(0) {
                    partialResult,
                    ids in

                    partialResult
                    +
                    ids.count
                }


        let checkpointReflectionCount =
            noteService
                .notes
                .filter {
                    note in

                    guard
                        note.type == .reflection
                    else {

                        return false
                    }


                    return !note.text
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        )
                        .isEmpty
                }
                .count


        let finalJourneyReflectionCount =
            reflectionStore
                .records
                .filter {
                    $0.hasOverallReflection
                }
                .count


        let journeySummaryCount =
            summaryStore
                .records
                .count


        let completedJourneyCount =
            calculateCompletedJourneyCount()


        return CompanionGrowthMetrics(
            completedCheckpoints:
                completedCheckpointCount,
            checkpointReflections:
                checkpointReflectionCount,
            completedJourneys:
                completedJourneyCount,
            finalJourneyReflections:
                finalJourneyReflectionCount,
            journeySummaries:
                journeySummaryCount
        )
    }


    private func calculateCompletedJourneyCount()
        -> Int {

        var completedJourneyIDs =
            Set<String>()


        let foundationJourney =
            JourneyLibrary.meetJesus


        if progressStore
            .isJourneyComplete(
                foundationJourney
            ) {

            completedJourneyIDs.insert(
                foundationJourney.id
            )
        }


        let personalizedRecords =
            storageService
                .loadPersonalizedJourneyRecords()


        for record in personalizedRecords {

            if progressStore
                .isJourneyComplete(
                    record.journey
                ) {

                completedJourneyIDs.insert(
                    record.journey.id
                )
            }
        }


        return completedJourneyIDs.count
    }


    // =====================================================
    // MARK: - Score
    // =====================================================

    private func score(
        _ metrics:
            CompanionGrowthMetrics
    ) -> Int {

        metrics.completedCheckpoints
        *
        Weight.checkpoint

        +

        metrics.checkpointReflections
        *
        Weight.checkpointReflection

        +

        metrics.completedJourneys
        *
        Weight.completedJourney

        +

        metrics.finalJourneyReflections
        *
        Weight.finalJourneyReflection

        +

        metrics.journeySummaries
        *
        Weight.journeySummary
    }


    // =====================================================
    // MARK: - Apply / Persist
    // =====================================================

    private func apply(
        metrics:
            CompanionGrowthMetrics,
        points:
            Int,
        stage:
            CompanionStage
    ) {

        let previousStage =
            self.stage


        self.metrics =
            metrics


        self.points =
            points


        self.stage =
            stage


        if stage.rawValue > previousStage.rawValue {

            recordMilestoneIfNeeded(
                stage: stage,
                reachedAt: Date(),
                isBackfilled: false
            )
        }


        // -------------------------------------------------
        // One-Time Growth Reveal
        // -------------------------------------------------
        //
        // Do not celebrate the initial egg stage. Any real stage above egg
        // is shown once, including retroactive growth for an existing user.
        // If someone jumps more than one threshold before reopening the app,
        // celebrate the highest stage they actually reached rather than
        // forcing several popups in a row.

        let lastCelebratedStageRaw =
            UserDefaults.standard
                .integer(
                    forKey:
                        lastCelebratedStageKey
                )


        if stage != .egg,
           stage.rawValue >
            lastCelebratedStageRaw {

            pendingStageReveal =
                stage
        }


        UserDefaults.standard.set(
            points,
            forKey:
                highestPointsKey
        )


        UserDefaults.standard.set(
            stage.rawValue,
            forKey:
                stageKey
        )
    }


    // =====================================================
    // MARK: - Milestone History
    // =====================================================

    private func recordMilestoneIfNeeded(
        stage: CompanionStage,
        reachedAt: Date,
        isBackfilled: Bool
    ) {

        guard stage != .egg else {
            return
        }


        guard !milestones.contains(
            where: {
                $0.stage == stage
            }
        ) else {

            return
        }


        milestones.append(
            CompanionGrowthMilestone(
                stage: stage,
                reachedAt: reachedAt,
                isBackfilled: isBackfilled
            )
        )


        persistMilestones()
    }


    private func backfillCurrentStageIfNeeded() {

        guard stage != .egg else {
            return
        }


        recordMilestoneIfNeeded(
            stage: stage,
            reachedAt: Date(),
            isBackfilled: true
        )
    }


    private func persistMilestones() {

        do {

            let data =
                try JSONEncoder()
                    .encode(
                        milestones
                    )


            UserDefaults.standard.set(
                data,
                forKey: milestonesKey
            )

        } catch {

            print(
                "Companion milestone save error:",
                error
            )
        }
    }


    private func loadMilestones() {

        guard
            let data =
                UserDefaults.standard.data(
                    forKey: milestonesKey
                )
        else {

            milestones = []
            return
        }


        do {

            milestones =
                try JSONDecoder()
                    .decode(
                        [CompanionGrowthMilestone].self,
                        from: data
                    )

        } catch {

            print(
                "Companion milestone load error:",
                error
            )

            milestones = []
        }
    }


    private func restorePersistedFloor() {

        points =
            UserDefaults.standard
                .integer(
                    forKey:
                        highestPointsKey
                )


        stage =
            CompanionStage(
                rawValue:
                    UserDefaults.standard
                        .integer(
                            forKey:
                                stageKey
                        )
            )
            ?? .egg
    }


    private func maxStage(
        _ lhs:
            CompanionStage,
        _ rhs:
            CompanionStage
    ) -> CompanionStage {

        lhs.rawValue >= rhs.rawValue
        ? lhs
        : rhs
    }
}
