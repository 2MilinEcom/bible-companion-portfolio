import SwiftUI


private enum CheckInQuestion {

    case spiritualPosition
    case bibleFamiliarity
    case primaryGoal
    case currentSeason
    case challengePreference
}


private enum StruggleQuestion {

    case category
    case trigger
    case growth
}



struct SpiritualCheckInView: View {



    @EnvironmentObject

    var viewModel: OnboardingViewModel



    @State

    private var activeQuestion:
        CheckInQuestion =
        .spiritualPosition



    @State

    private var hasStartedCheckIn =
        false





    var body: some View {



        ScrollView {



            VStack(

                alignment: .leading,

                spacing: 30

            ) {



                HStack(

                    alignment: .top,

                    spacing: 16

                ) {



                    VStack(

                        alignment: .leading,

                        spacing: 8

                    ) {



                        Text(
                            viewModel.profile.preferredName.isEmpty
                                ? "Where are you right now?"
                                : "Where are you right now, \(viewModel.profile.preferredName)?"
                        )

                            .font(.largeTitle)

                            .bold()



                        Text(

                            "There's no right answer. This helps your Companion meet you where you are."

                        )

                        .foregroundStyle(AppTheme.textSecondary)

                    }



                    Spacer(minLength: 0)



                    if !hasStartedCheckIn {

                        CompanionAvatar(size: 92, behavior: .floating)
                            .transition(
                                .scale
                                    .combined(with: .opacity)
                            )
                    }

                }
                .animation(
                    .spring(
                        response: 0.45,
                        dampingFraction: 0.78
                    ),
                    value: hasStartedCheckIn
                )





                QuestionSection(

                    question:

                        "How would you describe where you are spiritually?",

                    options:

                        viewModel.spiritualPositions,

                    selection:

                        $viewModel.profile.spiritualPosition,

                    showsCompanion:

                        hasStartedCheckIn
                        &&
                        activeQuestion
                        ==
                        .spiritualPosition,

                    onSelectionChanged: {

                        withAnimation {

                            activeQuestion =
                                .spiritualPosition

                            hasStartedCheckIn =
                                true

                        }

                    }

                )





                QuestionSection(

                    question:

                        "How familiar are you with Scripture?",

                    options:

                        viewModel.bibleFamiliarityOptions,

                    selection:

                        $viewModel.profile.bibleFamiliarity,

                    showsCompanion:

                        hasStartedCheckIn
                        &&
                        activeQuestion
                        ==
                        .bibleFamiliarity,

                    onSelectionChanged: {

                        withAnimation {

                            activeQuestion =
                                .bibleFamiliarity

                            hasStartedCheckIn =
                                true

                        }

                    }

                )





                QuestionSection(

                    question:

                        "What brought you here?",

                    options:

                        viewModel.primaryGoals,

                    selection:

                        $viewModel.profile.primaryGoal,

                    showsCompanion:

                        hasStartedCheckIn
                        &&
                        activeQuestion
                        ==
                        .primaryGoal,

                    onSelectionChanged: {

                        withAnimation {

                            activeQuestion =
                                .primaryGoal

                            hasStartedCheckIn =
                                true

                        }

                    }

                )





                QuestionSection(

                    question:

                        "What does your spiritual life feel like lately?",

                    options:

                        viewModel.currentSeasons,

                    selection:

                        $viewModel.profile.currentSeason,

                    showsCompanion:

                        hasStartedCheckIn
                        &&
                        activeQuestion
                        ==
                        .currentSeason,

                    onSelectionChanged: {

                        withAnimation {

                            activeQuestion =
                                .currentSeason

                            hasStartedCheckIn =
                                true

                        }

                    }

                )





                QuestionSection(

                    question:

                        "How should your Companion challenge you?",

                    options:

                        viewModel.challengePreferences,

                    selection:

                        $viewModel.profile.challengePreference,

                    showsCompanion:

                        hasStartedCheckIn
                        &&
                        activeQuestion
                        ==
                        .challengePreference,

                    onSelectionChanged: {

                        withAnimation {

                            activeQuestion =
                                .challengePreference

                            hasStartedCheckIn =
                                true

                        }

                    }

                )





                // Everyone moves through the struggle page.

                NavigationLink {



                    StruggleFollowUpView()



                } label: {



                    Text("Continue")

                        .fontWeight(.semibold)

                        .frame(maxWidth: .infinity)

                        .padding(.vertical, 15)

                }

                .buttonStyle(.borderedProminent)

                .disabled(!viewModel.canContinue)

                .opacity(

                    viewModel.canContinue

                    ? 1

                    : 0.5

                )

            }

            .padding()

        }

        .cloudScreen()
        .navigationTitle("Your Journey")

        .navigationBarTitleDisplayMode(.inline)

    }

}





