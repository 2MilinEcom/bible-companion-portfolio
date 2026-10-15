import Foundation


final class StorageService {

    static let shared =
        StorageService()


    private let defaults =
        UserDefaults.standard


    // =====================================================
    // MARK: - Storage Keys
    // =====================================================

    private let spiritualProfileKey =
        "spiritualProfile"


    // Keep this during the transition from the old
    // one-off recommendation system.
    private let journeyRecommendationKey =
        "journeyRecommendation"


    // New persistent personalized journey system.
    private let personalizedJourneyRecordsKey =
        "personalizedJourneyRecords"


    private init() {}


    // =====================================================
    // MARK: - Spiritual Profile
    // =====================================================

    func saveSpiritualProfile(
        _ profile: SpiritualProfile
    ) {

        do {

            let data =
                try JSONEncoder()
                    .encode(
                        profile
                    )


            defaults.set(
                data,
                forKey:
                    spiritualProfileKey
            )

        } catch {

            print(
                "Failed to save spiritual profile: \(error)"
            )
        }
    }


    func loadSpiritualProfile()
        -> SpiritualProfile? {

        guard
            let data =
                defaults.data(
                    forKey:
                        spiritualProfileKey
                )
        else {

            return nil
        }


        do {

            return try JSONDecoder()
                .decode(
                    SpiritualProfile.self,
                    from:
                        data
                )

        } catch {

            print(
                "Failed to load spiritual profile: \(error)"
            )

            return nil
        }
    }


    func clearSpiritualProfile() {

        defaults.removeObject(
            forKey:
                spiritualProfileKey
        )
    }


    // =====================================================
    // MARK: - Legacy Journey Recommendation
    // =====================================================

    /*
     Keep this section for now.

     Your current HomeViewModel still uses
     JourneyRecommendation while we transition
     Recommended for You into a full JourneyPath.

     Once the new personalized journey system is
     fully wired into Home, we can remove this
     legacy storage later.
    */

    func saveJourneyRecommendation(
        _ recommendation:
            JourneyRecommendation
    ) {

        do {

            let data =
                try JSONEncoder()
                    .encode(
                        recommendation
                    )


            defaults.set(
                data,
                forKey:
                    journeyRecommendationKey
            )

        } catch {

            print(
                "Failed to save journey recommendation: \(error)"
            )
        }
    }


    func loadJourneyRecommendation()
        -> JourneyRecommendation? {

        guard
            let data =
                defaults.data(
                    forKey:
                        journeyRecommendationKey
                )
        else {

            return nil
        }


        do {

            return try JSONDecoder()
                .decode(
                    JourneyRecommendation.self,
                    from:
                        data
                )

        } catch {

            print(
                "Failed to load journey recommendation: \(error)"
            )

            return nil
        }
    }


    func clearJourneyRecommendation() {

        defaults.removeObject(
            forKey:
                journeyRecommendationKey
        )
    }


    // =====================================================
    // MARK: - Personalized Journey Records
    // =====================================================

    /// Returns every personalized journey the user has
    /// created or accepted.
    ///
    /// This includes:
    ///
    /// - active
    /// - paused
    /// - completed
    func loadPersonalizedJourneyRecords()
        -> [PersonalizedJourneyRecord] {

        guard
            let data =
                defaults.data(
                    forKey:
                        personalizedJourneyRecordsKey
                )
        else {

            return []
        }


        do {

            return try JSONDecoder()
                .decode(
                    [PersonalizedJourneyRecord]
                        .self,
                    from:
                        data
                )

        } catch {

            print(
                "Failed to load personalized journeys: \(error)"
            )

            return []
        }
    }


    private func savePersonalizedJourneyRecords(
        _ records:
            [PersonalizedJourneyRecord]
    ) {

        do {

            let data =
                try JSONEncoder()
                    .encode(
                        records
                    )


            defaults.set(
                data,
                forKey:
                    personalizedJourneyRecordsKey
            )

        } catch {

            print(
                "Failed to save personalized journeys: \(error)"
            )
        }
    }


    // =====================================================
    // MARK: - Active Personalized Journey
    // =====================================================

    /// There should normally be only one active
    /// personalized journey at a time.
    func loadActivePersonalizedJourney()
        -> PersonalizedJourneyRecord? {

        loadPersonalizedJourneyRecords()
            .first {

                $0.status ==
                    .active
            }
    }


