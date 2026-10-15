//

//  JourneyReviewView.swift

//  BibleCompanion Swift

//

//  Created by Shopify on 10/2/26.

//



import SwiftUI





// =========================================================

// MARK: - Journey Review View

// =========================================================



struct JourneyReviewView: View {



    // =====================================================

    // MARK: - Journey

    // =====================================================



    let journey:

        JourneyPath





    // =====================================================

    // MARK: - Stores

    // =====================================================



    @StateObject

    private var noteService =

        StudyNoteService.shared





    @StateObject

    private var progressStore =

        JourneyProgressStore.shared





    @StateObject

    private var journeyReflectionStore =

        JourneyReflectionStore.shared





    @StateObject

    private var journeySummaryStore =

        JourneySummaryStore.shared





    private let journeySummaryService =

        JourneySummaryService.shared




    private var preferredName: String {

        StorageService.shared
            .loadSpiritualProfile()?
            .preferredName
            ?? ""
    }





    // =====================================================

    // MARK: - Journey Reflection State

    // =====================================================



    @State

    private var overallReflection =

        ""





    @State

    private var remainingQuestions =

        ""





    @State

    private var hasLoadedJourneyReflection =

        false





    // =====================================================

    // MARK: - Journey Summary State

    // =====================================================



    @State

    private var isGeneratingSummary =

        false





    @State

    private var summaryError:

        String?





    // =====================================================

    // MARK: - Progress

    // =====================================================



    private var completedCount:

        Int {



        progressStore

            .completedCount(

                in:

                    journey

            )

    }





    private var totalCount:

        Int {



        journey

            .checkpoints

            .count

    }





    private var progress:

        Double {



        progressStore

            .progress(

                in:

                    journey

            )

    }





    private var percentage:

        Int {



        Int(

            progress

            *

            100

        )

    }





    private var reflectionCount:

        Int {



        noteService

            .reflectionCount(

                for:

                    journey

            )

    }





    private var completedCheckpointIDs:

        Set<String> {



        Set(

            progressStore

                .completedCheckpointList(

                    in:

                        journey

                )

                .map(

                    \.id

                )

        )

    }





    private var isJourneyComplete:

        Bool {



        totalCount > 0

        &&

        completedCount

        ==

        totalCount

    }





    // =====================================================

    // MARK: - Journey Summary Source

    // =====================================================



    private var summaryCheckpointReflections:

        [JourneySummaryCheckpointReflection] {



        journey

            .checkpoints

            .sorted {

                $0.order <

                    $1.order

            }

            .compactMap {

                checkpoint

                -> JourneySummaryCheckpointReflection?

                in



                guard

                    let text =

                        noteService

                            .reflectionText(

                                for:

                                    checkpoint,

                                in:

                                    journey

                            )?

                            .trimmingCharacters(

                                in:

                                    .whitespacesAndNewlines

                            ),

                    !text.isEmpty

                else {



                    return nil
                }





                return

                    JourneySummaryCheckpointReflection(

                        checkpoint:

                            checkpoint,

                        text:

                            text

                    )
            }
    }





    private var savedJourneySummary:

        JourneySummaryResponse? {



        journeySummaryStore

            .summary(

                for:

                    journey

            )
    }





    private var summaryIsStale:

        Bool {



        journeySummaryStore

            .isSummaryStale(

                for:

                    journey,

                checkpointReflections:

                    summaryCheckpointReflections,

                overallReflection:

                    overallReflection,

                remainingQuestions:

                    remainingQuestions

            )
    }





    private var hasSummarySourceContent:

        Bool {



        !summaryCheckpointReflections

            .isEmpty

        ||

        !overallReflection

            .trimmingCharacters(

                in:

                    .whitespacesAndNewlines

            )

            .isEmpty

        ||

        !remainingQuestions

            .trimmingCharacters(

                in:

                    .whitespacesAndNewlines

            )

            .isEmpty
    }