// =========================================================

// MARK: - Struggle Follow-Up

// =========================================================



struct StruggleFollowUpView: View {



    @EnvironmentObject

    var viewModel: OnboardingViewModel



    @State

    private var navigateToSummary = false



    @State

    private var activeQuestion:
        StruggleQuestion =
        .category



    @State

    private var hasStartedFollowUp =
        false





    private var effectiveCategory: String {

        viewModel.effectiveStruggleCategory

    }





    private var triggerOptions: [String] {

        viewModel.triggerOptions(

            for: effectiveCategory

        )

    }





    private var growthOptions: [String] {

        viewModel.growthOptions(

            for: effectiveCategory

        )

    }





    var body: some View {



        ScrollView {



            VStack(

                alignment: .leading,

                spacing: 30

            ) {



                // MARK: - Header



                HStack(

                    alignment: .top,

                    spacing: 16

                ) {

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Text("What are you working through?")
                            .font(.largeTitle)
                            .bold()

                        Text(
                            "Everyone has something they're carrying or trying to grow through. This helps Recommended for You focus on what matters to you right now."
                        )
                        .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer(minLength: 0)

                    if !hasStartedFollowUp {

                        CompanionAvatar(size: 86, behavior: .floating)
                            .transition(
                                .scale
                                    .combined(with: .opacity)
                            )
                    }
                }
                .animation(
                    .spring(
                        response: 0.45,
                        dampingFraction: 0.78
                    ),
                    value: hasStartedFollowUp
                )





                // MARK: - Struggle Category



                QuestionSection(

                    question:

                        "What are you struggling with most right now?",

                    options:

                        viewModel.struggleCategories,

                    selection:

                        $viewModel.profile.struggleCategory,

                    showsCompanion:

                        hasStartedFollowUp
                        &&
                        activeQuestion
                        ==
                        .category,

                    onSelectionChanged: {

                        withAnimation {

                            activeQuestion =
                                .category

                            hasStartedFollowUp =
                                true

                        }

                    }

                )





                // MARK: - Custom Struggle



                if viewModel.profile.struggleCategory == "Something else" {



                    VStack(

                        alignment: .leading,

                        spacing: 12

                    ) {



                        Text("Tell us what it is")

                            .font(.title3)

                            .bold()



                        Text(

                            "Write it in your own words. We'll keep what you wrote and use AI to understand the theme without diagnosing or labeling you."

                        )

                        .font(.subheadline)

                        .foregroundStyle(AppTheme.textSecondary)



                        TextField(

                            "For example: I keep comparing myself to other people and getting jealous...",

                            text:

                                $viewModel.profile.customStruggleText,

                            axis: .vertical

                        )

                        .lineLimit(3...7)

                        .textFieldStyle(.roundedBorder)





                        if !viewModel.customStruggleHasBeenAnalyzed {



                            Button {



                                Task {

                                    _ = await viewModel

                                        .analyzeCustomStruggle()

                                }



                            } label: {



                                HStack {



                                    if viewModel.isAnalyzingStruggle {

                                        ProgressView()

                                    } else {

                                        Image(systemName: "sparkles")

                                    }



                                    Text(

                                        viewModel.isAnalyzingStruggle

                                        ? "Understanding..."

                                        : "Understand What I Wrote"

                                    )

                                    .fontWeight(.semibold)

                                }

                                .frame(maxWidth: .infinity)

                                .padding(.vertical, 12)

                            }

                            .buttonStyle(.borderedProminent)

                            .disabled(

                                !viewModel.canAnalyzeCustomStruggle ||

                                viewModel.isAnalyzingStruggle

                            )

                        }





                        if let error = viewModel.struggleAnalysisError {



                            Text(error)

                                .font(.caption)

                                .foregroundStyle(.red)

                        }





                        if viewModel.customStruggleHasBeenAnalyzed {



                            VStack(

                                alignment: .leading,

                                spacing: 6

                            ) {



                                Text("Got it")

                                    .font(.caption)

                                    .fontWeight(.bold)

                                    .foregroundStyle(AppTheme.textSecondary)



                                Text(viewModel.effectiveStruggleLabel)

                                    .font(.headline)



                                if !viewModel.profile.struggleSummary.isEmpty {



                                    Text(viewModel.profile.struggleSummary)

                                        .font(.subheadline)

                                        .foregroundStyle(AppTheme.textSecondary)

                                }

                            }

                            .padding()

                            .frame(

                                maxWidth: .infinity,

                                alignment: .leading

                            )

                            .background(

                                RoundedRectangle(

                                    cornerRadius: 16

                                )

                                .fill(

                                    AppTheme.surface

                                )

                            )

                        }

                    }

                }





                // MARK: - Adaptive Follow-Ups



                if viewModel.shouldShowStruggleFollowUps {



                    QuestionSection(

                        question: triggerQuestion,

                        options: triggerOptions,

                        selection:

                            $viewModel.profile.struggleTrigger,

                        showsCompanion:

                            hasStartedFollowUp
                            &&
                            activeQuestion
                            ==
                            .trigger,

                        onSelectionChanged: {

                            withAnimation {

                                activeQuestion =
                                    .trigger

                                hasStartedFollowUp =
                                    true

                            }

                        }

                    )





                    if !viewModel.profile.struggleTrigger.isEmpty {



                        QuestionSection(

                            question: growthQuestion,

                            options: growthOptions,

                            selection:

                                $viewModel.profile.struggleGoal,

                            showsCompanion:

                                hasStartedFollowUp
                                &&
                                activeQuestion
                                ==
                                .growth,

                            onSelectionChanged: {

                                withAnimation {

                                    activeQuestion =
                                        .growth

                                    hasStartedFollowUp =
                                        true

                                }

                            }

                        )

                    }

                }





                // MARK: - Personalization Preview



                if viewModel.canContinueStruggleDetails {



                    VStack(

                        alignment: .leading,

                        spacing: 8

                    ) {



                        Label(

                            "This will shape Recommended for You",

                            systemImage: "sparkles"

                        )

                        .font(.headline)



                        Text(recommendationExplanation)

                            .font(.subheadline)

                            .foregroundStyle(AppTheme.textSecondary)

                    }

                    .padding()

                    .frame(

                        maxWidth: .infinity,

                        alignment: .leading

                    )

                    .background(

                        RoundedRectangle(

                            cornerRadius: 16

                        )

                        .fill(

                            AppTheme.surface

                        )

                    )

                }





                // MARK: - Continue



                Button {



                    guard viewModel.prepareStruggleForSummary() else {

                        return

                    }



                    navigateToSummary = true



                } label: {



                    Text("Continue")

                        .fontWeight(.semibold)

                        .frame(maxWidth: .infinity)

                        .padding(.vertical, 15)

                }

                .buttonStyle(.borderedProminent)

                .disabled(

                    !viewModel.canContinueStruggleDetails

                )

                .opacity(

                    viewModel.canContinueStruggleDetails

                    ? 1

                    : 0.5

                )

            }

            .padding()

        }

        .navigationTitle("Your Journey")

        .navigationBarTitleDisplayMode(.inline)

        .navigationDestination(

            isPresented: $navigateToSummary

        ) {

            OnboardingSummaryView()

        }

        .onChange(

            of: viewModel.profile.struggleCategory

        ) { oldValue, newValue in



            if oldValue != newValue {

                viewModel.resetStruggleForNewCategory()

            }

        }

        .onChange(

            of: viewModel.profile.customStruggleText

        ) { oldValue, newValue in



            if oldValue != newValue,

               viewModel.customStruggleHasBeenAnalyzed {



                viewModel.clearCustomStruggleAnalysis()

            }

        }

    }





