//
//  JourneyReflectionStore.swift
//  BibleCompanion Swift
//
//  Created by Shopify on 10/2/26.
//

import Foundation
import Combine


// =========================================================
// MARK: - Journey Reflection Record
// =========================================================

struct JourneyReflectionRecord:
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
    // MARK: Reflection
    // =====================================================

    var overallReflection:
        String


    var remainingQuestions:
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
        journeyFocus: String? = nil,
        overallReflection: String = "",
        remainingQuestions: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {

        self.journeyID =
            journeyID


        self.journeyTitle =
            journeyTitle


        self.journeyFocus =
            journeyFocus


        self.overallReflection =
            overallReflection


        self.remainingQuestions =
            remainingQuestions


        self.createdAt =
            createdAt


        self.updatedAt =
            updatedAt
    }


    // =====================================================
    // MARK: Helpers
    // =====================================================

    var cleanedOverallReflection:
        String {

        overallReflection
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
    }


    var cleanedRemainingQuestions:
        String {

        remainingQuestions
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
    }


    var hasOverallReflection:
        Bool {

        !cleanedOverallReflection
            .isEmpty
    }


    var hasRemainingQuestions:
        Bool {

        !cleanedRemainingQuestions
            .isEmpty
    }


    var hasContent:
        Bool {

        hasOverallReflection
        ||
        hasRemainingQuestions
    }
}


// =========================================================
// MARK: - Journey Reflection Store
// =========================================================

final class JourneyReflectionStore:
    ObservableObject {

    // =====================================================
    // MARK: Singleton
    // =====================================================

    static let shared =
        JourneyReflectionStore()


    // =====================================================
    // MARK: Published State
    // =====================================================

    @Published
    private(set) var records:
        [JourneyReflectionRecord] = []


    // =====================================================
    // MARK: Storage
    // =====================================================

    private let storageKey =
        "bibleCompanionJourneyReflections"


    // =====================================================
    // MARK: Init
    // =====================================================

    private init() {

        load()
    }


    // =====================================================
    // MARK: - Lookup
    // =====================================================

    func reflection(
        for journey:
            JourneyPath
    ) -> JourneyReflectionRecord? {

        reflection(
            journeyID:
                journey.id
        )
    }


    func reflection(
        journeyID:
            String
    ) -> JourneyReflectionRecord? {

        records.first {

            $0.journeyID ==
                journeyID
        }
    }


    // =====================================================
    // MARK: - Overall Reflection
    // =====================================================

    func overallReflection(
        for journey:
            JourneyPath
    ) -> String {

        reflection(
            for:
                journey
        )?
        .overallReflection
        ??
        ""
    }


    func saveOverallReflection(
        journey:
            JourneyPath,
        text:
            String
    ) {

        update(
            journey:
                journey,
            overallReflection:
                text,
            remainingQuestions:
                nil
        )
    }


    // =====================================================
    // MARK: - Remaining Questions
    // =====================================================

    func remainingQuestions(
        for journey:
            JourneyPath
    ) -> String {

        reflection(
            for:
                journey
        )?
        .remainingQuestions
        ??
        ""
    }


    func saveRemainingQuestions(
        journey:
            JourneyPath,
        text:
            String
    ) {

        update(
            journey:
                journey,
            overallReflection:
                nil,
            remainingQuestions:
                text
        )
    }


    // =====================================================
    // MARK: - Save Both
    // =====================================================

    func save(
        journey:
            JourneyPath,
        overallReflection:
            String,
        remainingQuestions:
            String
    ) {

        update(
            journey:
                journey,
            overallReflection:
                overallReflection,
            remainingQuestions:
                remainingQuestions
        )
    }


    // =====================================================
    // MARK: - Update
    // =====================================================

    private func update(
        journey:
            JourneyPath,
        overallReflection:
            String?,
        remainingQuestions:
            String?
    ) {

        // -------------------------------------------------
        // Existing Record
        // -------------------------------------------------

        if let index =
            records.firstIndex(
                where: {

                    $0.journeyID ==
                        journey.id
                }
            ) {

            if let overallReflection {

                records[index]
                    .overallReflection =
                    overallReflection
            }


            if let remainingQuestions {

                records[index]
                    .remainingQuestions =
                    remainingQuestions
            }


            records[index]
                .journeyTitle =
                journey.title


            records[index]
                .journeyFocus =
                cleanedFocus(
                    from:
                        journey
                )


            records[index]
                .updatedAt =
                Date()


            // ---------------------------------------------
            // If everything was cleared,
            // remove the record entirely.
            // ---------------------------------------------

            if !records[index]
                .hasContent {

                records.remove(
                    at:
                        index
                )
            }


            persist()


            return
        }


        // -------------------------------------------------
        // New Record
        // -------------------------------------------------

        let overall =
            overallReflection
            ??
            ""


        let remaining =
            remainingQuestions
            ??
            ""


        let cleanedOverall =
            overall
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        let cleanedRemaining =
            remaining
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        guard
            !cleanedOverall.isEmpty
            ||
            !cleanedRemaining.isEmpty
        else {

            return
        }


        let record =
            JourneyReflectionRecord(

                journeyID:
                    journey.id,

                journeyTitle:
                    journey.title,

                journeyFocus:
                    cleanedFocus(
                        from:
                            journey
                    ),

                overallReflection:
                    overall,

                remainingQuestions:
                    remaining
            )


        records.append(
            record
        )


        persist()
    }


    // =====================================================
    // MARK: - Has Overall Reflection
    // =====================================================

    func hasReflection(
        for journey:
            JourneyPath
    ) -> Bool {

        reflection(
            for:
                journey
        )?
        .hasOverallReflection
        ??
        false
    }


    // =====================================================
    // MARK: - Has Remaining Questions
    // =====================================================

    func hasRemainingQuestions(
        for journey:
            JourneyPath
    ) -> Bool {

        reflection(
            for:
                journey
        )?
        .hasRemainingQuestions
        ??
        false
    }


    // =====================================================
    // MARK: - Has Any Content
    // =====================================================

    func hasAnyContent(
        for journey:
            JourneyPath
    ) -> Bool {

        reflection(
            for:
                journey
        )?
        .hasContent
        ??
        false
    }


    // =====================================================
    // MARK: - Delete
    // =====================================================

    func deleteReflection(
        for journey:
            JourneyPath
    ) {

        deleteReflection(
            journeyID:
                journey.id
        )
    }


    func deleteReflection(
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
    // MARK: - All Reflections
    // =====================================================

    func allReflections()
        -> [JourneyReflectionRecord] {

        records
            .sorted {

                $0.updatedAt >
                    $1.updatedAt
            }
    }


    // =====================================================
    // MARK: - Focus Helper
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


    // =====================================================
    // MARK: - Persist
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
                "Journey reflection save error:",
                error
            )
        }
    }


    // =====================================================
    // MARK: - Load
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

            records =
                try JSONDecoder()
                    .decode(
                        [JourneyReflectionRecord]
                            .self,
                        from:
                            data
                    )

        } catch {

            print(
                "Journey reflection load error:",
                error
            )


            records =
                []
        }
    }
}
