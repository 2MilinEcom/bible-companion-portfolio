import Foundation

import Combine





@MainActor

final class HomeViewModel:

    ObservableObject {



    // =====================================================

    // MARK: - Personalized Journey

    // =====================================================



    /// The user's currently active personalized path.

    ///

    /// Eventually HomeView will use this instead of

    /// displaying a single JourneyRecommendation.

    @Published

    private(set)

    var activePersonalizedJourney:

        JourneyPath?





    /// Past personalized paths.

    ///

    /// Includes both:

    /// - paused

    /// - completed

    @Published

    private(set)

    var pastPersonalizedJourneys:

        [PersonalizedJourneyRecord] = []





    // =====================================================

    // MARK: - Legacy Recommendation Compatibility

    // =====================================================



    /*

     KEEP THIS FOR NOW.



     Your current HomeView and JourneyPreparationView

     still rely on recommendation.



     Once HomeView is converted to display the full

     personalized JourneyPath, we can remove this

     legacy layer.

    */

    @Published

    var recommendation:

        JourneyRecommendation?





    // =====================================================

    // MARK: - State

    // =====================================================



    @Published

    var isLoading =

        false





    @Published

    var errorMessage:

        String?





    // =====================================================

    // MARK: - Services

    // =====================================================



    private let journeyService:

        JourneyService





    private let storageService:

        StorageService





    private let studyHistoryService:

        StudyHistoryService





    private let progressStore:

        JourneyProgressStore



    private let personalizationContextService =

        PersonalizationContextService.shared





    // =====================================================

    // MARK: - Init

    // =====================================================



    init(

        journeyService:

            JourneyService? = nil,



        storageService:

            StorageService? = nil,



        studyHistoryService:

            StudyHistoryService? = nil,



        progressStore:

            JourneyProgressStore? = nil

    ) {



        self.journeyService =

            journeyService ?? .shared





        self.storageService =

            storageService ?? .shared





        self.studyHistoryService =

            studyHistoryService ?? .shared





        self.progressStore =

            progressStore ?? .shared





        // Load anything already stored immediately.

        loadPersonalizedJourneyState()

    }





    // =====================================================

    // MARK: - Personalized Journey State

    // =====================================================



    func loadPersonalizedJourneyState() {



        activePersonalizedJourney =

            storageService

                .loadActivePersonalizedPath()





        pastPersonalizedJourneys =

            storageService

                .loadPastPersonalizedJourneys()





        syncRecommendationWithActiveJourney()

    }





    // =====================================================

    // MARK: - Active Journey Helpers

    // =====================================================



    var currentPersonalizedCheckpoint:

        JourneyCheckpoint? {



        guard

            let journey =

                activePersonalizedJourney

        else {



            return nil

        }





        return progressStore

            .currentCheckpoint(

                in: journey

            )

    }





    var lastCompletedPersonalizedCheckpoint:

        JourneyCheckpoint? {



        guard

            let journey =

                activePersonalizedJourney

        else {



            return nil

        }





        return progressStore

            .lastCompletedCheckpoint(

                in: journey

            )

    }





    var completedPersonalizedCheckpoints:

        [JourneyCheckpoint] {



        guard

            let journey =

                activePersonalizedJourney

        else {



            return []

        }





        return progressStore

            .completedCheckpointList(

                in: journey

            )

    }





    var personalizedProgress:

        Double {



        guard

            let journey =

                activePersonalizedJourney

        else {



            return 0

        }





        return progressStore

            .progress(

                in: journey

            )

    }





    var personalizedCompletedCount:

        Int {



        guard

            let journey =

                activePersonalizedJourney

        else {



            return 0

        }





        return progressStore

            .completedCount(

                in: journey

            )

    }





    var personalizedCheckpointCount:

        Int {



        activePersonalizedJourney?

            .checkpoints

            .count

        ?? 0

    }





    var isPersonalizedJourneyComplete:

        Bool {



        guard

            let journey =

                activePersonalizedJourney

        else {



            return false

        }





        return progressStore

            .isJourneyComplete(

                journey

            )

    }





    // =====================================================

    // MARK: - Activate New Personalized Path

    // =====================================================



    /// Called after:

    ///

    /// - onboarding creates a path

    /// - Change Path questionnaire

    /// - Talk It Through

    /// - user approves an AI-created path

    ///

    /// StorageService automatically pauses the old

    /// active path rather than deleting it.

    func activatePersonalizedJourney(

        _ journey: JourneyPath

    ) {



        storageService

            .activatePersonalizedJourney(

                journey

            )





        // The old single recommendation is no longer

        // authoritative once a full path exists.

        storageService

            .clearJourneyRecommendation()





        loadPersonalizedJourneyState()

    }





    // =====================================================

    // MARK: - Complete Personalized Checkpoint

    // =====================================================



    func completeCheckpoint(

        _ checkpoint: JourneyCheckpoint

    ) {



        guard

            let journey =

                activePersonalizedJourney

        else {



            return

        }





        progressStore

            .complete(

                checkpoint,

                in: journey

            )





        storageService

            .touchPersonalizedJourney(

                journeyID:

                    journey.id

            )





        // Preserve the completed study in the existing

        // study history system as well.

        studyHistoryService

            .recordCompletedJourney(

                checkpoint

                    .recommendation

            )





        // IMPORTANT:

        //

        // We do NOT generate a random new recommendation.

        //

        // We simply advance to the next checkpoint that

        // already belongs to this path.

        syncRecommendationWithActiveJourney()

    }





    // =====================================================

    // MARK: - Finish Current Personalized Path

    // =====================================================



    /// This should be called only after the user says

    /// they feel ready to move on.

    ///

    /// Completing the final checkpoint alone does NOT

    /// automatically mark the topic finished.

    func finishActivePersonalizedJourney() {



        guard

            let journey =

                activePersonalizedJourney

        else {



            return

        }





        storageService

            .markPersonalizedJourneyCompleted(

                journeyID:

                    journey.id

            )





        loadPersonalizedJourneyState()

    }





    // =====================================================

    // MARK: - Keep Working On Current Topic

    // =====================================================



    /// Used when the user finishes the checkpoints but

    /// chooses:

    ///

    /// "Keep working on this"

    func keepWorkingOnCurrentJourney() {



        guard

            let journey =

                activePersonalizedJourney

        else {



            return

        }





        storageService

            .keepPersonalizedJourneyActive(

                journeyID:

                    journey.id

            )





        loadPersonalizedJourneyState()

    }





    // =====================================================

    // MARK: - Resume Previous Path

    // =====================================================



    func resumePersonalizedJourney(

        journeyID: String

    ) {



        storageService

            .resumePersonalizedJourney(

                journeyID:

                    journeyID

            )





        loadPersonalizedJourneyState()

    }





    // =====================================================

    // MARK: - Pause Active Path

    // =====================================================



    func pauseActivePersonalizedJourney() {



        storageService

            .pauseActivePersonalizedJourney()





        loadPersonalizedJourneyState()

    }





    // =====================================================

    // MARK: - Legacy Recommendation Loading

    // =====================================================



    /*

     This remains temporarily because:



     1. HomeView still expects recommendation

     2. JourneyPreparationView still calls this

     3. We have not yet wired the questionnaire's

        struggle fields into JourneyFocus



     If a personalized path already exists,

     this returns its current checkpoint instead.

    */

    func loadRecommendation(

        profile: SpiritualProfile

    ) async {



        // -------------------------------------------------

        // Prefer New Personalized Path

        // -------------------------------------------------



        loadPersonalizedJourneyState()





        if

            activePersonalizedJourney

            != nil {



            syncRecommendationWithActiveJourney()



            return

        }





        // -------------------------------------------------

        // Existing In-Memory Legacy Recommendation

        // -------------------------------------------------



        if recommendation != nil {



            return

        }





        // -------------------------------------------------

        // Existing Saved Legacy Recommendation

        // -------------------------------------------------



        if let saved =

            storageService

                .loadJourneyRecommendation() {



            recommendation =

                saved



            return

        }





        // -------------------------------------------------

        // Generate Legacy Recommendation

        // -------------------------------------------------



        await generateLegacyRecommendation(

            profile:

                profile

        )

    }





    // =====================================================

    // MARK: - Generate Legacy Recommendation

    // =====================================================



    private func generateLegacyRecommendation(

        profile: SpiritualProfile

    ) async {



        isLoading =

            true





        errorMessage =

            nil





        defer {



            isLoading =

                false

        }





        do {



            let history =

                studyHistoryService

                    .loadActivities()





            let recentActivity =

                Array(

                    history

                        .prefix(

                            10

                        )

                )





            // Keep Journey state current before building the

            // recommendation context.

            loadPersonalizedJourneyState()





            let personalizationContext =

                personalizationContextService

                    .buildContext(

                        profile:

                            profile,

                        activeJourney:

                            activePersonalizedJourney,

                        pastJourneys:

                            pastPersonalizedJourneys,

                        recentActivity:

                            recentActivity,

                        purpose:

                            .recommendation,

                        currentPassage:

                            "",

                        currentMessage:

                            "Generate the next Recommended for You Bible study step."

                    )





            let generated =

                try await journeyService

                    .generateRecommendation(

                        profile:

                            profile,

                        recentActivity:

                            recentActivity,

                        personalizationContext:

                            personalizationContext

                    )





            recommendation =

                generated





            storageService

                .saveJourneyRecommendation(

                    generated

                )



        } catch {



            errorMessage =

                error

                    .localizedDescription

        }

    }





    // =====================================================

    // MARK: - Legacy Complete Recommendation

    // =====================================================



    /*

     KEEP TEMPORARILY.



     If HomeView is still showing an old-style

     single recommendation, this prevents the

     existing UI from breaking.



     Once HomeView is upgraded, personalized paths

     will use completeCheckpoint(_:) instead.

    */

    func completeRecommendation(

        _ completedRecommendation:

            JourneyRecommendation,

        profile: SpiritualProfile

    ) {



        // -------------------------------------------------

        // If New Personalized Journey Exists

        // -------------------------------------------------



        if

            let currentCheckpoint =

                currentPersonalizedCheckpoint {



            completeCheckpoint(

                currentCheckpoint

            )



            return

        }





        // -------------------------------------------------

        // Legacy Behavior

        // -------------------------------------------------



        studyHistoryService

            .recordCompletedJourney(

                completedRecommendation

            )





        storageService

            .clearJourneyRecommendation()





        recommendation =

            nil





        Task {



            await generateLegacyRecommendation(

                profile:

                    profile

            )

        }

    }





    // =====================================================

    // MARK: - Legacy Refresh

    // =====================================================



    func refreshRecommendation(

        profile: SpiritualProfile

    ) async {



        // A persistent personalized path should NOT

        // be silently replaced by refresh behavior.



        if

            activePersonalizedJourney

            != nil {



            syncRecommendationWithActiveJourney()



            return

        }





        storageService

            .clearJourneyRecommendation()





        recommendation =

            nil





        await generateLegacyRecommendation(

            profile:

                profile

        )

    }





    // =====================================================

    // MARK: - Current Recommendation Compatibility

    // =====================================================



    /// While HomeView still expects a

    /// JourneyRecommendation, expose the current

    /// checkpoint through that existing model.

    ///

    /// Once HomeView is upgraded, it can work directly

    /// with activePersonalizedJourney.

    private func syncRecommendationWithActiveJourney() {



        guard

            let journey =

                activePersonalizedJourney

        else {



            return

        }





        if let checkpoint =

            progressStore

                .currentCheckpoint(

                    in: journey

                ) {



            recommendation =

                checkpoint

                    .recommendation



        } else {



            // All checkpoints have been completed.

            //

            // Do not generate another unrelated study.

            // The UI will later show:

            //

            // "You've completed this path."

            //

            // Move on

            // Keep working

            // Review what I've learned



            recommendation =

                nil

        }

    }





    // =====================================================

    // MARK: - Previous Journey Refresh

    // =====================================================



    func refreshPastJourneys() {



        pastPersonalizedJourneys =

            storageService

                .loadPastPersonalizedJourneys()

    }

}