    /// Convenience method when the UI only needs
    /// the JourneyPath itself.
    func loadActivePersonalizedPath()
        -> JourneyPath? {

        loadActivePersonalizedJourney()?
            .journey
    }


    /// Makes this journey the user's current path.
    ///
    /// IMPORTANT:
    ///
    /// Any previous active path is PAUSED,
    /// not deleted.
    ///
    /// That means:
    ///
    /// Doubt 2/6
    ///     ↓ change path
    /// Anger 0/7
    ///
    /// Doubt remains stored as paused at 2/6.
    func activatePersonalizedJourney(
        _ journey: JourneyPath
    ) {

        var records =
            loadPersonalizedJourneyRecords()


        let now =
            Date()


        // -------------------------------------------------
        // Pause any currently active journey
        // -------------------------------------------------

        for index in records.indices {

            guard
                records[index]
                    .status
                ==
                .active
            else {

                continue
            }


            // If this is already the same journey,
            // we do not need to pause it.
            guard
                records[index]
                    .journey
                    .id
                !=
                journey.id
            else {

                continue
            }


            records[index]
                .status =
                .paused


            records[index]
                .endedAt =
                now


            records[index]
                .lastUpdatedAt =
                now
        }


        // -------------------------------------------------
        // Existing Journey
        // -------------------------------------------------

        if let existingIndex =
            records.firstIndex(
                where: {

                    $0.journey.id ==
                        journey.id
                }
            ) {

            records[
                existingIndex
            ]
            .status =
                .active


            records[
                existingIndex
            ]
            .endedAt =
                nil


            records[
                existingIndex
            ]
            .lastUpdatedAt =
                now


        // -------------------------------------------------
        // Brand-New Journey
        // -------------------------------------------------

        } else {

            let record =
                PersonalizedJourneyRecord(

                    journey:
                        journey,

                    status:
                        .active,

                    startedAt:
                        now,

                    lastUpdatedAt:
                        now,

                    endedAt:
                        nil
                )


            records.append(
                record
            )
        }


        savePersonalizedJourneyRecords(
            records
        )
    }


    // =====================================================
    // MARK: - Resume Old Journey
    // =====================================================

    /// Reopens a paused or completed path.
    ///
    /// Its checkpoint progress is stored separately in
    /// JourneyProgressStore using journey.id, so resuming
    /// the path automatically restores where they were.
    func resumePersonalizedJourney(
        journeyID: String
    ) {

        var records =
            loadPersonalizedJourneyRecords()


        guard
            records.contains(
                where: {

                    $0.journey.id ==
                        journeyID
                }
            )
        else {

            return
        }


        let now =
            Date()


        // Pause whatever is currently active.

        for index in records.indices {

            if records[index]
                .status
                ==
                .active {

                records[index]
                    .status =
                    .paused


                records[index]
                    .endedAt =
                    now


                records[index]
                    .lastUpdatedAt =
                    now
            }
        }


        // Activate the selected path.

        guard
            let targetIndex =
                records.firstIndex(
                    where: {

                        $0.journey.id ==
                            journeyID
                    }
                )
        else {

            return
        }


        records[
            targetIndex
        ]
        .status =
            .active


        records[
            targetIndex
        ]
        .endedAt =
            nil


        records[
            targetIndex
        ]
        .lastUpdatedAt =
            now


        savePersonalizedJourneyRecords(
            records
        )
    }


    // =====================================================
    // MARK: - Pause Current Journey
    // =====================================================

    /// Useful when the user chooses:
    ///
    /// "Change Path"
    ///
    /// but has not chosen their new path yet.
    func pauseActivePersonalizedJourney() {

        var records =
            loadPersonalizedJourneyRecords()


        let now =
            Date()


        var changed =
            false


        for index in records.indices {

            guard
                records[index]
                    .status
                ==
                .active
            else {

                continue
            }


            records[index]
                .status =
                .paused


            records[index]
                .endedAt =
                now


            records[index]
                .lastUpdatedAt =
                now


            changed =
                true
        }


        if changed {

            savePersonalizedJourneyRecords(
                records
            )
        }
    }


    // =====================================================
    // MARK: - Complete Journey
    // =====================================================

