import Foundation


// =========================================================
// MARK: - Legacy Recommendation Request
// =========================================================

struct JourneyRequest: Codable {

    let profile:
        SpiritualProfile

    let recentActivity:
        [StudyActivity]

    /// Shared structured personalization context.
    ///
    /// Optional so existing callers continue to work while
    /// Journey generation is migrated incrementally.
    let personalizationContext:
        PersonalizationContext?


    enum CodingKeys:
        String,
        CodingKey {

        case profile

        case recentActivity

        case personalizationContext =
            "personalization_context"
    }
}


// =========================================================
// MARK: - Custom Journey Path Request
// =========================================================

struct CustomJourneyPathRequest: Codable {

    let profile:
        SpiritualProfile

    let focus:
        JourneyFocus

    let recentActivity:
        [StudyActivity]

    /// Shared structured personalization context.
    ///
    /// This lets the backend consider relevant Journey history,
    /// reflections, unresolved questions, and prior study without
    /// collapsing those things into the user's explicit profile.
    let personalizationContext:
        PersonalizationContext?


    enum CodingKeys:
        String,
        CodingKey {

        case profile

        case focus

        case recentActivity

        case personalizationContext =
            "personalization_context"
    }
}


// =========================================================
// MARK: - Generated Checkpoint Response
// =========================================================

struct GeneratedJourneyCheckpoint:
    Codable {

    let title:
        String

    let subtitle:
        String

    let passage:
        String

    let focusQuestion:
        String
}


// =========================================================
// MARK: - Generated Journey Response
// =========================================================

struct GeneratedJourneyPathResponse:
    Codable {

    let title:
        String

    let subtitle:
        String

    let checkpoints:
        [GeneratedJourneyCheckpoint]
}


// =========================================================
// MARK: - Journey Service Error
// =========================================================

enum JourneyServiceError:
    LocalizedError {

    case invalidURL

    case invalidResponse

    case serverError(
        statusCode:
            Int,
        message:
            String
    )

    case invalidGeneratedPath(
        String
    )


    var errorDescription:
        String? {

        switch self {

        case .invalidURL:

            return
                "The journey service URL is invalid."


        case .invalidResponse:

            return
                "The journey service returned an invalid response."


        case let .serverError(
            _,
            message
        ):

            return
                message


        case let .invalidGeneratedPath(
            message
        ):

            return
                message
        }
    }
}


// =========================================================
// MARK: - Journey Service
// =========================================================

final class JourneyService {

    static let shared =
        JourneyService()


    private init() {}


    // =====================================================
    // MARK: - Legacy Recommendation
    // =====================================================

    func generateRecommendation(
        profile:
            SpiritualProfile,
        recentActivity:
            [StudyActivity],
        personalizationContext:
            PersonalizationContext? = nil
    ) async throws
        -> JourneyRecommendation {

        let body =
            JourneyRequest(
                profile:
                    profile,
                recentActivity:
                    recentActivity,
                personalizationContext:
                    personalizationContext
            )


        let data =
            try await performPOST(
                endpoint:
                    "/journey",
                body:
                    body
            )


        do {

            return
                try JSONDecoder()
                    .decode(
                        JourneyRecommendation.self,
                        from:
                            data
                    )

        } catch {

            throw JourneyServiceError
                .invalidGeneratedPath(
                    "The personalized recommendation could not be read."
                )
        }
    }


    // =====================================================
    // MARK: - Generate Full Custom Path
    // =====================================================

    /// Generates a complete personalized JourneyPath.
    ///
    /// This is used when JourneyLibrary does not already
    /// contain a curated path for the user's focus.
    ///
    /// The backend provides the curriculum content.
    /// The iPhone creates the permanent journey and
    /// checkpoint IDs.
    func generateCustomPath(
        profile:
            SpiritualProfile,
        focus:
            JourneyFocus,
        recentActivity:
            [StudyActivity],
        personalizationContext:
            PersonalizationContext? = nil
    ) async throws
        -> JourneyPath {

        let requestBody =
            CustomJourneyPathRequest(
                profile:
                    profile,
                focus:
                    focus,
                recentActivity:
                    recentActivity,
                personalizationContext:
                    personalizationContext
            )


        let data =
            try await performPOST(
                endpoint:
                    "/journey-path",
                body:
                    requestBody
            )


        let generated:
            GeneratedJourneyPathResponse


        do {

            generated =
                try JSONDecoder()
                    .decode(
                        GeneratedJourneyPathResponse.self,
                        from:
                            data
                    )

        } catch {

            throw JourneyServiceError
                .invalidGeneratedPath(
                    "Your personalized path was generated, but its format could not be read."
                )
        }


        return
            try makeJourneyPath(
                from:
                    generated,
                focus:
                    focus
            )
    }


