//
//  JourneySummaryService.swift
//  BibleCompanion Swift
//
//  Created by Shopify on 10/2/26.
//

import Foundation


// =========================================================
// MARK: - Journey Summary Checkpoint Reflection
// =========================================================

struct JourneySummaryCheckpointReflection:
    Codable,
    Hashable {

    let checkpointID:
        String

    let order:
        Int

    let title:
        String

    let passage:
        String

    let text:
        String


    init(
        checkpointID: String,
        order: Int,
        title: String,
        passage: String,
        text: String
    ) {

        self.checkpointID =
            checkpointID

        self.order =
            order

        self.title =
            title

        self.passage =
            passage

        self.text =
            text
    }


    init(
        checkpoint: JourneyCheckpoint,
        text: String
    ) {

        self.init(
            checkpointID:
                checkpoint.id,
            order:
                checkpoint.order,
            title:
                checkpoint.title,
            passage:
                checkpoint.passage,
            text:
                text
        )
    }
}


// =========================================================
// MARK: - Journey Summary Request
// =========================================================

private struct JourneySummaryRequest:
    Codable {

    let journey:
        JourneyPath

    let checkpointReflections:
        [JourneySummaryCheckpointReflection]

    let overallReflection:
        String

    let remainingQuestions:
        String

    let profile:
        SpiritualProfile
}


// =========================================================
// MARK: - Journey Summary Response
// =========================================================

struct JourneySummaryResponse:
    Codable,
    Hashable {

    let overview:
        String

    let themes:
        [String]

    let development:
        String

    let remainingQuestions:
        [String]

    let encouragement:
        String


    // =====================================================
    // MARK: - Cleaned Values
    // =====================================================

    var cleanedOverview:
        String {

        overview
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
    }


    var cleanedThemes:
        [String] {

        themes
            .map {

                $0.trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
            }
            .filter {

                !$0.isEmpty
            }
    }


    var cleanedDevelopment:
        String {

        development
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
    }


    var cleanedRemainingQuestions:
        [String] {

        remainingQuestions
            .map {

                $0.trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
            }
            .filter {

                !$0.isEmpty
            }
    }


    var cleanedEncouragement:
        String {

        encouragement
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
    }


    var hasThemes:
        Bool {

        !cleanedThemes
            .isEmpty
    }


    var hasRemainingQuestions:
        Bool {

        !cleanedRemainingQuestions
            .isEmpty
    }
}


// =========================================================
// MARK: - Journey Summary Service Error
// =========================================================

enum JourneySummaryServiceError:
    LocalizedError {

    case invalidURL

    case invalidResponse

    case server(
        statusCode: Int,
        message: String
    )

    case emptySummary


    var errorDescription:
        String? {

        switch self {

        case .invalidURL:

            return
                "The journey summary URL is invalid."


        case .invalidResponse:

            return
                "The server returned an invalid response."


        case let .server(
            _,
            message
        ):

            return
                message


        case .emptySummary:

            return
                "The server returned an empty journey summary."
        }
    }
}


// =========================================================
// MARK: - Server Error Response
// =========================================================

private struct JourneySummaryServerError:
    Codable {

    let error:
        String?
}


// =========================================================
// MARK: - Journey Summary Service
// =========================================================

final class JourneySummaryService {

    // =====================================================
    // MARK: Singleton
    // =====================================================

    static let shared =
        JourneySummaryService()


    // =====================================================
    // MARK: Init
    // =====================================================

    private init() {}


    // =====================================================
    // MARK: - Generate Summary
    // =====================================================

    func generateSummary(
        journey: JourneyPath,
        checkpointReflections:
            [JourneySummaryCheckpointReflection],
        overallReflection: String,
        remainingQuestions: String,
        profile: SpiritualProfile
    ) async throws
        -> JourneySummaryResponse {

        guard
            let url =
                URL(
                    string:
                        "\(APIConfig.baseURL)/journey-summary"
                )
        else {

            throw JourneySummaryServiceError
                .invalidURL
        }


        var request =
            URLRequest(
                url:
                    url
            )


        request.httpMethod =
            "POST"


        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Content-Type"
        )


        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Accept"
        )


        let cleanedReflections =
            checkpointReflections
                .compactMap {
                    reflection
                    -> JourneySummaryCheckpointReflection?
                    in

                    let cleanedText =
                        reflection
                            .text
                            .trimmingCharacters(
                                in:
                                    .whitespacesAndNewlines
                            )


                    guard
                        !cleanedText.isEmpty
                    else {

                        return nil
                    }


                    return
                        JourneySummaryCheckpointReflection(
                            checkpointID:
                                reflection
                                    .checkpointID,
                            order:
                                reflection
                                    .order,
                            title:
                                reflection
                                    .title,
                            passage:
                                reflection
                                    .passage,
                            text:
                                cleanedText
                        )
                }
                .sorted {

                    $0.order <
                        $1.order
                }


        let body =
            JourneySummaryRequest(
                journey:
                    journey,
                checkpointReflections:
                    cleanedReflections,
                overallReflection:
                    overallReflection
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        ),
                remainingQuestions:
                    remainingQuestions
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        ),
                profile:
                    profile
            )


        request.httpBody =
            try JSONEncoder()
                .encode(
                    body
                )


        let (
            data,
            response
        ) =
            try await CompanionHTTPClient.data(
                    for:
                        request
                )


        guard
            let httpResponse =
                response
                as?
                HTTPURLResponse
        else {

            throw JourneySummaryServiceError
                .invalidResponse
        }


        guard
            200..<300
                ~= httpResponse
                    .statusCode
        else {

            throw JourneySummaryServiceError
                .server(
                    statusCode:
                        httpResponse
                            .statusCode,
                    message:
                        serverErrorMessage(
                            from:
                                data,
                            statusCode:
                                httpResponse
                                    .statusCode
                        )
                )
        }


        let decoded =
            try JSONDecoder()
                .decode(
                    JourneySummaryResponse
                        .self,
                    from:
                        data
                )


        guard
            !decoded
                .cleanedOverview
                .isEmpty
        else {

            throw JourneySummaryServiceError
                .emptySummary
        }


        return decoded
    }


    // =====================================================
    // MARK: - Server Error
    // =====================================================

    private func serverErrorMessage(
        from data: Data,
        statusCode: Int
    ) -> String {

        if
            let decoded =
                try?
                JSONDecoder()
                    .decode(
                        JourneySummaryServerError
                            .self,
                        from:
                            data
                    ),
            let message =
                decoded
                    .error?
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    ),
            !message.isEmpty {

            return message
        }


        if
            let raw =
                String(
                    data:
                        data,
                    encoding:
                        .utf8
                )?
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                ),
            !raw.isEmpty {

            return raw
        }


        return
            "The journey summary request failed with status \(statusCode)."
    }
}
