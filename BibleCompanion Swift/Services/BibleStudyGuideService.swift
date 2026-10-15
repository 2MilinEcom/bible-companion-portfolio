//
//  BibleStudyGuideService.swift
//  BibleCompanion Swift
//
//  Created by Shopify on 10/3/26.
//

import Foundation


// =========================================================
// MARK: - Study Guide Models
// =========================================================

struct BibleStudyTheme:
    Codable,
    Identifiable,
    Equatable {

    let title:
        String

    let explanation:
        String


    var id:
        String {

        title
        +
        "::"
        +
        explanation
    }
}


struct BibleStudyDeepQuestion:
    Codable,
    Identifiable,
    Equatable {

    let question:
        String

    let whyItMatters:
        String


    var id:
        String {

        question
        +
        "::"
        +
        whyItMatters
    }


    enum CodingKeys:
        String,
        CodingKey {

        case question

        case whyItMatters =
            "why_it_matters"
    }
}


struct BibleStudyJourneyConnection:
    Codable,
    Equatable {

    let relevant:
        Bool

    let text:
        String
}


struct BibleStudyGuide:
    Codable,
    Equatable {

    let title:
        String

    let understand:
        String

    let context:
        String

    let themes:
        [BibleStudyTheme]

    let goDeeper:
        [BibleStudyDeepQuestion]

    let journeyConnection:
        BibleStudyJourneyConnection


    enum CodingKeys:
        String,
        CodingKey {

        case title
        case understand
        case context
        case themes

        case goDeeper =
            "go_deeper"

        case journeyConnection =
            "journey_connection"
    }


    init(
        title:
            String,
        understand:
            String,
        context:
            String,
        themes:
            [BibleStudyTheme],
        goDeeper:
            [BibleStudyDeepQuestion],
        journeyConnection:
            BibleStudyJourneyConnection
    ) {

        self.title =
            title

        self.understand =
            understand

        self.context =
            context

        self.themes =
            themes

        self.goDeeper =
            goDeeper

        self.journeyConnection =
            journeyConnection
    }


    init(
        from decoder:
            Decoder
    ) throws {

        let container =
            try decoder
                .container(
                    keyedBy:
                        CodingKeys.self
                )


        title =
            try container
                .decodeIfPresent(
                    String.self,
                    forKey:
                        .title
                )
            ??
            ""

        understand =
            try container
                .decodeIfPresent(
                    String.self,
                    forKey:
                        .understand
                )
            ??
            ""

        context =
            try container
                .decodeIfPresent(
                    String.self,
                    forKey:
                        .context
                )
            ??
            ""

        themes =
            try container
                .decodeIfPresent(
                    [BibleStudyTheme].self,
                    forKey:
                        .themes
                )
            ??
            []

        goDeeper =
            try container
                .decodeIfPresent(
                    [BibleStudyDeepQuestion].self,
                    forKey:
                        .goDeeper
                )
            ??
            []

        journeyConnection =
            try container
                .decodeIfPresent(
                    BibleStudyJourneyConnection.self,
                    forKey:
                        .journeyConnection
                )
            ??
            BibleStudyJourneyConnection(
                relevant:
                    false,
                text:
                    ""
            )
    }


    var meaningfulJourneyConnection:
        String? {

        let cleaned =
            journeyConnection
                .text
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        guard
            journeyConnection.relevant,
            !cleaned.isEmpty
        else {
            return nil
        }


        return cleaned
    }
}


// =========================================================
// MARK: - Study Guide Service
// =========================================================

final class BibleStudyGuideService {

    static let shared =
        BibleStudyGuideService()


    private init() {}