    // =====================================================
    // MARK: - Build Local JourneyPath
    // =====================================================

    private func makeJourneyPath(
        from generated:
            GeneratedJourneyPathResponse,
        focus:
            JourneyFocus
    ) throws
        -> JourneyPath {

        let title =
            generated
                .title
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        let subtitle =
            generated
                .subtitle
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        guard !title.isEmpty else {

            throw JourneyServiceError
                .invalidGeneratedPath(
                    "The generated path did not include a title."
                )
        }


        guard !subtitle.isEmpty else {

            throw JourneyServiceError
                .invalidGeneratedPath(
                    "The generated path did not include a description."
                )
        }


        // Personalized paths should be substantial
        // without becoming overwhelming.

        guard
            generated.checkpoints.count >= 5,
            generated.checkpoints.count <= 7
        else {

            throw JourneyServiceError
                .invalidGeneratedPath(
                    "The generated path needs between 5 and 7 checkpoints."
                )
        }


        let journeyID =
            makeJourneyID()


        var checkpoints:
            [JourneyCheckpoint] = []


        for (
            index,
            generatedCheckpoint
        ) in generated
            .checkpoints
            .enumerated() {

            let checkpointTitle =
                generatedCheckpoint
                    .title
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )


            let checkpointSubtitle =
                generatedCheckpoint
                    .subtitle
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )


            let passage =
                generatedCheckpoint
                    .passage
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )


            let focusQuestion =
                generatedCheckpoint
                    .focusQuestion
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )


            guard
                !checkpointTitle.isEmpty,
                !checkpointSubtitle.isEmpty,
                !passage.isEmpty,
                !focusQuestion.isEmpty
            else {

                throw JourneyServiceError
                    .invalidGeneratedPath(
                        "One of the generated checkpoints was incomplete."
                    )
            }


            let order =
                index + 1


            let checkpoint =
                JourneyCheckpoint(
                    id:
                        "\(journeyID)_checkpoint_\(order)",
                    order:
                        order,
                    title:
                        checkpointTitle,
                    subtitle:
                        checkpointSubtitle,
                    passage:
                        passage,
                    focusQuestion:
                        focusQuestion
                )


            checkpoints.append(
                checkpoint
            )
        }


        return JourneyPath(
            id:
                journeyID,
            title:
                title,
            subtitle:
                subtitle,
            category:
                .personalized,
            checkpoints:
                checkpoints,
            focus:
                focus,
            createdAt:
                Date()
        )
    }


    // =====================================================
    // MARK: - Journey ID
    // =====================================================

    private func makeJourneyID()
        -> String {

        let uuid =
            UUID()
                .uuidString
                .lowercased()


        return
            "personalized_custom_\(uuid)"
    }


    // =====================================================
    // MARK: - Shared POST Helper
    // =====================================================

    private func performPOST<
        Body:
            Encodable
    >(
        endpoint:
            String,
        body:
            Body
    ) async throws
        -> Data {

        guard
            let url =
                URL(
                    string:
                        "\(APIConfig.baseURL)\(endpoint)"
                )
        else {

            throw JourneyServiceError
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


        let encoder =
            JSONEncoder()


        // PersonalizationContext can contain Journey timestamps.
        // Keep date transport consistent with AIService and
        // PerspectivesService.
        encoder.dateEncodingStrategy =
            .iso8601


        request.httpBody =
            try encoder
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

            throw JourneyServiceError
                .invalidResponse
        }


        guard
            (200...299)
                .contains(
                    httpResponse
                        .statusCode
                )
        else {

            let message =
                extractServerMessage(
                    from:
                        data
                )


            throw JourneyServiceError
                .serverError(
                    statusCode:
                        httpResponse
                            .statusCode,
                    message:
                        message
                )
        }


        return data
    }


    // =====================================================
    // MARK: - Server Error Parsing
    // =====================================================

    private func extractServerMessage(
        from data:
            Data
    ) -> String {

        // Try normal JSON:
        //
        // {
        //   "error": "..."
        // }

        if
            let object =
                try?
                JSONSerialization
                    .jsonObject(
                        with:
                            data
                    )
                as?
                [String: Any] {

            if
                let message =
                    object["error"]
                    as?
                    String,
                !message.isEmpty {

                return
                    message
            }


            if
                let message =
                    object["message"]
                    as?
                    String,
                !message.isEmpty {

                return
                    message
            }
        }


        // Fall back to raw text.

        if
            let rawMessage =
                String(
                    data:
                        data,
                    encoding:
                        .utf8
                ) {

            let cleaned =
                rawMessage
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )


            if !cleaned.isEmpty {

                return
                    cleaned
            }
        }


        return
            "The journey service returned an unknown error."
    }
}
