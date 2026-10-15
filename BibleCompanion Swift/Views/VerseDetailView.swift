import SwiftUI

struct VerseDetailView: View {

    private let reference = "1 Peter 3:21"

    private let verseText = """
    The like figure whereunto even baptism doth also now save us
    (not the putting away of the filth of the flesh, but the answer
    of a good conscience toward God,) by the resurrection of Jesus Christ.
    """

    private var passageContext: String {
        """
        1 Peter 3:21

        \(verseText)
        """
    }

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                VStack(alignment: .leading, spacing: 12) {

                    Text(reference)
                        .font(.largeTitle)
                        .bold()

                    Text(verseText)
                        .font(.title3)
                        .lineSpacing(5)

                    Text("KJV")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Divider()

                Text("Study this passage")
                    .font(.title2)
                    .bold()

                NavigationLink {
                    CompanionView(
                        passage: passageContext,
                        mode: .explain
                    )
                } label: {

                    StudyModeCard(
                        title: "Explain",
                        subtitle: "Understand the passage, context, and important phrases.",
                        icon: "sparkles"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    CompanionView(
                        passage: passageContext,
                        mode: .perspectives
                    )
                } label: {

                    StudyModeCard(
                        title: "Perspectives",
                        subtitle: "Compare major Christian interpretations.",
                        icon: "person.3.fill"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    CompanionView(
                        passage: passageContext,
                        mode: .challenge
                    )
                } label: {

                    StudyModeCard(
                        title: "Challenge My View",
                        subtitle: "Test your interpretation against strong counterarguments.",
                        icon: "brain.head.profile"
                    )
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .cloudScreen()
        .navigationTitle("Passage")
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct StudyModeCard: View {

    let title: String
    let subtitle: String
    let icon: String

    var body: some View {

        HStack(spacing: 16) {

            Image(systemName: icon)
                .font(.title2)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 5) {

                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.surface)
        )
    }
}


#Preview {
    NavigationStack {
        VerseDetailView()
    }
}
