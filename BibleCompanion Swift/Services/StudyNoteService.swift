import Foundation
import Combine


final class StudyNoteService:
    ObservableObject {

    static let shared =
        StudyNoteService()


    @Published
    private(set) var notes:
        [StudyNote] = []


    private let storageKey =
        "bibleCompanionStudyNotes"


    private init() {

        load()
    }


    // =====================================================
    // MARK: - Reflection Lookup
    // =====================================================

    func reflection(
        journeyID: String,
        checkpointID: String
    ) -> StudyNote? {

        notes.first {

            $0.type == .reflection
            &&
            $0.journeyID == journeyID
            &&
            $0.checkpointID == checkpointID
        }
    }


    // =====================================================
    // MARK: - Reflections for Journey
    // =====================================================

    /// Returns checkpoint reflections in the SAME ORDER
    /// as the checkpoints in the JourneyPath.
    ///
    /// This is useful for:
    /// - JourneyReviewView
    /// - end-of-journey summaries
    /// - future AI reflection summaries
    func reflections(
        for journey: JourneyPath
    ) -> [StudyNote] {

        journey
            .checkpoints
            .compactMap { checkpoint in

                reflection(

                    journeyID:
                        journey.id,

                    checkpointID:
                        checkpoint.id
                )
            }
    }


    // =====================================================
    // MARK: - Reflection for Checkpoint
    // =====================================================

    func reflection(
        for checkpoint: JourneyCheckpoint,
        in journey: JourneyPath
    ) -> StudyNote? {

        reflection(

            journeyID:
                journey.id,

            checkpointID:
                checkpoint.id
        )
    }


    // =====================================================
    // MARK: - Reflection Text
    // =====================================================

    /// Convenience helper for views that only need
    /// the actual saved text.
    func reflectionText(
        for checkpoint: JourneyCheckpoint,
        in journey: JourneyPath
    ) -> String? {

        guard
            let note =
                reflection(
                    for:
                        checkpoint,
                    in:
                        journey
                )
        else {

            return nil
        }


        let cleaned =
            note
                .text
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        return cleaned.isEmpty
        ? nil
        : cleaned
    }


    // =====================================================
    // MARK: - Reflection Count
    // =====================================================

    func reflectionCount(
        for journey: JourneyPath
    ) -> Int {

        reflections(
            for:
                journey
        )
        .count
    }


    // =====================================================
    // MARK: - Has Any Reflections
    // =====================================================

    func hasReflections(
        for journey: JourneyPath
    ) -> Bool {

        reflectionCount(
            for:
                journey
        )
        >
        0
    }


    // =====================================================
    // MARK: - Has Reflection for Checkpoint
    // =====================================================

    func hasReflection(
        for checkpoint: JourneyCheckpoint,
        in journey: JourneyPath
    ) -> Bool {

        reflection(
            for:
                checkpoint,
            in:
                journey
        )
        !=
        nil
    }


    // =====================================================
    // MARK: - Save Reflection
    // =====================================================

    func saveReflection(
        journey: JourneyPath,
        checkpoint: JourneyCheckpoint,
        text: String
    ) {

        let cleaned =
            text
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        // -------------------------------------------------
        // Empty reflection = remove stored version
        // -------------------------------------------------

        if cleaned.isEmpty {

            removeReflection(

                journeyID:
                    journey.id,

                checkpointID:
                    checkpoint.id
            )


            return
        }


        // -------------------------------------------------
        // Update Existing Reflection
        // -------------------------------------------------

        if let index =
            notes.firstIndex(
                where: {

                    $0.type == .reflection
                    &&
                    $0.journeyID == journey.id
                    &&
                    $0.checkpointID == checkpoint.id
                }
            ) {

            notes[index].text =
                text


            notes[index].updatedAt =
                Date()


            save()


            return
        }


        // -------------------------------------------------
        // Create New Reflection
        // -------------------------------------------------

        let note =
            StudyNote(

                id:
                    UUID(),

                createdAt:
                    Date(),

                updatedAt:
                    Date(),

                journeyID:
                    journey.id,

                checkpointID:
                    checkpoint.id,

                passage:
                    checkpoint.passage,

                title:
                    checkpoint.title,

                text:
                    text,

                type:
                    .reflection
            )


        notes.append(
            note
        )


        save()
    }


    // =====================================================
    // MARK: - Remove Reflection
    // =====================================================

    func removeReflection(
        journeyID: String,
        checkpointID: String
    ) {

        notes.removeAll {

            $0.type == .reflection
            &&
            $0.journeyID == journeyID
            &&
            $0.checkpointID == checkpointID
        }


        save()
    }


    // =====================================================
    // MARK: - Remove All Reflections for Journey
    // =====================================================

    func removeReflections(
        for journey: JourneyPath
    ) {

        notes.removeAll {

            $0.type == .reflection
            &&
            $0.journeyID == journey.id
        }


        save()
    }


    // =====================================================
    // MARK: - Notes for Passage
    // =====================================================

    func notes(
        forPassage passage: String
    ) -> [StudyNote] {

        notes
            .filter {

                $0.passage ==
                    passage
            }
            .sorted {

                $0.updatedAt >
                    $1.updatedAt
            }
    }


    // =====================================================
    // MARK: - Notes for Journey
    // =====================================================

    func notes(
        forJourneyID journeyID: String
    ) -> [StudyNote] {

        notes
            .filter {

                $0.journeyID ==
                    journeyID
            }
            .sorted {

                $0.updatedAt >
                    $1.updatedAt
            }
    }


    // =====================================================
    // MARK: - Delete
    // =====================================================

    func delete(
        note: StudyNote
    ) {

        notes.removeAll {

            $0.id ==
                note.id
        }


        save()
    }


    // =====================================================
    // MARK: - Storage
    // =====================================================

    private func save() {

        do {

            let data =
                try JSONEncoder()
                    .encode(
                        notes
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
                "Study note save error:",
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

            notes =
                try JSONDecoder()
                    .decode(

                        [StudyNote].self,

                        from:
                            data
                    )

        } catch {

            print(
                "Study note load error:",
                error
            )
        }
    }
}