    // =====================================================

    // MARK: - Body

    // =====================================================



    var body: some View {



        ScrollView {



            VStack(

                alignment:

                    .leading,

                spacing:

                    28

            ) {



                // =================================================

                // MARK: Header

                // =================================================



                header





                // =================================================

                // MARK: Summary

                // =================================================



                summaryCard





                // =================================================

                // MARK: Checkpoint Reflections

                // =================================================



                VStack(

                    alignment:

                        .leading,

                    spacing:

                        8

                ) {



                    Text(

                        "YOUR JOURNEY"

                    )

                    .font(

                        .caption

                    )

                    .fontWeight(

                        .bold

                    )

                    .foregroundStyle(AppTheme.textSecondary)





                    Text(

                        "What You Learned"

                    )

                    .font(

                        .title2

                    )

                    .bold()





                    Text(

                        "Look back through each checkpoint and the reflections you saved along the way."

                    )

                    .font(

                        .subheadline

                    )

                    .foregroundStyle(AppTheme.textSecondary)

                }





                VStack(

                    spacing:

                        16

                ) {



                    ForEach(

                        journey

                            .checkpoints

                    ) { checkpoint in



                        checkpointCard(

                            checkpoint

                        )

                    }

                }





                // =================================================

                // MARK: Looking Back

                // =================================================



                lookingBackSection





                Spacer(

                    minLength:

                        30

                )

            }

            .padding()

        }

        .cloudScreen()
        .navigationTitle(

            "What You Learned"

        )

        .navigationBarTitleDisplayMode(

            .inline

        )

        .onAppear {

            loadJourneyReflection()

        }

        .onChange(

            of:

                overallReflection

        ) { _, newValue in

            guard hasLoadedJourneyReflection else {

                return
            }


            journeyReflectionStore
                .saveOverallReflection(

                    journey:

                        journey,

                    text:

                        newValue

                )
        }

        .onChange(

            of:

                remainingQuestions

        ) { _, newValue in

            guard hasLoadedJourneyReflection else {

                return
            }


            journeyReflectionStore
                .saveRemainingQuestions(

                    journey:

                        journey,

                    text:

                        newValue

                )
        }

    }





    // =====================================================

    // MARK: - Header

    // =====================================================



    private var header:

        some View {



        VStack(

            alignment:

                .leading,

            spacing:

                8

        ) {



            Text(

                isJourneyComplete

                ? "JOURNEY COMPLETE"

                : "JOURNEY REVIEW"

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





            if
                isJourneyComplete,
                !preferredName.isEmpty {

                Text(
                    "You made it, \(preferredName)."
                )
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textSecondary)
            }



            Text(

                journey.title

            )

            .font(

                .largeTitle

            )

            .bold()





            Text(

                journey.subtitle

            )

            .font(

                .body

            )

            .foregroundStyle(AppTheme.textSecondary)





            if let focus =

                journey

                    .focus?

                    .label

                    .trimmingCharacters(

                        in:

                            .whitespacesAndNewlines

                    ),

               !focus.isEmpty {



                HStack(

                    spacing:

                        7

                ) {



                    Image(

                        systemName:

                            "scope"

                    )





                    Text(

                        focus

                    )

                }

                .font(

                    .subheadline

                )

                .foregroundStyle(AppTheme.textSecondary)

                .padding(

                    .top,

                    4

                )

            }

        }

    }





    // =====================================================

    // MARK: - Summary Card

    // =====================================================



    private var summaryCard:

        some View {



        VStack(

            alignment:

                .leading,

            spacing:

                16

        ) {



            HStack {



                VStack(

                    alignment:

                        .leading,

                    spacing:

                        4

                ) {



                    Text(

                        "\(completedCount) of \(totalCount) checkpoints"

                    )

                    .font(

                        .headline

                    )





                    Text(

                        isJourneyComplete

                        ? "You've completed the full path."

                        : "Your journey is still in progress."

                    )

                    .font(

                        .subheadline

                    )

                    .foregroundStyle(AppTheme.textSecondary)

                }





                Spacer()





                Text(

                    "\(percentage)%"

                )

                .font(

                    .title2

                )

                .fontWeight(

                    .bold

                )

            }





            ProgressView(

                value:

                    progress

            )

            .tint(AppTheme.accent)





            Divider()





            HStack(

                spacing:

                    12

            ) {



                ZStack {



                    Circle()

                        .fill(

                            AppTheme.accent

                                .opacity(

                                    0.10

                                )

                        )

                        .frame(

                            width:

                                40,

                            height:

                                40

                        )





                    Image(

                        systemName:

                            "quote.bubble.fill"

                    )

                    .foregroundStyle(

                        AppTheme.accent

                    )

                }





                VStack(

                    alignment:

                        .leading,

                    spacing:

                        2

                ) {



                    Text(

                        "\(reflectionCount) saved \(reflectionCount == 1 ? "reflection" : "reflections")"

                    )

                    .font(

                        .headline

                    )





                    Text(

                        "These are your own notes from the journey."

                    )

                    .font(

                        .caption

                    )

                    .foregroundStyle(AppTheme.textSecondary)

                }





                Spacer()

            }

        }

        .padding(

            18

        )

        .background(



            RoundedRectangle(

                cornerRadius:

                    20

            )

            .fill(

                AppTheme.surface

            )

        )

    }





    // =====================================================

    // MARK: - Checkpoint Card

    // =====================================================



    @ViewBuilder

    private func checkpointCard(

        _ checkpoint:

            JourneyCheckpoint

    ) -> some View {



        let completed =

            completedCheckpointIDs

                .contains(

                    checkpoint.id

                )





        let reflection =

            noteService

                .reflectionText(

                    for:

                        checkpoint,

                    in:

                        journey

                )





        VStack(

            alignment:

                .leading,

            spacing:

                16

        ) {



            // =================================================

            // MARK: Checkpoint Header

            // =================================================



            HStack(

                alignment:

                    .top,

                spacing:

                    14

            ) {



                ZStack {



                    Circle()

                        .fill(

                            completed

                            ? AppTheme.accent

                                .opacity(

                                    0.12

                                )

                            : AppTheme.surfaceSoft

                        )

                        .frame(

                            width:

                                38,

                            height:

                                38

                        )





                    if completed {



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



                    } else {



                        Text(

                            "\(checkpoint.order)"

                        )

                        .font(

                            .caption

                        )

                        .fontWeight(

                            .bold

                        )

                        .foregroundStyle(AppTheme.textSecondary)

                    }

                }





                VStack(

                    alignment:

                        .leading,

                    spacing:

                        5

                ) {



                    Text(

                        "CHECKPOINT \(checkpoint.order)"

                    )

                    .font(

                        .caption2

                    )

                    .fontWeight(

                        .bold

                    )

                    .foregroundStyle(AppTheme.textSecondary)





                    Text(

                        checkpoint.title

                    )

                    .font(

                        .headline

                    )





                    Label(

                        checkpoint.passage,

                        systemImage:

                            "book.closed.fill"

                    )

                    .font(

                        .caption

                    )

                    .foregroundStyle(AppTheme.textSecondary)

                }





                Spacer()

            }





            // =================================================

            // MARK: Checkpoint Context

            // =================================================



            Text(

                checkpoint.subtitle

            )

            .font(

                .subheadline

            )

            .foregroundStyle(AppTheme.textSecondary)





            // =================================================

            // MARK: Reflection

            // =================================================



            if let reflection {



                VStack(

                    alignment:

                        .leading,

                    spacing:

                        8

                ) {



                    HStack(

                        spacing:

                            6

                    ) {



                        Image(

                            systemName:

                                "quote.opening"

                        )





                        Text(

                            "YOUR REFLECTION"

                        )

                        .fontWeight(

                            .bold

                        )

                    }

                    .font(

                        .caption

                    )

                    .foregroundStyle(

                        AppTheme.accent

                    )





                    Text(

                        reflection

                    )

                    .font(

                        .body

                    )

                    .lineSpacing(

                        4

                    )

                    .textSelection(

                        .enabled

                    )

                }

                .padding(

                    15

                )

                .frame(

                    maxWidth:

                        .infinity,

                    alignment:

                        .leading

                )

                .background(



                    RoundedRectangle(

                        cornerRadius:

                            15

                    )

                    .fill(

                        AppTheme.accent

                            .opacity(

                                0.07

                            )

                    )

                )



            } else {



                HStack(

                    alignment:

                        .top,

                    spacing:

                        9

                ) {



                    Image(

                        systemName:

                            "square.and.pencil"

                    )

                    .foregroundStyle(AppTheme.textSecondary)





                    Text(

                        completed

                        ? "No written reflection was saved for this checkpoint."

                        : "This checkpoint hasn't been completed yet."

                    )

                    .font(

                        .subheadline

                    )

                    .foregroundStyle(AppTheme.textSecondary)

                }

            }





            Divider()





            // =================================================

            // MARK: Review Checkpoint

            // =================================================



            NavigationLink {



                JourneyCheckpointView(

                    journey:

                        journey,

                    checkpoint:

                        checkpoint,

                    onComplete: {}

                )



            } label: {



                HStack {



                    Image(

                        systemName:

                            "arrow.counterclockwise"

                    )





                    Text(

                        completed

                        ? "Review Checkpoint"

                        : "Open Checkpoint"

                    )

                    .fontWeight(

                        .semibold

                    )





                    Spacer()





                    Image(

                        systemName:

                            "chevron.right"

                    )

                    .font(

                        .caption

                    )

                    .foregroundStyle(AppTheme.textSecondary)

                }

            }

            .buttonStyle(

                .plain

            )

        }

        .padding(

            18

        )

        .frame(

            maxWidth:

                .infinity,

            alignment:

                .leading

        )

        .background(



            RoundedRectangle(

                cornerRadius:

                    20

            )

            .fill(

                AppTheme.surface

            )

        )

    }





