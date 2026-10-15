import SwiftUI





struct JourneyPreparationView: View {



    // =====================================================

    // MARK: - Environment

    // =====================================================



    @EnvironmentObject

    private var onboardingViewModel:

        OnboardingViewModel





    @AppStorage(

        "onboardingComplete"

    )

    private var onboardingComplete =

        false





    // =====================================================

    // MARK: - View Models

    // =====================================================



    @StateObject

    private var homeViewModel =

        HomeViewModel()





    // =====================================================

    // MARK: - Preparation State

    // =====================================================



    @State

    private var completedSteps:

        Set<Int> = []





    @State

    private var activeStep =

        0





    @State

    private var isPreparing =

        false





    @State

    private var preparationError:

        String?








    /// True only during the temporary transition

    /// where a completely custom topic still uses

    /// the old one-off recommendation system.

    ///

    /// Once JourneyService can generate full custom

    /// paths, this can be removed.

    @State

    private var usedLegacyCustomFallback =

        false





    // =====================================================

    // MARK: - Steps

    // =====================================================



    private var preferredName: String {

        onboardingViewModel
            .profile
            .preferredName
    }




    private let steps = [



        "Saving what you shared",



        "Setting up your Jesus journey",



        "Building your personalized path"

    ]





    // =====================================================

    // MARK: - Body

    // =====================================================



    var body: some View {



        VStack(

            spacing: 0

        ) {



            Spacer()





            // =================================================

            // MARK: Companion

            // =================================================



            ZStack {



                Circle()

                    .fill(

                        AppTheme.accent

                            .opacity(

                                activeStep >= 3

                                ? 0.12

                                : 0.08

                            )

                    )

                    .frame(

                        width: 174,

                        height: 174

                    )

                    .scaleEffect(

                        activeStep >= 3

                        ? 1.04

                        : 1

                    )



                CompanionAvatar(
                    size: 148,
                    behavior:
                        isPreparing
                        ? .floating
                        : .still
                )


                if activeStep >= 3 {



                    Image(

                        systemName:

                            "checkmark.circle.fill"

                    )

                    .font(

                        .system(

                            size: 34

                        )

                    )

                    .foregroundStyle(

                        AppTheme.accent,

                        AppTheme.surfaceStrong

                    )

                    .offset(

                        x: 58,

                        y: 58

                    )

                    .transition(

                        .scale

                            .combined(

                                with: .opacity

                            )

                    )

                }

            }

            .animation(

                .easeInOut(

                    duration: 0.35

                ),

                value:

                    activeStep

            )





            // =================================================

            // MARK: Main Message

            // =================================================



            VStack(

                spacing: 12

            ) {



                Text(

                    titleText

                )

                .font(

                    .largeTitle

                )

                .bold()

                .multilineTextAlignment(

                    .center

                )





                Text(

                    subtitleText

                )

                .font(

                    .body

                )

                .foregroundStyle(AppTheme.textSecondary)

                .multilineTextAlignment(

                    .center

                )

                .frame(

                    maxWidth: 340

                )

            }

            .padding(

                .top,

                30

            )





            // =================================================

            // MARK: Steps

            // =================================================



            VStack(

                spacing: 18

            ) {



                ForEach(

                    steps.indices,

                    id: \.self

                ) { index in



                    preparationStep(

                        title:

                            steps[index],

                        index:

                            index

                    )

                }

            }

            .padding(

                .top,

                42

            )

            .frame(

                maxWidth: 360

            )





            // =================================================

            // MARK: Error

            // =================================================



            if let preparationError {



                VStack(

                    spacing: 14

                ) {



                    Text(

                        "We couldn't finish preparing your journey."

                    )

                    .font(

                        .headline

                    )

                    .multilineTextAlignment(

                        .center

                    )





                    Text(

                        preparationError

                    )

                    .font(

                        .caption

                    )

                    .foregroundStyle(AppTheme.textSecondary)

                    .multilineTextAlignment(

                        .center

                    )





                    Button {



                        Task {



                            await prepareJourney()

                        }



                    } label: {



                        Text(

                            "Try Again"

                        )

                        .fontWeight(

                            .semibold

                        )

                        .frame(

                            maxWidth:

                                .infinity

                        )

                        .padding(

                            .vertical,

                            14

                        )

                    }

                    .buttonStyle(

                        .borderedProminent

                    )

                }

                .padding(

                    .top,

                    28

                )

                .frame(

                    maxWidth: 340

                )

            }





            Spacer()

            Spacer()

        }

        .padding(

            .horizontal,

            28

        )

        .frame(

            maxWidth:

                .infinity,

            maxHeight:

                .infinity

        )

        .background(

            AppTheme.surfaceStrong

        )

        .navigationBarBackButtonHidden(

            isPreparing

        )

        .task {



            guard

                !isPreparing,

                completedSteps.isEmpty

            else {



                return

            }





            await prepareJourney()

        }

    }





