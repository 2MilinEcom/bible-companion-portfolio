import SwiftUI

struct JourneyStudyView: View {

    let recommendation: JourneyRecommendation
    let onComplete: () -> Void

    @Environment(\.dismiss)
    private var dismiss

    @State
    private var isCompleting = false


    private var parsedPassage: BiblePassageReference? {

        BibleService.shared.parsePassageRange(
            recommendation.passage
        )
    }


    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 26
            ) {

                // MARK: - Header

                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {

                    Text("Your Next Step")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.textSecondary)

                    Text(recommendation.title)
                        .font(.largeTitle)
                        .bold()

                    Text(recommendation.reason)
                        .font(.title3)
                        .foregroundStyle(AppTheme.textSecondary)
                }


                // MARK: - Passage

                if !recommendation.passage.isEmpty {

                    VStack(
                        alignment: .leading,
                        spacing: 12
                    ) {

                        Text("READ")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.textSecondary)

                        HStack {

                            Image(
                                systemName: "book.closed.fill"
                            )

                            Text(recommendation.passage)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }


                        // MARK: Open Exact Passage

                        if let parsedPassage {

                            NavigationLink {

                                BibleReaderView(
                                    book: parsedPassage.book,
                                    chapter: parsedPassage.chapter,
                                    initialVerses: parsedPassage.verses
                                )

                            } label: {

                                HStack {

                                    Image(
                                        systemName: "book.fill"
                                    )

                                    Text(
                                        "Read \(recommendation.passage)"
                                    )
                                    .fontWeight(.semibold)

                                    Spacer()

                                    Image(
                                        systemName: "chevron.right"
                                    )
                                }
                                .padding(16)
                                .frame(
                                    maxWidth: .infinity
                                )
                                .background(
                                    RoundedRectangle(
                                        cornerRadius: 14
                                    )
                                    .fill(
                                        AppTheme.surfaceSoft
                                    )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(18)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .background(
                        RoundedRectangle(
                            cornerRadius: 18
                        )
                        .fill(
                            AppTheme.surface
                        )
                    )
                }


                // MARK: - Reflection Question

                if !recommendation
                    .suggestedQuestion
                    .isEmpty {

                    VStack(
                        alignment: .leading,
                        spacing: 10
                    ) {

                        Text("THINK ABOUT")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.textSecondary)

                        Text(
                            recommendation
                                .suggestedQuestion
                        )
                        .font(.title3)
                        .fontWeight(.medium)
                    }
                }


                // MARK: - Companion

                NavigationLink {

                    CompanionView(
                        passage: recommendation.passage,
                        mode: .explain
                    )

                } label: {

                    HStack {

                        Image(
                            systemName: "sparkles"
                        )

                        VStack(
                            alignment: .leading,
                            spacing: 3
                        ) {

                            Text("Study with Companion")
                                .font(.headline)

                            Text(
                                "Ask questions about this step."
                            )
                            .font(.caption)
                        }

                        Spacer()

                        Image(
                            systemName: "chevron.right"
                        )
                    }
                    .padding(18)
                    .frame(
                        maxWidth: .infinity
                    )
                }
                .buttonStyle(.bordered)


                Spacer(minLength: 20)


                // MARK: - Complete

                Button {

                    guard !isCompleting else {
                        return
                    }

                    isCompleting = true

                    onComplete()

                    dismiss()

                } label: {

                    HStack {

                        Image(
                            systemName: "checkmark.circle.fill"
                        )

                        Text("Complete This Study")
                            .fontWeight(.semibold)
                    }
                    .frame(
                        maxWidth: .infinity
                    )
                    .padding(
                        .vertical,
                        15
                    )
                }
                .buttonStyle(
                    .borderedProminent
                )
                .disabled(
                    isCompleting
                )
            }
            .padding()
        }
        .cloudScreen()
        .navigationTitle("Study")
        .navigationBarTitleDisplayMode(.inline)
    }
}


#Preview {

    NavigationStack {

        JourneyStudyView(
            recommendation:
                JourneyRecommendation(
                    title:
                        "Start with Jesus",
                    reason:
                        "Begin by seeing how Mark introduces Jesus.",
                    actionTitle:
                        "Begin",
                    type:
                        .guidedStudy,
                    passage:
                        "Mark 1:1–15",
                    suggestedQuestion:
                        "What does Mark want me to understand about Jesus?"
                ),
            onComplete: {}
        )
        .environmentObject(
            OnboardingViewModel()
        )
    }
}
