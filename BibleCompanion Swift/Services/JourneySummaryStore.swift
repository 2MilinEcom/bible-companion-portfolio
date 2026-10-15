//
//  JourneySummaryStore.swift
//  BibleCompanion Swift
//
//  Created by Shopify on 10/2/26.
//

import Foundation
import Combine
import CryptoKit


// =========================================================
// MARK: - Journey Summary Record
// =========================================================

struct JourneySummaryRecord:
    Identifiable,
    Codable,
    Hashable {

    // =====================================================
    // MARK: Identity
    // =====================================================

    var id:
        String {

        journeyID
    }


    let journeyID:
        String


    // =====================================================
    // MARK: Journey Snapshot
    // =====================================================

    var journeyTitle:
        String


    var journeyFocus:
        String?


    // =====================================================
    // MARK: Summary
    // =====================================================

    var summary:
        JourneySummaryResponse


    // =====================================================
    // MARK: Source Tracking
    // =====================================================

    /// Fingerprint of the journey + reflections that were used
    /// to create this summary.
    ///
    /// If the user later edits a reflection, this fingerprint
    /// will no longer match and the UI can offer to regenerate.
    var sourceFingerprint:
        String


    // =====================================================
    // MARK: Dates
    // =====================================================

    let createdAt:
        Date


    var updatedAt:
        Date


    // =====================================================
    // MARK: Init
    // =====================================================

    init(
        journeyID: String,
        journeyTitle: String,
        journeyFocus: String?,
        summary: JourneySummaryResponse,
        sourceFingerprint: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {

        self.journeyID =
            journeyID

        self.journeyTitle =
            journeyTitle

        self.journeyFocus =
            journeyFocus

        self.summary =
            summary

        self.sourceFingerprint =
            sourceFingerprint

        self.createdAt =
            createdAt

        self.updatedAt =
            updatedAt
    }
}


// =========================================================
// MARK: - Journey Summary Store
// =========================================================

final class JourneySummaryStore:
    ObservableObject {

    // =====================================================
    // MARK: Singleton
    // =====================================================

    static let shared =
        JourneySummaryStore()


    // =====================================================
    // MARK: Published State
    // =====================================================

    @Published
    private(set) var records:
        [JourneySummaryRecord] = []


    // =====================================================
    // MARK: Storage
    // =====================================================

    private let storageKey =
        "bibleCompanionJourneySummaries"


    // =====================================================
    // MARK: Init
    // =====================================================

    private init() {

        load()
    }


    // =====================================================
    // MARK: - Lookup
    // =====================================================

    func record(
        for journey:
            JourneyPath
    ) -> JourneySummaryRecord? {

        record(
            journeyID:
                journey.id
        )
    }


    func record(
        journeyID:
            String
    ) -> JourneySummaryRecord? {

        records.first {

            $0.journeyID ==
                journeyID
        }
    }


    func summary(
        for journey:
            JourneyPath
    ) -> JourneySummaryResponse? {

        record(
            for:
                journey
        )?
        .summary
    }


    func hasSummary(
        for journey:
            JourneyPath
    ) -> Bool {

        record(
            for:
                journey
        )
        !=
        nil
    }


    // =====================================================
    // MARK: - Save Summary
    // =====================================================

    func saveSummary(
        _ summary:
            JourneySummaryResponse,
        for journey:
            JourneyPath,
        checkpointReflections:
            [JourneySummaryCheckpointReflection],
        overallReflection:
            String,
        remainingQuestions:
            String
    ) {

        let fingerprint =
            sourceFingerprint(
                for:
                    journey,
                checkpointReflections:
                    checkpointReflections,
                overallReflection:
                    overallReflection,
                remainingQuestions:
                    remainingQuestions
            )


        let focus =
            cleanedFocus(
                from:
                    journey
            )


        if let index =
            records.firstIndex(
                where: {

                    $0.journeyID ==
                        journey.id
                }
            ) {

            records[index]
                .journeyTitle =
                journey.title


            records[index]
                .journeyFocus =
                focus


            records[index]
                .summary =
                summary


            records[index]
                .sourceFingerprint =
                fingerprint


            records[index]
                .updatedAt =
                Date()


            persist()


            return
        }


        let record =
            JourneySummaryRecord(

                journeyID:
                    journey.id,

                journeyTitle:
                    journey.title,

                journeyFocus:
                    focus,

                summary:
                    summary,

                sourceFingerprint:
                    fingerprint
            )


        records.append(
            record
        )


        persist()
    }


    // =====================================================
    // MARK: - Current / Stale
    // =====================================================

    func isSummaryCurrent(
        for journey:
            JourneyPath,
        checkpointReflections:
            [JourneySummaryCheckpointReflection],
        overallReflection:
            String,
        remainingQuestions:
            String
    ) -> Bool {

        guard
            let record =
                record(
                    for:
                        journey
                )
        else {

            return false
        }


        let currentFingerprint =
            sourceFingerprint(
                for:
                    journey,
                checkpointReflections:
                    checkpointReflections,
                overallReflection:
                    overallReflection,
                remainingQuestions:
                    remainingQuestions
            )


        return
            record
                .sourceFingerprint
            ==
            currentFingerprint
    }


    func isSummaryStale(
        for journey:
            JourneyPath,
        checkpointReflections:
            [JourneySummaryCheckpointReflection],
        overallReflection:
            String,
        remainingQuestions:
            String
    ) -> Bool {

        guard
            hasSummary(
                for:
                    journey
            )
        else {

            return false
        }


        return
            !isSummaryCurrent(
                for:
                    journey,
                checkpointReflections:
                    checkpointReflections,
                overallReflection:
                    overallReflection,
                remainingQuestions:
                    remainingQuestions
            )
    }


    // =====================================================
    // MARK: - Fingerprint
    // =====================================================

    func sourceFingerprint(
        for journey:
            JourneyPath,
        checkpointReflections:
            [JourneySummaryCheckpointReflection],
        overallReflection:
            String,
        remainingQuestions:
            String
    ) -> String {

        let normalizedReflections =
            checkpointReflections
                .map {
                    reflection
                    in

                    JourneySummaryCheckpointReflection(
                        checkpointID:
                            reflection
                                .checkpointID,
                        order:
                            reflection
                                .order,
                        title:
                            normalized(
                                reflection
                                    .title
                            ),
                        passage:
                            normalized(
                                reflection
                                    .passage
                            ),
                        text:
                            normalized(
                                reflection
                                    .text
                            )
                    )
                }
                .filter {

                    !$0.text.isEmpty
                }
                .sorted {

                    if
                        $0.order
                        ==
                        $1.order {

                        return
                            $0.checkpointID
                            <
                            $1.checkpointID
                    }


                    return
                        $0.order
                        <
                        $1.order
                }


        let normalizedCheckpoints =
            journey
                .checkpoints
                .sorted {

                    $0.order <
                        $1.order
                }
                .map {
                    checkpoint
                    in

                    [
                        checkpoint.id,
                        String(
                            checkpoint.order
                        ),
                        normalized(
                            checkpoint.title
                        ),
                        normalized(
                            checkpoint.subtitle
                        ),
                        normalized(
                            checkpoint.passage
                        ),
                        normalized(
                            checkpoint.focusQuestion
                        ),
                    ]
                    .joined(
                        separator:
                            "|"
                    )
                }
                .joined(
                    separator:
                        "\n"
                )


        let reflectionBlock =
            normalizedReflections
                .map {
                    reflection
                    in

                    [
                        reflection
                            .checkpointID,
                        String(
                            reflection
                                .order
                        ),
                        reflection
                            .title,
                        reflection
                            .passage,
                        reflection
                            .text,
                    ]
                    .joined(
                        separator:
                            "|"
                    )
                }
                .joined(
                    separator:
                        "\n"
                )


        let focusBlock =
            [
                normalized(
                    journey
                        .focus?
                        .category
                    ??
                    ""
                ),
                normalized(
                    journey
                        .focus?
                        .label
                    ??
                    ""
                ),
                normalized(
                    journey
                        .focus?
                        .originalText
                    ??
                    ""
                ),
                normalized(
                    journey
                        .focus?
                        .trigger
                    ??
                    ""
                ),
                normalized(
                    journey
                        .focus?
                        .goal
                    ??
                    ""
                ),
            ]
            .joined(
                separator:
                    "|"
            )


        let source =
            """
            JOURNEY_ID
            \(journey.id)

            JOURNEY_TITLE
            \(normalized(journey.title))

            JOURNEY_SUBTITLE
            \(normalized(journey.subtitle))

            JOURNEY_FOCUS
            \(focusBlock)

            CHECKPOINTS
            \(normalizedCheckpoints)

            CHECKPOINT_REFLECTIONS
            \(reflectionBlock)

            OVERALL_REFLECTION
            \(normalized(overallReflection))

            REMAINING_QUESTIONS
            \(normalized(remainingQuestions))
            """


        let digest =
            SHA256.hash(
                data:
                    Data(
                        source.utf8
                    )
            )


        return
            digest
                .map {

                    String(
                        format:
                            "%02x",
                        $0
                    )
                }
                .joined()
    }


    // =====================================================
    // MARK: - Delete
    // =====================================================

    func deleteSummary(
        for journey:
            JourneyPath
    ) {

        deleteSummary(
            journeyID:
                journey.id
        )
    }


    func deleteSummary(
        journeyID:
            String
    ) {

        records.removeAll {

            $0.journeyID ==
                journeyID
        }


        persist()
    }


    // =====================================================
    // MARK: - All Summaries
    // =====================================================

    func allSummaries()
        -> [JourneySummaryRecord] {

        records
            .sorted {

                $0.updatedAt >
                    $1.updatedAt
            }
    }


    // =====================================================
    // MARK: - Helpers
    // =====================================================

    private func cleanedFocus(
        from journey:
            JourneyPath
    ) -> String? {

        guard
            let focus =
                journey
                    .focus?
                    .label
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    ),
            !focus.isEmpty
        else {

            return nil
        }


        return focus
    }


    private func normalized(
        _ value:
            String
    ) -> String {

        value
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .replacingOccurrences(
                of:
                    "\r\n",
                with:
                    "\n"
            )
            .replacingOccurrences(
                of:
                    "\r",
                with:
                    "\n"
            )
    }


    // =====================================================
    // MARK: - Persistence
    // =====================================================

    private func persist() {

        do {

            let data =
                try JSONEncoder()
                    .encode(
                        records
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
                "Journey summary save error:",
                error
            )
        }
    }


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

            records =
                try JSONDecoder()
                    .decode(
                        [JourneySummaryRecord]
                            .self,
                        from:
                            data
                    )

        } catch {

            print(
                "Journey summary load error:",
                error
            )


            records =
                []
        }
    }
}