    // =====================================================

    // MARK: - Looking Back

    // =====================================================



    private var lookingBackSection:

        some View {



        VStack(

            alignment:

                .leading,

            spacing:

                18

        ) {



            VStack(

                alignment:

                    .leading,

                spacing:

                    6

            ) {



                Text(

                    "LOOKING BACK"

                )

                .font(

                    .caption

                )

                .fontWeight(

                    .bold

                )

                .foregroundStyle(AppTheme.textSecondary)





                Text(

                    "Notice the Story Across the Journey"

                )

                .font(

                    .title2

                )

                .bold()

            }





            if reflectionCount > 0 {



                Text(

                    """

                    Read back through what you wrote from the first checkpoint to the last. Notice ideas that kept returning, places where your thinking changed, and questions you still carry.

                    """

                )

                .font(

                    .body

                )

                .foregroundStyle(AppTheme.textSecondary)



            } else {



                Text(

                    """

                    You didn't save written reflections during this journey, but you can still revisit each checkpoint and add what stood out to you.

                    """

                )

                .font(

                    .body

                )

                .foregroundStyle(AppTheme.textSecondary)

            }





            if isJourneyComplete {



                journeyReflectionSection





                journeySummarySection





                HStack(

                    alignment:

                        .top,

                    spacing:

                        12

                ) {



                    Image(

                        systemName:

                            "checkmark.seal.fill"

                    )

                    .foregroundStyle(

                        AppTheme.accent

                    )





                    VStack(

                        alignment:

                            .leading,

                        spacing:

                            4

                    ) {



                        Text(

                            "You completed the full path."

                        )

                        .font(

                            .headline

                        )





                        Text(

                            "Your progress and reflections remain saved even if you choose another focus."

                        )

                        .font(

                            .subheadline

                        )

                        .foregroundStyle(AppTheme.textSecondary)

                    }

                }

                .padding(

                    15

                )

                .frame(

                    maxWidth:

                        .infinity,

                    alignment:

                        .leading

                )

                .background(



                    RoundedRectangle(

                        cornerRadius:

                            16

                    )

                    .fill(

                        AppTheme.accent

                            .opacity(

                                0.07

                            )

                    )

                )

            }





            NavigationLink {



                JourneyMapView(

                    journey:

                        journey

                )



            } label: {



                HStack {



                    Image(

                        systemName:

                            "map.fill"

                    )





                    Text(

                        "Review Full Path"

                    )

                    .fontWeight(

                        .semibold

                    )





                    Spacer()





                    Image(

                        systemName:

                            "chevron.right"

                    )

                }

                .frame(

                    maxWidth:

                        .infinity

                )

                .padding(

                    .vertical,

                    13

                )

            }

            .buttonStyle(

                .borderedProminent

            )

        }

        .padding(

            20

        )

        .background(



            RoundedRectangle(

                cornerRadius:

                    22

            )

            .fill(

                AppTheme.surface

            )

        )

    }