    // MARK: - Dynamic Question Copy



    private var triggerQuestion: String {



        switch effectiveCategory {



        case "Anger":

            return "When does your anger tend to show up?"



        case "Forgiveness":

            return "What makes forgiveness difficult right now?"



        case "Temptation":

            return "When does this struggle usually become strongest?"



        case "Doubt":

            return "Where are your doubts showing up most?"



        case "Relationships":

            return "What feels hardest in your relationships right now?"



        case "Prayer and consistency":

            return "What usually gets in the way?"



        case "Fear or worry":

            return "When does the fear or worry become strongest?"



        case "Loneliness":

            return "When do you feel the loneliness most?"



        case "Grief or loss":

            return "What feels hardest right now?"



        case "Purpose or direction":

            return "Where do you feel most stuck or uncertain?"



        case "Habits and self-control":

            return "When is this pattern hardest to resist?"



        default:

            return "What best describes how this tends to show up?"

        }

    }





    private var growthQuestion: String {



        switch effectiveCategory {



        case "Anger":

            return "What would you most like to change about your anger?"



        case "Forgiveness":

            return "What would you most like help with?"



        case "Temptation":

            return "What would growth look like for you?"



        case "Doubt":

            return "What would you most like to understand?"



        case "Relationships":

            return "What would you most like to grow in?"



        case "Prayer and consistency":

            return "What would you most like to build?"



        case "Fear or worry":

            return "What would you most like to become different?"



        case "Loneliness":

            return "What would feel like meaningful growth here?"



        case "Grief or loss":

            return "What would feel most helpful right now?"



        case "Purpose or direction":

            return "What would you most like clarity about?"



        case "Habits and self-control":

            return "What would you most like to change about this pattern?"



        default:

            return "What would you most like help with?"

        }

    }





