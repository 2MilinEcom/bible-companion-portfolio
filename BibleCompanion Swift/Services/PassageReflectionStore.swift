//
//  PassageReflectionStore.swift
//  BibleCompanion Swift
//
//  Created by Shopify on 10/3/26.
//

import Foundation
import Combine


// =========================================================
// MARK: - Passage Study Reflection
// =========================================================

struct PassageStudyReflection:
    Codable,
    Identifiable {

    let id:
        UUID

    let reference:
        String

    var text:
        String

    let createdAt:
        Date

    var updatedAt:
        Date
}


// =========================================================
// MARK: - Passage Reflection Store
// =========================================================

/// Stores free-form reflections created while studying a normal Bible passage.
///
/// Journey checkpoint reflections remain in StudyNoteService. This store is for
/// direct Scripture study that is not attached to a Journey checkpoint.
final class PassageReflectionStore:
    ObservableObject {

    static let shared =
        PassageReflectionStore()


    @Published
    private(set) var reflections:
        [String: PassageStudyReflection] = [:]


    private let storageKey =
        "bibleCompanionPassageStudyReflections"


    private init() {
        load()
    }


    // =====================================================
    // MARK: - Lookup
    // =====================================================

    func reflection(
        for reference:
            String
    ) -> PassageStudyReflection? {

        reflections[
            storageID(
                for:
                    reference
            )
        ]
    }


    func text(
        for reference:
            String
    ) -> String {

        reflection(
            for:
                reference
        )?
        .text
        ??
        ""
    }


    func recent(
        limit:
            Int = 6
    ) -> [PassageStudyReflection] {

        Array(
            reflections
                .values
                .sorted {
                    $0.updatedAt >
                    $1.updatedAt
                }
                .prefix(
                    max(
                        limit,
                        0
                    )
                )
        )
    }


    // =====================================================
    // MARK: - Save
    // =====================================================

    func save(
        reference:
            String,
        text:
            String
    ) {

        let cleanedReference =
            reference
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        let cleanedText =
            text
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        guard
            !cleanedReference.isEmpty
        else {
            return
        }


        let key =
            storageID(
                for:
                    cleanedReference
            )


        if cleanedText.isEmpty {

            reflections
                .removeValue(
                    forKey:
                        key
                )

            persist()
            return
        }


        let now =
            Date()


        if var existing =
            reflections[key] {

            existing.text =
                text

            existing.updatedAt =
                now

            reflections[key] =
                existing

        } else {

            reflections[key] =
                PassageStudyReflection(
                    id:
                        UUID(),
                    reference:
                        cleanedReference,
                    text:
                        text,
                    createdAt:
                        now,
                    updatedAt:
                        now
                )
        }


        persist()
    }


    // =====================================================
    // MARK: - Delete
    // =====================================================

    func remove(
        reference:
            String
    ) {

        reflections
            .removeValue(
                forKey:
                    storageID(
                        for:
                            reference
                    )
            )

        persist()
    }


    // =====================================================
    // MARK: - Storage
    // =====================================================

    private func persist() {

        do {

            let data =
                try JSONEncoder()
                    .encode(
                        reflections
                    )

            UserDefaults.standard
                .set(
                    data,
                    forKey:
                        storageKey
                )

        } catch {

            print(
                "Passage reflection save error:",
                error
            )
        }
    }


    private func load() {

        guard
            let data =
                UserDefaults.standard
                    .data(
                        forKey:
                            storageKey
                    )
        else {
            return
        }


        do {

            reflections =
                try JSONDecoder()
                    .decode(
                        [String: PassageStudyReflection].self,
                        from:
                            data
                    )

        } catch {

            print(
                "Passage reflection load error:",
                error
            )
        }
    }


    private func storageID(
        for reference:
            String
    ) -> String {

        reference
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .lowercased()
            .replacingOccurrences(
                of:
                    "–",
                with:
                    "-"
            )
            .replacingOccurrences(
                of:
                    "—",
                with:
                    "-"
            )
            .components(
                separatedBy:
                    .whitespacesAndNewlines
            )
            .filter {
                !$0.isEmpty
            }
            .joined(
                separator:
                    " "
            )
    }
}