    // =====================================================

    // MARK: - Preparation

    // =====================================================



    @MainActor

    private func prepareJourney()

        async {



        guard

            !isPreparing

        else {



            return

        }





        isPreparing =

            true





        preparationError =

            nil





        completedSteps =

            []





        activeStep =

            0





        usedLegacyCustomFallback =

            false





        // =================================================

        // STEP 1

        // Save Profile

        // =================================================



        onboardingViewModel

            .saveProfile()





        try? await Task.sleep(

            nanoseconds:

                300_000_000

        )





        _ = withAnimation(

            .easeInOut(

                duration: 0.25

            )

        ) {



            completedSteps.insert(

                0

            )

        }





        // =================================================

        // STEP 2

        // Foundation Journey

        // =================================================



        activeStep =

            1





        /*

         Meet Jesus remains the permanent

         foundation journey.



         It is local, so there is no network

         request necessary here.

        */



        let foundationJourney =

            JourneyLibrary

                .meetJesus





        _ =

            foundationJourney

                .checkpoints

                .count





        try? await Task.sleep(

            nanoseconds:

                450_000_000

        )





        _ = withAnimation(

            .easeInOut(

                duration: 0.25

            )

        ) {



            completedSteps.insert(

                1

            )

        }





        // =================================================

        // STEP 3

        // Personalized Journey

        // =================================================



        activeStep =

            2





        /*

         First check whether this onboarding session

         already created and activated its path.



         This prevents a retry from accidentally

         generating a second UUID and duplicating

         the same personalized journey.

        */



        homeViewModel

            .loadPersonalizedJourneyState()





        if shouldReuseCurrentPersonalizedJourney {



            // We already have the correct path.

            // Nothing else needs to be generated.



            await finishPersonalizedStep()



            return

        }





        // -------------------------------------------------

        // Try Curated Personalized Path

        // -------------------------------------------------



        if let personalizedPath =

            onboardingViewModel

                .createAndActivateInitialPersonalizedPath() {



            /*

             Example:



             Anger

                 →

             Understanding Your Anger

                 →

             7 persistent checkpoints



             Doubt

                 →

             Working Through Doubt

                 →

             6 persistent checkpoints

            */



            homeViewModel

                .loadPersonalizedJourneyState()





            guard

                homeViewModel

                    .activePersonalizedJourney?

                    .id

                ==

                personalizedPath.id

            else {



                failPreparation(

                    message:

                        "Your personalized path was created, but it could not be loaded."

                )



                return

            }





            await finishPersonalizedStep()



            return

        }





        // -------------------------------------------------

        // Custom Topic Transitional Fallback

        // -------------------------------------------------



        /*

         If JourneyLibrary does not contain a curated

         path, this is likely a truly custom topic.



         Example:



         "I compare myself to everyone online and

         always feel behind."



         We have not updated JourneyService yet to

         return an entire AI-created JourneyPath.



         Until that next file is updated, preserve the

         existing onboarding experience by generating

         the original personalized recommendation.



         IMPORTANT:



         This is temporary.



         JourneyService.swift will be the next upgrade,

         where this branch becomes:



             AI

              ↓

         5–7 checkpoints

              ↓

         JourneyPath

              ↓

         activatePersonalizedJourney(...)

        */



        usedLegacyCustomFallback =

            true





        await homeViewModel

            .loadRecommendation(

                profile:

                    onboardingViewModel

                        .profile

            )





        // -------------------------------------------------

        // Handle Legacy AI Error

        // -------------------------------------------------



        if let error =

            homeViewModel

                .errorMessage {



            failPreparation(

                message:

                    error

            )



            return

        }





        guard

            homeViewModel

                .recommendation

            != nil

        else {



            failPreparation(

                message:

                    "We couldn't prepare a personalized starting point for this focus."

            )



            return

        }





        await finishPersonalizedStep()

    }





    // =====================================================

    // MARK: - Reuse Existing Path

    // =====================================================



    /// Prevents duplicate personalized journeys if:

    ///

    /// - the preparation screen retries

    /// - the view redraws

    /// - the path was created moments earlier

    private var shouldReuseCurrentPersonalizedJourney:

        Bool {



        guard

            let activeJourney =

                homeViewModel

                    .activePersonalizedJourney,



            let currentFocus =

                onboardingViewModel

                    .currentJourneyFocus,



            let activeFocus =

                activeJourney

                    .focus

        else {



            return false

        }





        let currentCategory =

            currentFocus

                .category

                .trimmingCharacters(

                    in:

                        .whitespacesAndNewlines

                )

                .lowercased()





        let activeCategory =

            activeFocus

                .category

                .trimmingCharacters(

                    in:

                        .whitespacesAndNewlines

                )

                .lowercased()





        let currentTrigger =

            currentFocus

                .trigger?

                .trimmingCharacters(

                    in:

                        .whitespacesAndNewlines

                )

            ?? ""





        let activeTrigger =

            activeFocus

                .trigger?

                .trimmingCharacters(

                    in:

                        .whitespacesAndNewlines

                )

            ?? ""





        let currentGoal =

            currentFocus

                .goal?

                .trimmingCharacters(

                    in:

                        .whitespacesAndNewlines

                )

            ?? ""





        let activeGoal =

            activeFocus

                .goal?

                .trimmingCharacters(

                    in:

                        .whitespacesAndNewlines

                )

            ?? ""





        return

            currentCategory ==

                activeCategory



            &&



            currentTrigger ==

                activeTrigger



            &&



            currentGoal ==

                activeGoal

    }