    // =====================================================

    // MARK: - Final Journey Reflection

    // =====================================================



    private var journeyReflectionSection:

        some View {



        VStack(

            alignment:

                .leading,

            spacing:

                18

        ) {



            VStack(

                alignment:

                    .leading,

                spacing:

                    6

            ) {



                Text(

                    "YOUR FINAL REFLECTION"

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





                Text(

                    "What changed in how you see this topic?"

                )

                .font(

                    .headline

                )





                Text(

                    "Try to put the biggest thing you learned, reconsidered, or understood differently into your own words."

                )

                .font(

                    .subheadline

                )

                .foregroundStyle(AppTheme.textSecondary)

            }





            TextEditor(

                text:

                    $overallReflection

            )

            .frame(

                minHeight:

                    130

            )

            .padding(

                10

            )

            .background(

                RoundedRectangle(

                    cornerRadius:

                        16

                )

                .fill(

                    AppTheme.surfaceSoft

                )

            )

            .overlay {



                RoundedRectangle(

                    cornerRadius:

                        16

                )

                .stroke(

                    AppTheme.textSecondary

                        .opacity(

                            0.15

                        ),

                    lineWidth:

                        1

                )
            }





            Divider()





            VStack(

                alignment:

                    .leading,

                spacing:

                    6

            ) {



                Text(

                    "WHAT ARE YOU STILL CARRYING?"

                )

                .font(

                    .caption

                )

                .fontWeight(

                    .bold

                )

                .foregroundStyle(AppTheme.textSecondary)





                Text(

                    "What do you still want to understand or work on?"

                )

                .font(

                    .headline

                )





                Text(

                    "This can be a question, an unresolved tension, or something you want to keep growing in."

                )

                .font(

                    .subheadline

                )

                .foregroundStyle(AppTheme.textSecondary)

            }





            TextEditor(

                text:

                    $remainingQuestions

            )

            .frame(

                minHeight:

                    110

            )

            .padding(

                10

            )

            .background(

                RoundedRectangle(

                    cornerRadius:

                        16

                )

                .fill(

                    AppTheme.surfaceSoft

                )

            )

            .overlay {



                RoundedRectangle(

                    cornerRadius:

                        16

                )

                .stroke(

                    AppTheme.textSecondary

                        .opacity(

                            0.15

                        ),

                    lineWidth:

                        1

                )
            }





            if hasJourneyReflectionContent {



                Label(

                    "Saved automatically",

                    systemImage:

                        "checkmark.circle.fill"

                )

                .font(

                    .caption

                )

                .foregroundStyle(AppTheme.textSecondary)
            }
        }

        .padding(

            18

        )

        .frame(

            maxWidth:

                .infinity,

            alignment:

                .leading

        )

        .background(

            RoundedRectangle(

                cornerRadius:

                    18

            )

            .fill(

                AppTheme.surfaceSoft

            )

        )
    }





    // =====================================================

    // MARK: - AI Journey Summary

    // =====================================================



    private var journeySummarySection:

        some View {



        VStack(

            alignment:

                .leading,

            spacing:

                18

        ) {



            VStack(

                alignment:

                    .leading,

                spacing:

                    6

            ) {



                Text(

                    "YOUR JOURNEY IN REVIEW"

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





                Text(

                    savedJourneySummary == nil

                    ? "Create a summary from your reflections"

                    : "A summary grounded in what you wrote"

                )

                .font(

                    .headline

                )





                Text(

                    "This summary uses your journey, saved checkpoint reflections, final reflection, and remaining questions."

                )

                .font(

                    .subheadline

                )

                .foregroundStyle(AppTheme.textSecondary)
            }





            if let summary =

                savedJourneySummary {



                if summaryIsStale {



                    HStack(

                        alignment:

                            .top,

                        spacing:

                            10

                    ) {



                        Image(

                            systemName:

                                "arrow.triangle.2.circlepath"

                        )

                        .foregroundStyle(

                            AppTheme.accent

                        )





                        VStack(

                            alignment:

                                .leading,

                            spacing:

                                4

                        ) {



                            Text(

                                "Your reflections changed"

                            )

                            .font(

                                .subheadline

                            )

                            .fontWeight(

                                .semibold

                            )





                            Text(

                                "This saved summary was created before your latest edits. You can keep reading it or update it."

                            )

                            .font(

                                .caption

                            )

                            .foregroundStyle(AppTheme.textSecondary)
                        }
                    }

                    .padding(

                        12

                    )

                    .frame(

                        maxWidth:

                            .infinity,

                        alignment:

                            .leading

                    )

                    .background(

                        RoundedRectangle(

                            cornerRadius:

                                14

                        )

                        .fill(

                            AppTheme.accent

                                .opacity(

                                    0.07

                                )

                        )

                    )
                }





                summaryContent(

                    summary

                )





                Button {



                    Task {



                        await generateJourneySummary()
                    }



                } label: {



                    HStack {



                        if isGeneratingSummary {



                            ProgressView()

                        } else {



                            Image(

                                systemName:

                                    summaryIsStale

                                    ? "arrow.clockwise"

                                    : "sparkles"

                            )
                        }





                        Text(

                            summaryIsStale

                            ? "Update Summary"

                            : "Regenerate Summary"

                        )

                        .fontWeight(

                            .semibold

                        )





                        Spacer()
                    }

                    .frame(

                        maxWidth:

                            .infinity

                    )

                    .padding(

                        .vertical,

                        13

                    )
                }

                .buttonStyle(

                    .bordered

                )

                .disabled(

                    isGeneratingSummary

                    ||

                    !hasSummarySourceContent

                )



            } else {



                VStack(

                    alignment:

                        .leading,

                    spacing:

                        12

                ) {



                    if hasSummarySourceContent {



                        Text(

                            "When you're ready, create a concise review of the themes, development, and questions found in your own reflections."

                        )

                        .font(

                            .subheadline

                        )

                        .foregroundStyle(AppTheme.textSecondary)



                    } else {



                        Text(

                            "Add at least one written reflection before creating a personalized journey summary."

                        )

                        .font(

                            .subheadline

                        )

                        .foregroundStyle(AppTheme.textSecondary)
                    }





                    Button {



                        Task {



                            await generateJourneySummary()
                        }



                    } label: {



                        HStack {



                            if isGeneratingSummary {



                                ProgressView()

                            } else {



                                Image(

                                    systemName:

                                        "sparkles"

                                )
                            }





                            Text(

                                isGeneratingSummary

                                ? "Creating Summary..."

                                : "Create My Journey Summary"

                            )

                            .fontWeight(

                                .semibold

                            )





                            Spacer()
                        }

                        .frame(

                            maxWidth:

                                .infinity

                        )

                        .padding(

                            .vertical,

                            13

                        )
                    }

                    .buttonStyle(

                        .borderedProminent

                    )

                    .disabled(

                        isGeneratingSummary

                        ||

                        !hasSummarySourceContent

                    )
                }
            }





            if let summaryError {



                HStack(

                    alignment:

                        .top,

                    spacing:

                        10

                ) {



                    Image(

                        systemName:

                            "exclamationmark.triangle.fill"

                    )





                    VStack(

                        alignment:

                            .leading,

                        spacing:

                            4

                    ) {



                        Text(

                            "We couldn't create your summary."

                        )

                        .font(

                            .subheadline

                        )

                        .fontWeight(

                            .semibold

                        )





                        Text(

                            summaryError

                        )

                        .font(

                            .caption

                        )
                    }
                }

                .foregroundStyle(AppTheme.textSecondary)

                .padding(

                    12

                )

                .frame(

                    maxWidth:

                        .infinity,

                    alignment:

                        .leading

                )

                .background(

                    RoundedRectangle(

                        cornerRadius:

                            14

                    )

                    .fill(

                        AppTheme.surfaceSoft

                    )

                )
            }
        }

        .padding(

            18

        )

        .frame(

            maxWidth:

                .infinity,

            alignment:

                .leading

        )

        .background(

            RoundedRectangle(

                cornerRadius:

                    18

            )

            .fill(

                AppTheme.surfaceSoft

            )

        )
    }





    // =====================================================

    // MARK: - Summary Content

    // =====================================================



    @ViewBuilder

    private func summaryContent(

        _ summary:

            JourneySummaryResponse

    ) -> some View {



        VStack(

            alignment:

                .leading,

            spacing:

                18

        ) {



            summaryTextSection(

                title:

                    "WHAT YOU EXPLORED",

                text:

                    summary

                        .cleanedOverview

            )





            if summary.hasThemes {



                VStack(

                    alignment:

                        .leading,

                    spacing:

                        9

                ) {



                    Text(

                        "THEMES IN YOUR REFLECTIONS"

                    )

                    .font(

                        .caption

                    )

                    .fontWeight(

                        .bold

                    )

                    .foregroundStyle(AppTheme.textSecondary)





                    ForEach(

                        Array(

                            summary

                                .cleanedThemes

                                .enumerated()

                        ),

                        id:

                            \.offset

                    ) {

                        _,

                        theme

                        in



                        HStack(

                            alignment:

                                .top,

                            spacing:

                                9

                        ) {



                            Image(

                                systemName:

                                    "circle.fill"

                            )

                            .font(

                                .system(

                                    size:

                                        5

                                )

                            )

                            .padding(

                                .top,

                                7

                            )

                            .foregroundStyle(

                                AppTheme.accent

                            )





                            Text(

                                theme

                            )

                            .font(

                                .subheadline

                            )
                        }
                    }
                }
            }





            summaryTextSection(

                title:

                    "HOW YOUR THINKING DEVELOPED",

                text:

                    summary

                        .cleanedDevelopment

            )





            if summary

                .hasRemainingQuestions {



                VStack(

                    alignment:

                        .leading,

                    spacing:

                        9

                ) {



                    Text(

                        "QUESTIONS YOU'RE STILL CARRYING"

                    )

                    .font(

                        .caption

                    )

                    .fontWeight(

                        .bold

                    )

                    .foregroundStyle(AppTheme.textSecondary)





                    ForEach(

                        Array(

                            summary

                                .cleanedRemainingQuestions

                                .enumerated()

                        ),

                        id:

                            \.offset

                    ) {

                        _,

                        question

                        in



                        HStack(

                            alignment:

                                .top,

                            spacing:

                                9

                        ) {



                            Image(

                                systemName:

                                    "questionmark.circle.fill"

                            )

                            .font(

                                .caption

                            )

                            .foregroundStyle(

                                AppTheme.accent

                            )





                            Text(

                                question

                            )

                            .font(

                                .subheadline

                            )
                        }
                    }
                }
            }





            if !summary

                .cleanedEncouragement

                .isEmpty {



                Divider()





                HStack(

                    alignment:

                        .top,

                    spacing:

                        10

                ) {



                    Image(

                        systemName:

                            "sparkles"

                    )

                    .foregroundStyle(

                        AppTheme.accent

                    )





                    Text(

                        summary

                            .cleanedEncouragement

                    )

                    .font(

                        .subheadline

                    )

                    .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }

        .padding(

            15

        )

        .frame(

            maxWidth:

                .infinity,

            alignment:

                .leading

        )

        .background(

            RoundedRectangle(

                cornerRadius:

                    16

            )

            .fill(

                AppTheme.surface

            )

        )
    }





    private func summaryTextSection(

        title:

            String,

        text:

            String

    ) -> some View {



        VStack(

            alignment:

                .leading,

            spacing:

                6

        ) {



            Text(

                title

            )

            .font(

                .caption

            )

            .fontWeight(

                .bold

            )

            .foregroundStyle(AppTheme.textSecondary)





            Text(

                text

            )

            .font(

                .subheadline

            )

            .lineSpacing(

                3

            )
        }

        .frame(

            maxWidth:

                .infinity,

            alignment:

                .leading

        )
    }





    // =====================================================

    // MARK: - Generate Journey Summary

    // =====================================================



    @MainActor

    private func generateJourneySummary()

        async {



        guard !isGeneratingSummary else {

            return
        }





        guard hasSummarySourceContent else {



            summaryError =

                "Add at least one written reflection before creating your journey summary."



            return
        }





        isGeneratingSummary =

            true





        summaryError =

            nil





        defer {



            isGeneratingSummary =

                false
        }





        do {



            let generated =

                try await journeySummaryService

                    .generateSummary(

                        journey:

                            journey,

                        checkpointReflections:

                            summaryCheckpointReflections,

                        overallReflection:

                            overallReflection,

                        remainingQuestions:

                            remainingQuestions,

                        profile:

                            StorageService.shared
                                .loadSpiritualProfile()
                                ?? .empty

                    )





            journeySummaryStore

                .saveSummary(

                    generated,

                    for:

                        journey,

                    checkpointReflections:

                        summaryCheckpointReflections,

                    overallReflection:

                        overallReflection,

                    remainingQuestions:

                        remainingQuestions

                )



        } catch {



            summaryError =

                error.localizedDescription
        }
    }





    // =====================================================

    // MARK: - Journey Reflection Helpers

    // =====================================================



    private var hasJourneyReflectionContent:

        Bool {



        !overallReflection

            .trimmingCharacters(

                in:

                    .whitespacesAndNewlines

            )

            .isEmpty

        ||

        !remainingQuestions

            .trimmingCharacters(

                in:

                    .whitespacesAndNewlines

            )

            .isEmpty
    }





    private func loadJourneyReflection() {



        guard !hasLoadedJourneyReflection else {

            return
        }





        overallReflection =

            journeyReflectionStore

                .overallReflection(

                    for:

                        journey

                )





        remainingQuestions =

            journeyReflectionStore

                .remainingQuestions(

                    for:

                        journey

                )





        hasLoadedJourneyReflection =

            true
    }

}





// =========================================================

// MARK: - Preview

// =========================================================



#Preview {



    NavigationStack {



        JourneyReviewView(

            journey:

                JourneyLibrary.meetJesus

        )

        .environmentObject(

            OnboardingViewModel()

        )

    }

}