    func generate(
        reference:
            String,
        passage:
            String,
        profile:
            SpiritualProfile,
        personalizationContext:
            PersonalizationContext
    ) async throws
        -> BibleStudyGuide {

        let prompt =
            """
            Create a calm, structured Bible study guide for the CURRENT STUDY PASSAGE.

            The guide should help someone understand the text without turning the screen into a sermon.

            Return ONLY valid JSON. Do not wrap it in markdown fences and do not add commentary before or after the JSON.

            Use exactly this shape:

            {
              "title": "A short study title grounded in the passage",
              "understand": "A concise plain-language explanation of what is happening and what the text is saying.",
              "context": "Relevant literary, historical, or biblical context. Include only context that materially helps interpret this passage.",
              "themes": [
                {
                  "title": "Theme name",
                  "explanation": "Why this theme is actually present in the passage."
                }
              ],
              "go_deeper": [
                {
                  "question": "A serious interpretive or reflective question",
                  "why_it_matters": "Why examining this question helps the reader understand the text more carefully."
                }
              ],
              "journey_connection": {
                "relevant": true,
                "text": "A brief connection to the user's current journey only if the supplied personalization context makes that connection genuinely relevant."
              }
            }

            Rules:
            - Base the guide on the supplied biblical passage.
            - Distinguish what the text explicitly says from interpretation.
            - Do not invent historical details you are unsure of.
            - Use 2 to 4 themes.
            - Use 2 to 3 go_deeper questions.
            - Keep each section concise enough for a mobile study screen.
            - Adapt vocabulary to the user's Bible familiarity when useful.
            - The user's saved journey or struggle is supporting context, not the subject of every passage.
            - Set journey_connection.relevant to false and journey_connection.text to an empty string when there is no natural connection.
            - Never define the user by a struggle or imply that reading history proves a spiritual condition.
            - Do not mention private personalization data, hidden context, or memory systems.

            STUDY REFERENCE:
            \(reference)
            """


        let response =
            try await AIService.shared
                .ask(
                    question:
                        prompt,
                    passage:
                        passage,
                    mode:
                        .explain,
                    previousResponseID:
                        nil,
                    profile:
                        profile,
                    personalizationContext:
                        personalizationContext
                )


        return
            try decodeGuide(
                from:
                    response.answer
            )
    }


    // =====================================================
    // MARK: - Decode
    // =====================================================

    private func decodeGuide(
        from raw:
            String
    ) throws -> BibleStudyGuide {

        let cleaned =
            raw
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        guard
            !cleaned.isEmpty
        else {

            throw BibleStudyGuideError.emptyResponse
        }


        let candidate =
            extractJSONObject(
                from:
                    cleaned
            )
            ??
            cleaned


        guard
            let data =
                candidate
                    .data(
                        using:
                            .utf8
                    )
        else {

            throw BibleStudyGuideError.invalidResponse
        }


        do {

            let decoded =
                try JSONDecoder()
                    .decode(
                        BibleStudyGuide.self,
                        from:
                            data
                    )


            return
                normalized(
                    decoded
                )

        } catch {

            throw BibleStudyGuideError.invalidResponse
        }
    }


    private func extractJSONObject(
        from value:
            String
    ) -> String? {

        guard
            let first =
                value.firstIndex(
                    of:
                        "{"
                ),
            let last =
                value.lastIndex(
                    of:
                        "}"
                ),
            first <= last
        else {
            return nil
        }


        return
            String(
                value[first...last]
            )
    }


    private func normalized(
        _ guide:
            BibleStudyGuide
    ) -> BibleStudyGuide {

        BibleStudyGuide(
            title:
                cleaned(
                    guide.title
                ),
            understand:
                cleaned(
                    guide.understand
                ),
            context:
                cleaned(
                    guide.context
                ),
            themes:
                Array(
                    guide
                        .themes
                        .map {
                            BibleStudyTheme(
                                title:
                                    cleaned(
                                        $0.title
                                    ),
                                explanation:
                                    cleaned(
                                        $0.explanation
                                    )
                            )
                        }
                        .filter {
                            !$0.title.isEmpty
                            ||
                            !$0.explanation.isEmpty
                        }
                        .prefix(4)
                ),
            goDeeper:
                Array(
                    guide
                        .goDeeper
                        .map {
                            BibleStudyDeepQuestion(
                                question:
                                    cleaned(
                                        $0.question
                                    ),
                                whyItMatters:
                                    cleaned(
                                        $0.whyItMatters
                                    )
                            )
                        }
                        .filter {
                            !$0.question.isEmpty
                        }
                        .prefix(3)
                ),
            journeyConnection:
                BibleStudyJourneyConnection(
                    relevant:
                        guide
                            .journeyConnection
                            .relevant,
                    text:
                        cleaned(
                            guide
                                .journeyConnection
                                .text
                        )
                )
        )
    }


    private func cleaned(
        _ value:
            String
    ) -> String {

        value
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
    }
}


// =========================================================
// MARK: - Error
// =========================================================

enum BibleStudyGuideError:
    LocalizedError {

    case emptyResponse
    case invalidResponse


    var errorDescription:
        String? {

        switch self {

        case .emptyResponse:
            return
                "The study guide came back empty. Please try again."

        case .invalidResponse:
            return
                "The study guide came back in an unexpected format. Please try again."
        }
    }
}