    // =====================================================

    // MARK: - Finish Personalized Step

    // =====================================================



    @MainActor

    private func finishPersonalizedStep()

        async {



        _ = withAnimation(

            .easeInOut(

                duration: 0.25

            )

        ) {



            completedSteps.insert(

                2

            )

        }





        activeStep =

            3





        /*

         Give the user a moment to actually see:



         ✓ Saving what you shared

         ✓ Setting up Jesus journey

         ✓ Building personalized path



         before Home appears.

        */



        try? await Task.sleep(

            nanoseconds:

                700_000_000

        )





        isPreparing =

            false





        // Preserve the smooth transition

        // you already liked.



        withAnimation(

            .easeInOut(

                duration: 0.55

            )

        ) {



            onboardingComplete =

                true

        }

    }





    // =====================================================

    // MARK: - Failure

    // =====================================================



    @MainActor

    private func failPreparation(

        message: String

    ) {



        preparationError =

            message





        isPreparing =

            false

    }





    // =====================================================

    // MARK: - Step Row

    // =====================================================



    @ViewBuilder

    private func preparationStep(

        title: String,

        index: Int

    ) -> some View {



        HStack(

            spacing: 14

        ) {



            ZStack {



                Circle()

                    .fill(

                        stepBackgroundColor(

                            index

                        )

                    )

                    .frame(

                        width: 34,

                        height: 34

                    )





                if completedSteps

                    .contains(

                        index

                    ) {



                    Image(

                        systemName:

                            "checkmark"

                    )

                    .font(

                        .caption

                    )

                    .fontWeight(

                        .bold

                    )

                    .foregroundStyle(

                        AppTheme.accent

                    )





                } else if

                    activeStep == index,

                    isPreparing {



                    ProgressView()

                        .controlSize(

                            .small

                        )





                } else if

                    activeStep == index,

                    preparationError

                    != nil {



                    Image(

                        systemName:

                            "exclamationmark"

                    )

                    .font(

                        .caption

                    )

                    .fontWeight(

                        .bold

                    )

                    .foregroundStyle(AppTheme.textSecondary)





                } else {



                    Circle()

                        .fill(

                            AppTheme.textSecondary

                                .opacity(

                                    0.45

                                )

                        )

                        .frame(

                            width: 7,

                            height: 7

                        )

                }

            }





            Text(

                title

            )

            .font(

                .body

            )

            .fontWeight(



                completedSteps

                    .contains(

                        index

                    )

                ||

                activeStep == index



                ? .semibold

                : .regular

            )

            .foregroundStyle(



                completedSteps

                    .contains(

                        index

                    )

                ||

                activeStep == index



                ? AppTheme.textPrimary

                : AppTheme.textSecondary

            )





            Spacer()

        }

    }





    // =====================================================

    // MARK: - Text

    // =====================================================



    private var titleText:

        String {



        if activeStep >= 3 {



            return

                preferredName.isEmpty
                ? "Your journey is ready."
                : "Your journey is ready, \(preferredName)."

        }





        if preparationError

            != nil {



            return

                "Almost there."

        }





        return

            "Preparing your journey..."

    }





    private var subtitleText:

        String {



        switch activeStep {



        case 0:



            return

                "Saving what you shared so your Companion can meet you where you are."





        case 1:



            return

                "Setting up a foundation for getting to know Jesus through Scripture."





        case 2:



            if usedLegacyCustomFallback {



                return

                    "Preparing a personalized starting point for what you're working through."

            }





            return

                "Building a path of Scripture and checkpoints around what you're working through."





        default:



            return

                "Your foundation and personalized path are ready. You can change your focus whenever you need to."

        }

    }





    // =====================================================

    // MARK: - Styling

    // =====================================================



    private func stepBackgroundColor(

        _ index: Int

    ) -> Color {



        if completedSteps

            .contains(

                index

            ) {



            return

                AppTheme.accent

                    .opacity(

                        0.14

                    )

        }





        if activeStep == index {



            return

                AppTheme.accent

                    .opacity(

                        0.10

                    )

        }





        return

            AppTheme.surface

    }

}





// =========================================================

// MARK: - Preview

// =========================================================



#Preview {



    NavigationStack {



        JourneyPreparationView()

            .environmentObject(

                OnboardingViewModel()

            )

    }

}
