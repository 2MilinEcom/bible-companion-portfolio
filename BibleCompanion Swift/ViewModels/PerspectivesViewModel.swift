import Foundation
import Combine


@MainActor
final class PerspectivesViewModel:
    ObservableObject {

    // =====================================================
    // MARK: - Published State
    // =====================================================

    @Published
    var response:
        PerspectivesResponse?

    @Published
    var isLoading =
        false

    @Published
    var errorMessage:
        String?


    // =====================================================
    // MARK: - Dependencies
    // =====================================================

    private let service:
        PerspectivesService

    private let personalizationContextService =
        PersonalizationContextService.shared

    /// HomeViewModel already owns the app's current
    /// personalized-journey state.
    ///
    /// We use it here as a reader so Perspectives can receive
    /// the same active/past Journey context as Companion.
    private let journeyStateViewModel =
        HomeViewModel()


    // =====================================================
    // MARK: - Init
    // =====================================================

    init(
        service:
            PerspectivesService? = nil
    ) {

        self.service =
            service
            ?? PerspectivesService.shared
    }


    // =====================================================
    // MARK: - Load
    // =====================================================

    func load(
        passage:
            String,
        profile:
            SpiritualProfile
    ) async {

        guard response == nil else {
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

            let personalizationContext =
                buildPersonalizationContext(
                    passage:
                        passage,
                    profile:
                        profile
                )


            response =
                try await service
                    .generate(
                        passage:
                            passage,
                        profile:
                            profile,
                        personalizationContext:
                            personalizationContext
                    )

        } catch {

            errorMessage =
                error.localizedDescription
        }
    }


    // =====================================================
    // MARK: - Retry
    // =====================================================

    func retry(
        passage:
            String,
        profile:
            SpiritualProfile
    ) async {

        response =
            nil


        await load(
            passage:
                passage,
            profile:
                profile
        )
    }


    // =====================================================
    // MARK: - Personalization
    // =====================================================

    /// Builds context specifically for the Perspectives
    /// experience.
    ///
    /// The context may help the backend:
    ///
    /// - match explanation depth to Bible familiarity
    /// - avoid needlessly repeating prior material
    /// - understand whether this passage is part of an
    ///   active or past Journey
    /// - connect to relevant user-written reflections
    ///
    /// It must NOT be used to choose a theological position
    /// for the user or to distort the competing views.
    private func buildPersonalizationContext(
        passage:
            String,
        profile:
            SpiritualProfile
    ) -> PersonalizationContext {

        // -------------------------------------------------
        // Refresh Journey State
        // -------------------------------------------------

        journeyStateViewModel
            .loadPersonalizedJourneyState()


        journeyStateViewModel
            .refreshPastJourneys()


        // -------------------------------------------------
        // Build Relevant Context
        // -------------------------------------------------

        return personalizationContextService
            .buildContext(
                profile:
                    profile,
                activeJourney:
                    journeyStateViewModel
                        .activePersonalizedJourney,
                pastJourneys:
                    journeyStateViewModel
                        .pastPersonalizedJourneys,
                purpose:
                    .perspectives,
                currentPassage:
                    passage,
                currentMessage:
                    "Compare major Christian interpretations of this passage."
            )
    }
}
