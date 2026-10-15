import SwiftUI

struct OnboardingSummaryView: View {

    @EnvironmentObject
    var viewModel: OnboardingViewModel


    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 26
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

                        Text(
                            viewModel.profile.preferredName.isEmpty
                                ? "Here's where we'll start."
                                : "Here's where we'll start, \(viewModel.profile.preferredName)."
                        )
                        .font(.largeTitle)
                        .bold()


                        Text(
                            "Your Companion will keep learning as you study, ask questions, and reflect."
                        )
                        .foregroundStyle(AppTheme.textSecondary)
                    }


                    Spacer(
                        minLength: 0
                    )


                    CompanionAvatar(
                        size: 86,
                        behavior: .floating
                    )
                }


                // MARK: - Profile

                if !viewModel.profile.preferredName.isEmpty {

                    ProfileRow(
                        title:
                            "What I call you",
                        value:
                            viewModel
                                .profile
                                .preferredName
                    )
                }


                ProfileRow(
                    title:
                        "Where you are",
                    value:
                        viewModel
                            .profile
                            .spiritualPosition
                )


                ProfileRow(
                    title:
                        "Bible familiarity",
                    value:
                        viewModel
                            .profile
                            .bibleFamiliarity
                )


                ProfileRow(
                    title:
                        "What you're looking for",
                    value:
                        viewModel
                            .profile
                            .primaryGoal
                )


                ProfileRow(
                    title:
                        "Current season",
                    value:
                        viewModel
                            .profile
                            .currentSeason
                )


                ProfileRow(
                    title:
                        "Challenge style",
                    value:
                        viewModel
                            .profile
                            .challengePreference
                )


                // MARK: - Build Journey

                NavigationLink {

                    JourneyPreparationView()

                } label: {

                    HStack {

                        Text(
                            "Build My Journey"
                        )
                        .fontWeight(
                            .semibold
                        )


                        Spacer()


                        Image(
                            systemName:
                                "arrow.right"
                        )
                    }
                    .frame(
                        maxWidth:
                            .infinity
                    )
                    .padding(
                        .vertical,
                        16
                    )
                }
                .buttonStyle(CloudPrimaryButtonStyle())
            }
            .padding()
        }
        .cloudScreen()
        .navigationTitle(
            "Your Profile"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}


// =========================================================
// MARK: - Profile Row
// =========================================================

struct ProfileRow: View {

    let title: String
    let value: String


    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text(title)
                .font(
                    .caption
                )
                .foregroundStyle(AppTheme.textSecondary)


            Text(value)
                .font(
                    .headline
                )
        }
        .padding()
        .frame(
            maxWidth:
                .infinity,
            alignment:
                .leading
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
