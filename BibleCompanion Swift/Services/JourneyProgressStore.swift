import Foundation
import Combine


final class JourneyProgressStore:
    ObservableObject {

    static let shared =
        JourneyProgressStore()


    // =====================================================
    // MARK: - Published Progress
    // =====================================================

    /// Journey ID
    ///     ↓
    /// Set of completed checkpoint IDs
    ///
    /// Example:
    ///
    /// "meet_jesus"
    ///     → ["meet_jesus_1", "meet_jesus_2"]
    ///
    /// "personalized_anger_abc123"
    ///     → ["anger_1", "anger_2"]
    ///
    /// Because personalized journeys have unique IDs,
    /// progress from different paths never collides.
    @Published
    private(set)
    var completedCheckpoints:
        [String: Set<String>] = [:]


    /// Journey ID
    ///     ↓
    /// Checkpoint ID
    ///     ↓
    /// Completion date
    ///
    /// This allows the app to later say things like:
    ///
    /// "You studied this three weeks ago."
    ///
    /// or:
    ///
    /// "The last thing you worked through was Jonah."
    @Published
    private(set)
    var completionDates:
        [String: [String: Date]] = [:]


    // =====================================================
    // MARK: - Storage Keys
    // =====================================================

    /// IMPORTANT:
    ///
    /// Keep this exact key so existing Meet Jesus
    /// progress remains intact.
    private let storageKey =
        "journeyProgress"


    /// New storage added for completion timestamps.
    private let completionDatesStorageKey =
        "journeyProgressCompletionDates"


    // =====================================================
    // MARK: - Init
    // =====================================================

    private init() {

        load()
        loadCompletionDates()
    }


    // =====================================================
    // MARK: - Complete Checkpoint
    // =====================================================

    func complete(
        _ checkpoint: JourneyCheckpoint,
        in journey: JourneyPath
    ) {

        var completed =
            completedCheckpoints[
                journey.id
            ]
            ?? []


        let wasAlreadyCompleted =
            completed.contains(
                checkpoint.id
            )


        completed.insert(
            checkpoint.id
        )


        completedCheckpoints[
            journey.id
        ] = completed


        // Only record the original completion time.
        //
        // Reviewing an old checkpoint later should
        // not make it look newly completed.

        if !wasAlreadyCompleted {

            var journeyDates =
                completionDates[
                    journey.id
                ]
                ?? [:]


            journeyDates[
                checkpoint.id
            ] = Date()


            completionDates[
                journey.id
            ] = journeyDates
        }


        save()
        saveCompletionDates()
    }


    // =====================================================
    // MARK: - Remove Completion
    // =====================================================

    /// Useful if we later add:
    ///
    /// "Restart from this checkpoint"
    ///
    /// or development/debug controls.
    func markIncomplete(
        _ checkpoint: JourneyCheckpoint,
        in journey: JourneyPath
    ) {

        var completed =
            completedCheckpoints[
                journey.id
            ]
            ?? []


        completed.remove(
            checkpoint.id
        )


        completedCheckpoints[
            journey.id
        ] = completed


        var journeyDates =
            completionDates[
                journey.id
            ]
            ?? [:]


        journeyDates.removeValue(
            forKey:
                checkpoint.id
        )


        completionDates[
            journey.id
        ] = journeyDates


        save()
        saveCompletionDates()
    }


    // =====================================================
    // MARK: - Completion State
    // =====================================================

    func isCompleted(
        _ checkpoint: JourneyCheckpoint,
        in journey: JourneyPath
    ) -> Bool {

        completedCheckpoints[
            journey.id
        ]?
            .contains(
                checkpoint.id
            )
        ?? false
    }


    // =====================================================
    // MARK: - Completed Checkpoints
    // =====================================================

    /// Returns completed checkpoints in their
    /// actual journey order.
    ///
    /// This will be useful for:
    ///
    /// "What you've covered"
    ///
    /// ✓ Thomas
    /// ✓ Mark 9
    /// ✓ Habakkuk
    func completedCheckpointList(
        in journey: JourneyPath
    ) -> [JourneyCheckpoint] {

        journey
            .checkpoints
            .filter {

                isCompleted(
                    $0,
                    in: journey
                )
            }
            .sorted {

                $0.order <
                    $1.order
            }
    }


    /// Returns only the IDs that are still valid
    /// for the current journey definition.
    ///
    /// This prevents an old/stale checkpoint ID
    /// from artificially increasing progress if
    /// a journey template changes later.
    func completedCheckpointIDs(
        in journey: JourneyPath
    ) -> Set<String> {

        let validIDs =
            Set(
                journey
                    .checkpoints
                    .map {
                        $0.id
                    }
            )


        let storedIDs =
            completedCheckpoints[
                journey.id
            ]
            ?? []


        return storedIDs
            .intersection(
                validIDs
            )
    }


    // =====================================================
    // MARK: - Current Checkpoint
    // =====================================================

    func currentCheckpoint(
        in journey: JourneyPath
    ) -> JourneyCheckpoint? {

        journey
            .checkpoints
            .sorted {

                $0.order <
                    $1.order
            }
            .first {

                !isCompleted(
                    $0,
                    in: journey
                )
            }
    }


    func isCurrent(
        _ checkpoint: JourneyCheckpoint,
        in journey: JourneyPath
    ) -> Bool {

        currentCheckpoint(
            in: journey
        )?
            .id
        ==
        checkpoint.id
    }


    // =====================================================
    // MARK: - Availability
    // =====================================================

    /// For now journeys remain sequential:
    ///
    /// completed checkpoints
    ///     → available
    ///
    /// current checkpoint
    ///     → available
    ///
    /// future checkpoints
    ///     → locked
    func isAvailable(
        _ checkpoint: JourneyCheckpoint,
        in journey: JourneyPath
    ) -> Bool {

        isCompleted(
            checkpoint,
            in: journey
        )
        ||
        isCurrent(
            checkpoint,
            in: journey
        )
    }


    // =====================================================
    // MARK: - Previous / Last Completed
    // =====================================================

    /// The furthest completed checkpoint in journey order.
    ///
    /// This is useful for reminders such as:
    ///
    /// "Last time you worked through Jonah."
    func lastCompletedCheckpoint(
        in journey: JourneyPath
    ) -> JourneyCheckpoint? {

        completedCheckpointList(
            in: journey
        )
        .last
    }


    /// Returns the most recently completed checkpoint
    /// based on actual completion time.
    ///
    /// This can differ from the highest checkpoint
    /// if the user reviews or changes progress later.
    func mostRecentlyCompletedCheckpoint(
        in journey: JourneyPath
    ) -> JourneyCheckpoint? {

        let dates =
            completionDates[
                journey.id
            ]
            ?? [:]


        return completedCheckpointList(
            in: journey
        )
        .max {

            let firstDate =
                dates[
                    $0.id
                ]
                ?? .distantPast


            let secondDate =
                dates[
                    $1.id
                ]
                ?? .distantPast


            return firstDate <
                secondDate
        }
    }


    // =====================================================
    // MARK: - Completion Date
    // =====================================================

    func completedAt(
        _ checkpoint: JourneyCheckpoint,
        in journey: JourneyPath
    ) -> Date? {

        completionDates[
            journey.id
        ]?[
            checkpoint.id
        ]
    }


    // =====================================================
    // MARK: - Progress
    // =====================================================

    func completedCount(
        in journey: JourneyPath
    ) -> Int {

        completedCheckpointIDs(
            in: journey
        )
        .count
    }


    func remainingCount(
        in journey: JourneyPath
    ) -> Int {

        max(
            journey.checkpoints.count
            -
            completedCount(
                in: journey
            ),
            0
        )
    }


    func progress(
        in journey: JourneyPath
    ) -> Double {

        guard
            !journey
                .checkpoints
                .isEmpty
        else {

            return 0
        }


        return Double(

            completedCount(
                in: journey
            )

        )
        /
        Double(

            journey
                .checkpoints
                .count
        )
    }


    // =====================================================
    // MARK: - Journey Completion
    // =====================================================

    func isJourneyComplete(
        _ journey: JourneyPath
    ) -> Bool {

        guard
            !journey
                .checkpoints
                .isEmpty
        else {

            return false
        }


        return
            completedCount(
                in: journey
            )
            ==
            journey
                .checkpoints
                .count
    }


    // =====================================================
    // MARK: - Resume Context
    // =====================================================

    /// Gives us a convenient snapshot for the Home screen.
    ///
    /// Example:
    ///
    /// completed: 2
    /// total: 6
    /// current: Habakkuk
    /// previous: Mark 9
    struct JourneyProgressSnapshot {

        let completed:
            Int

        let total:
            Int

        let progress:
            Double

        let current:
            JourneyCheckpoint?

        let previous:
            JourneyCheckpoint?

        let isComplete:
            Bool
    }


    func snapshot(
        for journey: JourneyPath
    ) -> JourneyProgressSnapshot {

        JourneyProgressSnapshot(

            completed:
                completedCount(
                    in: journey
                ),

            total:
                journey
                    .checkpoints
                    .count,

            progress:
                progress(
                    in: journey
                ),

            current:
                currentCheckpoint(
                    in: journey
                ),

            previous:
                lastCompletedCheckpoint(
                    in: journey
                ),

            isComplete:
                isJourneyComplete(
                    journey
                )
        )
    }


    // =====================================================
    // MARK: - Reset One Journey
    // =====================================================

    func reset(
        journey: JourneyPath
    ) {

        completedCheckpoints
            .removeValue(
                forKey:
                    journey.id
            )


        completionDates
            .removeValue(
                forKey:
                    journey.id
            )


        save()
        saveCompletionDates()
    }


    // =====================================================
    // MARK: - Delete Journey Progress
    // =====================================================

    /// This should NOT normally be called when a user
    /// changes personalized paths.
    ///
    /// Changing paths should preserve progress.
    ///
    /// Use this only when the user explicitly wants
    /// to erase the history of a path.
    func deleteProgress(
        for journeyID: String
    ) {

        completedCheckpoints
            .removeValue(
                forKey:
                    journeyID
            )


        completionDates
            .removeValue(
                forKey:
                    journeyID
            )


        save()
        saveCompletionDates()
    }


    // =====================================================
    // MARK: - Save Progress
    // =====================================================

    private func save() {

        do {

            let data =
                try JSONEncoder()
                    .encode(
                        completedCheckpoints
                    )


            UserDefaults
                .standard
                .set(
                    data,
                    forKey:
                        storageKey
                )

        } catch {

            print(
                "Journey progress save error:",
                error
            )
        }
    }


    // =====================================================
    // MARK: - Load Progress
    // =====================================================

    private func load() {

        guard
            let data =
                UserDefaults
                    .standard
                    .data(
                        forKey:
                            storageKey
                    )
        else {

            return
        }


        do {

            completedCheckpoints =
                try JSONDecoder()
                    .decode(
                        [String: Set<String>]
                            .self,
                        from:
                            data
                    )

        } catch {

            print(
                "Journey progress load error:",
                error
            )
        }
    }


    // =====================================================
    // MARK: - Save Completion Dates
    // =====================================================

    private func saveCompletionDates() {

        do {

            let data =
                try JSONEncoder()
                    .encode(
                        completionDates
                    )


            UserDefaults
                .standard
                .set(
                    data,
                    forKey:
                        completionDatesStorageKey
                )

        } catch {

            print(
                "Journey completion-date save error:",
                error
            )
        }
    }


    // =====================================================
    // MARK: - Load Completion Dates
    // =====================================================

    private func loadCompletionDates() {

        guard
            let data =
                UserDefaults
                    .standard
                    .data(
                        forKey:
                            completionDatesStorageKey
                    )
        else {

            return
        }


        do {

            completionDates =
                try JSONDecoder()
                    .decode(
                        [
                            String:
                                [
                                    String:
                                        Date
                                ]
                        ]
                        .self,
                        from:
                            data
                    )

        } catch {

            print(
                "Journey completion-date load error:",
                error
            )
        }
    }
}
