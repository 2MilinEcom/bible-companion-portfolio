//
//  BibleStudyViewModel.swift
//  BibleCompanion Swift
//
//  Created by Shopify on 10/3/26.
//

import Foundation
import Combine


@MainActor
final class BibleStudyViewModel:
    ObservableObject {

    @Published
    var guide:
        BibleStudyGuide?

    @Published
    var isLoading =
        false

    @Published
    var errorMessage:
        String?


    private let service =
        BibleStudyGuideService.shared

    private let personalizationContextService =
        PersonalizationContextService.shared

    private let storageService =
        StorageService.shared

    private let studyHistoryService =
        StudyHistoryService.shared


    func load(
        reference:
            String,
        passage:
            String,
        profile:
            SpiritualProfile
    ) async {

        guard
            guide == nil,
            !isLoading
        else {
            return
        }


        isLoading =
            true

        errorMessage =
            nil


        defer {
            isLoading =
                false
        }


        do {

            let context =
                personalizationContextService
                    .buildContext(
                        profile:
                            profile,
                        activeJourney:
                            storageService
                                .loadActivePersonalizedPath(),
                        pastJourneys:
                            storageService
                                .loadPastPersonalizedJourneys(),
                        purpose:
                            .companion,
                        currentPassage:
                            reference,
                        currentMessage:
                            "Create a structured study guide for this passage."
                    )


            guide =
                try await service
                    .generate(
                        reference:
                            reference,
                        passage:
                            passage,
                        profile:
                            profile,
                        personalizationContext:
                            context
                    )


            recordStudyActivityIfNeeded(
                reference:
                    reference
            )

        } catch {

            errorMessage =
                error
                    .localizedDescription
        }
    }


    func retry(
        reference:
            String,
        passage:
            String,
        profile:
            SpiritualProfile
    ) async {

        guide =
            nil

        errorMessage =
            nil


        await load(
            reference:
                reference,
            passage:
                passage,
            profile:
                profile
        )
    }


    private func recordStudyActivityIfNeeded(
        reference:
            String
    ) {

        if let latest =
            studyHistoryService
                .loadActivities()
                .first,
           latest.type ==
                .passageStudy,
           latest.passage ==
                reference,
           Date()
                .timeIntervalSince(
                    latest.date
                )
                < 600 {

            return
        }


        studyHistoryService
            .record(
                StudyActivity(
                    type:
                        .passageStudy,
                    title:
                        "Studied \(reference)",
                    passage:
                        reference,
                    topic:
                        "Bible study"
                )
            )
    }
}