    // MARK: - Explanation



    private var recommendationExplanation: String {



        if effectiveCategory == "Anger" {



            return "We'll use what you shared to guide you through biblical examples of anger, including when anger was understandable, when it became destructive, and how Scripture teaches us to respond to it."

        }



        let label = viewModel.effectiveStruggleLabel



        if !label.isEmpty {



            return "We'll keep \(label) as an active focus and use it to choose Scripture, questions, and future studies that connect with what you're actually working through."

        }



        return "We'll use what you shared to choose Scripture and studies that connect more closely with what you're walking through."

    }

}






// =========================================================
// MARK: - Question Section

// =========================================================



struct QuestionSection: View {



    let question: String

    let options: [String]



    @Binding

    var selection: String



    var showsCompanion =
        false



    var onSelectionChanged:
        (() -> Void)?





    var body: some View {



        VStack(

            alignment: .leading,

            spacing: 12

        ) {



            Text(question)

                .font(.title3)

                .bold()





            ForEach(

                options,

                id: \.self

            ) { option in



                Button {

                    withAnimation(
                        .spring(
                            response: 0.36,
                            dampingFraction: 0.72
                        )
                    ) {

                        selection =
                            option
                    }

                    onSelectionChanged?()

                } label: {



                    HStack {



                        Text(option)

                            .multilineTextAlignment(.leading)



                        Spacer()



                        Image(

                            systemName:

                                selection == option

                                ? "checkmark.circle.fill"

                                : "circle"

                        )

                    }

                    .padding()

                    .frame(maxWidth: .infinity)

                    .background(

                        RoundedRectangle(

                            cornerRadius: 14

                        )

                        .fill(

                            selection == option

                            ? AppTheme.accent.opacity(0.10)

                            : AppTheme.surface

                        )

                    )

                }

                .buttonStyle(.plain)
                .overlay(
                    alignment: .topTrailing
                ) {

                    if
                        showsCompanion,
                        selection == option {

                        CompanionAvatar(
                            size: 54,
                            behavior: .floating
                        )
                        .offset(
                            x: 7,
                            y: -34
                        )
                        .transition(
                            .scale
                                .combined(with: .opacity)
                        )
                        .zIndex(10)
                    }
                }

            }

        }
        .animation(
            .spring(
                response: 0.42,
                dampingFraction: 0.74
            ),
            value: selection
        )

    }

}
