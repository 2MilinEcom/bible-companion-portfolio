import SwiftUI

struct ChapterPickerView: View {

    let book: BibleBook

    @StateObject
    private var viewModel = BibleViewModel()


    private let columns = [
        GridItem(
            .adaptive(
                minimum: 55
            )
        )
    ]


    var body: some View {

        ScrollView {

            LazyVGrid(
                columns: columns,
                spacing: 14
            ) {

                ForEach(
                    viewModel.chapters(
                        for: book.name
                    ),
                    id: \.self
                ) { chapter in

                    NavigationLink {

                        BibleReaderView(
                            book: book.name,
                            chapter: chapter
                        )

                    } label: {

                        Text("\(chapter)")
                            .font(.headline)
                            .frame(
                                maxWidth: .infinity
                            )
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: 12
                                )
                                .fill(
                                    AppTheme.surface
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .cloudScreen()
        .navigationTitle(
            book.name
        )
        .navigationBarTitleDisplayMode(
            .large
        )
    }
}


#Preview {

    NavigationStack {

        ChapterPickerView(
            book: BibleBook(
                name: "John",
                testament: .new,
                order: 43
            )
        )
    }
}