    /// Called when every checkpoint has been completed
    /// AND the user indicates they are satisfied with
    /// this path.
    ///
    /// Completing checkpoints alone does not have to
    /// immediately force them out of the topic.
    func markPersonalizedJourneyCompleted(
        journeyID: String
    ) {

        var records =
            loadPersonalizedJourneyRecords()


        guard
            let index =
                records.firstIndex(
                    where: {

                        $0.journey.id ==
                            journeyID
                    }
                )
        else {

            return
        }


        let now =
            Date()


        records[
            index
        ]
        .status =
            .completed


        records[
            index
        ]
        .endedAt =
            now


        records[
            index
        ]
        .lastUpdatedAt =
            now


        savePersonalizedJourneyRecords(
            records
        )
    }


    // =====================================================
    // MARK: - Keep Working on Completed Topic
    // =====================================================

    /// If somebody finishes all checkpoints but says:
    ///
    /// "I still want to work on this"
    ///
    /// we can keep the path active instead of treating
    /// completion as "problem solved."
    func keepPersonalizedJourneyActive(
        journeyID: String
    ) {

        resumePersonalizedJourney(
            journeyID:
                journeyID
        )
    }


    // =====================================================
    // MARK: - Touch Journey
    // =====================================================

    /// Updates the journey's last activity time.
    ///
    /// We can call this whenever a checkpoint or
    /// reflection is completed.
    func touchPersonalizedJourney(
        journeyID: String
    ) {

        var records =
            loadPersonalizedJourneyRecords()


        guard
            let index =
                records.firstIndex(
                    where: {

                        $0.journey.id ==
                            journeyID
                    }
                )
        else {

            return
        }


        records[
            index
        ]
        .lastUpdatedAt =
            Date()


        savePersonalizedJourneyRecords(
            records
        )
    }


    // =====================================================
    // MARK: - Find One Journey
    // =====================================================

    func loadPersonalizedJourney(
        journeyID: String
    ) -> PersonalizedJourneyRecord? {

        loadPersonalizedJourneyRecords()
            .first {

                $0.journey.id ==
                    journeyID
            }
    }


    // =====================================================
    // MARK: - Past Journeys
    // =====================================================

    /// Everything except the current active path.
    ///
    /// Sorted with the most recently updated first.
    func loadPastPersonalizedJourneys()
        -> [PersonalizedJourneyRecord] {

        loadPersonalizedJourneyRecords()

            .filter {

                $0.status !=
                    .active
            }

            .sorted {

                $0.lastUpdatedAt >
                    $1.lastUpdatedAt
            }
    }


    // =====================================================
    // MARK: - Paused Journeys
    // =====================================================

    func loadPausedPersonalizedJourneys()
        -> [PersonalizedJourneyRecord] {

        loadPersonalizedJourneyRecords()

            .filter {

                $0.status ==
                    .paused
            }

            .sorted {

                $0.lastUpdatedAt >
                    $1.lastUpdatedAt
            }
    }


    // =====================================================
    // MARK: - Completed Journeys
    // =====================================================

    func loadCompletedPersonalizedJourneys()
        -> [PersonalizedJourneyRecord] {

        loadPersonalizedJourneyRecords()

            .filter {

                $0.status ==
                    .completed
            }

            .sorted {

                $0.lastUpdatedAt >
                    $1.lastUpdatedAt
            }
    }


    // =====================================================
    // MARK: - Delete One Personalized Journey
    // =====================================================

    /// This removes the journey record itself.
    ///
    /// It intentionally does NOT erase checkpoint
    /// progress automatically.
    ///
    /// If the user explicitly wants all associated
    /// progress erased too, JourneyProgressStore
    /// should handle that separately.
    func deletePersonalizedJourney(
        journeyID: String
    ) {

        var records =
            loadPersonalizedJourneyRecords()


        records.removeAll {

            $0.journey.id ==
                journeyID
        }


        savePersonalizedJourneyRecords(
            records
        )
    }


    // =====================================================
    // MARK: - Clear Personalized Journey History
    // =====================================================

    /// This is a destructive reset and should only be used
    /// when the user explicitly wants to remove their
    /// personalized journey history.
    ///
    /// Normal "Change Path" behavior should NEVER call this.
    func clearPersonalizedJourneyRecords() {

        defaults.removeObject(
            forKey:
                personalizedJourneyRecordsKey
        )
    }
}
